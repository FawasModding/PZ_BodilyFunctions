-- =====================================================
--
-- BF_ServerCommands
--
-- Everything that changes the world or an inventory happens here.
--
-- An item a client creates with AddItem() doesn't exist on the server, so B42's
-- item transaction check refuses to let the player move it until they relog.
-- sendAddItemToContainer() can't help: it does nothing on a client. So timed
-- actions send a command and then this file manages it
--
-- Same path serves single player, where sendClientCommand loops back into
-- OnClientCommand. sendServerCommand does nothing there, which is why reply()
-- calls the client handler directly when there is no real server.
--
-- Requests come from a client, so nothing in them is trusted: item types are
-- checked against the config, the server picks every output, and anything in
-- the world has to be near the player.
--
-- Soiling is simulated on the client and the server doesn't hold those values,
-- so washing and wiping report back and the client updates the garment.
--
-- =====================================================

-- Multiplayer clients load this folder too.
if isClient() then return end

require "BF_Waste"
require "BF_Toilets"
require "BF_PuddleWipe"

local MODULE = "BF"

-- How far from the player (in squares) a referenced world object may be. A tile
-- of slack over what the client checks, to allow for position lag.
local REACH_WASH = 2
local REACH_TOILET = 2
local REACH_WIPE_PUDDLE = 1
-- Pee out of a window is placed on the far side, so allow one extra square.
local REACH_WASTE = 3
local REACH_WASTE_BIN = 2

local BOOK_CLEAN_RETURN = "Base.SheetPaper2"
local BOOK_CLEAN_PAGES = 10
local DEFAULT_JUNK_ITEM = "BF.SheetPaper2Pooped"

local WASTE_SPAWN_INTERVAL_MS = 250
local lastWasteSpawn = {}

local function isNumber(value)
    -- Rejects NaN and both infinities as well as non-numbers.
    return type(value) == "number" and value == value and value ~= 1 / 0 and value ~= -1 / 0
end

local function reply(player, args)
    if isServer() then
        sendServerCommand(player, MODULE, "result", args)
    elseif BF.OnCommandResult then
        BF.OnCommandResult(args)
    end
end

local function giveItems(player, fullType, count)
    local inventory = player:getInventory()
    for _ = 1, count do
        local item = inventory:AddItem(fullType)
        if item then
            sendAddItemToContainer(inventory, item)
        end
    end
end

-- Returns the square at args.x/y/z if it is within `reach` of the player.
local function squareInReach(player, args, reach)
    if not isNumber(args.x) or not isNumber(args.y) or not isNumber(args.z) then return nil end
    local current = player:getCurrentSquare()
    if not current or current:getZ() ~= args.z then return nil end
    if math.abs(current:getX() - args.x) > reach or math.abs(current:getY() - args.y) > reach then return nil end
    return getCell():getGridSquare(args.x, args.y, args.z)
end

local function findObjectBySprite(square, sprite, predicate)
    if not square or type(sprite) ~= "string" then return nil end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if object:getTextureName() == sprite and (not predicate or predicate(object)) then
            return object
        end
    end
    return nil
end

local function findRecordById(records, id)
    if not isNumber(id) then return nil end
    for _, record in ipairs(records) do
        if record.item:getID() == id then return record end
    end
    return nil
end

local Commands = {}

-- -----------------------------------------------------
-- Body values
-- -----------------------------------------------------

-- field -> function(player) returning its upper bound (nil = no upper bound known).
-- Bladder and bowels are capped at this player's own capacity, so Large Bladder/Bowels don't get clamped to the average.
local SYNCED_FIELDS = {
    urinateValue = function(player) return BF.GetBladderCapacity(player) end,
    defecateValue = function(player) return BF.GetBowelCapacity(player) end,
    peedSelfValue = function() return 100 end,
    poopedSelfValue = function() return 100 end,
    bodilyFumesValue = function() return 100 end,
    bfBladderStrain = function() return 100 end,
}

-- Stored without re-transmitting: echoing the player's whole modData back could rewind values the client has advanced since it sent these.
function Commands.setValues(player, args)
    if type(args.values) ~= "table" then return end
    local modData = player:getModData()
    for field, value in pairs(args.values) do
        local getMax = SYNCED_FIELDS[field]
        if getMax and isNumber(value) then
            local max = getMax(player)
            value = math.max(value, 0)
            if max then value = math.min(value, max) end
            modData[field] = value
        end
    end
end

-- -----------------------------------------------------
-- Waste on the ground
-- -----------------------------------------------------

-- Only poop is put into bins; pee on the ground becomes a puddle (BF_Waste).
local WASTE_KINDS = {
    pee = { option = "CreatePeeObject" },
    poop = { fullType = "BF.HumanFeces", option = "CreatePoopObject" },
}

-- args = { kind, x, y, z, liters (pee), fx, fy (poop) }
-- Pee is placed on the given square: the character's own, the ground outside a window
-- (up to BF_Waste.FALL floors down) or a bush's. Poop is only placed on the character's square.
function Commands.spawnWaste(player, args)
    local kind = WASTE_KINDS[args.kind]
    if not kind or SandboxVars.BF[kind.option] ~= true then return end

    local now = getTimestampMs()
    local username = player:getUsername() or "local"
    if lastWasteSpawn[username] and now - lastWasteSpawn[username] < WASTE_SPAWN_INTERVAL_MS then return end
    lastWasteSpawn[username] = now

    local here = player:getCurrentSquare()
    if not here or not isNumber(args.x) or not isNumber(args.y) or not isNumber(args.z) then return end
    local square = getCell():getGridSquare(args.x, args.y, args.z)
    if not square then return end
    if math.abs(square:getX() - here:getX()) > REACH_WASTE or math.abs(square:getY() - here:getY()) > REACH_WASTE then return end
    if square:getZ() > here:getZ() or here:getZ() - square:getZ() > BF_Waste.FALL then return end

    if args.kind == "pee" then
        local liters = isNumber(args.liters) and args.liters or 0
        BF_Waste.pee(square, math.min(BF_Waste.MAX_LITERS, math.max(0, liters)))
    elseif square == here then
        BF_Waste.poop(square, isNumber(args.fx) and args.fx or 0.5, isNumber(args.fy) and args.fy or 0.5)
    end
end

-- The container a waste bin keeps its contents in. Big dumpsters span two tiles.
-- Not checked whether every piece has a container, so if this piece has none, it
-- falls back to a neighboring piece from the same tileset.
local function findBinContainer(square, sprite)
    local object = findObjectBySprite(square, sprite)
    if not object then return nil end
    if object:getContainer() then return object:getContainer() end

    local tileset = sprite:match("^(.*_)%d+$")
    if not tileset then return nil end
    local cell = getCell()
    for dx = -1, 1 do
        for dy = -1, 1 do
            local neighbor = cell:getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
            local objects = neighbor and neighbor:getObjects()
            if objects then
                for i = 0, objects:size() - 1 do
                    local candidate = objects:get(i)
                    local name = candidate:getTextureName()
                    if candidate:getContainer() and name and name:sub(1, #tileset) == tileset then
                        return candidate:getContainer()
                    end
                end
            end
        end
    end
    return nil
end

-- The storage container of the toilet at args.x/y/z with sprite args.sprite, if
-- Toilets Store Items is on and the toilet is in reach. Only the mod's own
-- container type counts, so a container another mod gave a toilet is never
-- filled with waste.
local function findToiletStorage(player, args)
    local toilet = findObjectBySprite(squareInReach(player, args, REACH_TOILET), args.sprite, BF.IsToilet)
    return toilet and BF_Toilets.storage(toilet)
end

-- args = { kind, x, y, z, sprite }. Puts waste into a dumpster or trash can.
-- If it's full, the waste is placed on the ground beside it instead. Toilet
-- waste is handled by toiletUse.
function Commands.depositWaste(player, args)
    local kind = WASTE_KINDS[args.kind]
    if not kind or not kind.fullType or SandboxVars.BF[kind.option] ~= true then return end
    if type(args.sprite) ~= "string" then return end

    local now = getTimestampMs()
    local username = player:getUsername() or "local"
    if lastWasteSpawn[username] and now - lastWasteSpawn[username] < WASTE_SPAWN_INTERVAL_MS then return end
    lastWasteSpawn[username] = now

    local square = squareInReach(player, args, REACH_WASTE_BIN)
    local container = square and findBinContainer(square, args.sprite)
    if not container then return end

    local item = instanceItem(kind.fullType)
    if not item then return end
    if container:hasRoomFor(player, item) then
        container:AddItem(item)
        sendAddItemToContainer(container, item)
    else
        square:AddWorldInventoryItem(item, ZombRandFloat(0.1, 0.5), ZombRandFloat(0.1, 0.5), 0)
    end
end

-- -----------------------------------------------------
-- Wiping
-- -----------------------------------------------------

local function wipeWithDrainable(records, itemType, config, junk)
    local rolls = {}
    local available = 0
    for _, record in ipairs(records) do
        local item = record.item
        if item:getType() == itemType and BF.IsChargeBasedWipeable(item) and item:getCurrentUses() >= 1 then
            table.insert(rolls, item)
            available = available + item:getCurrentUses()
        end
    end
    -- Best first, so a nearly spent roll is the last thing touched.
    table.sort(rolls, function(a, b) return a:getCurrentUses() > b:getCurrentUses() end)

    local toSpend = math.min(available, config.usesRequired)
    for _, item in ipairs(rolls) do
        if toSpend <= 0 then break end
        local fromThis = math.min(item:getCurrentUses(), toSpend)
        for _ = 1, fromThis do
            item:UseAndSync()
        end
        toSpend = toSpend - fromThis
    end

    if available > 0 then
        local junkType = BF_WipeJunkMap and BF_WipeJunkMap[itemType]
        if junkType then
            junk[junkType] = (junk[junkType] or 0) + 1
        end
    end
    return math.min(available / config.usesRequired, 1.0)
end

-- Pooled "paper" items combine by weight (1/usesRequired each); everything else
-- only counts its own type. The pool comes from the config, not from the client.
local function wipeWithOneTime(records, itemType, config, junk)
    local pooled = config.category == "paper"
    local cap = config.maxEfficiency or 1.0
    local needed = math.min(1.0, cap)

    local candidates = {}
    local available = 0
    for _, record in ipairs(records) do
        local recordType = record.item:getType()
        local recordConfig = BF_WipingConfig.oneTimeWipeables[recordType]
        if recordConfig and (recordType == itemType or (pooled and recordConfig.category == "paper")) then
            table.insert(candidates, { record = record, itemType = recordType, weight = 1 / recordConfig.usesRequired })
            available = available + 1 / recordConfig.usesRequired
        end
    end

    local gathered = 0
    for _, candidate in ipairs(candidates) do
        -- The small margin stops float error from taking one item too many.
        if gathered >= needed - 0.000001 then break end
        if BF.RemoveItemRecord(candidate.record) then
            gathered = gathered + candidate.weight
            local junkType = (BF_WipeJunkMap and BF_WipeJunkMap[candidate.itemType]) or DEFAULT_JUNK_ITEM
            junk[junkType] = (junk[junkType] or 0) + 1
        end
    end

    return math.min(available, cap)
end

local function removeByType(records, itemType, count)
    local removed = 0
    for _, record in ipairs(records) do
        if removed >= count then break end
        if record.item:getType() == itemType and BF.RemoveItemRecord(record) then
            removed = removed + 1
        end
    end
    return removed
end

local function countByType(records, itemType)
    local count = 0
    for _, record in ipairs(records) do
        if record.item:getType() == itemType then count = count + 1 end
    end
    return count
end

local function wipeWithClothTool(player, records, itemType, config, bodilyFunction, junk)
    local available = countByType(records, itemType)
    local used = removeByType(records, itemType, math.min(available, config.usesRequired))

    if bodilyFunction == "pee" then
        if config.peeReplace and used > 0 then
            giveItems(player, config.peeReplace, used)
        end
    elseif config.poopJunk and used > 0 then
        junk[config.poopJunk] = (junk[config.poopJunk] or 0) + (config.poopCount or 1) * used
    end
    return math.min(available / config.usesRequired, 1.0)
end

local function wipeWithBook(player, records, itemType, config, junk)
    if removeByType(records, itemType, 1) == 0 then return 0 end
    giveItems(player, BOOK_CLEAN_RETURN, BOOK_CLEAN_PAGES)
    local scraps = math.max(1, math.floor((config.usesRequired or 10) / 5))
    junk[DEFAULT_JUNK_ITEM] = (junk[DEFAULT_JUNK_ITEM] or 0) + scraps
    return 1.0
end

-- Puts soiled junk into the toilet's storage, one item at a time. Whatever
-- doesn't fit goes to the player's inventory.
local function giveJunk(player, toiletStorage, fullType, count)
    for i = 1, count do
        local item = toiletStorage and instanceItem(fullType)
        if not item or not toiletStorage:hasRoomFor(player, item) then
            giveItems(player, fullType, count - i + 1)
            return
        end
        toiletStorage:AddItem(item)
        sendAddItemToContainer(toiletStorage, item)
    end
end

-- args = { wipeType, itemType, bodilyFunction, requestId, x, y, z, sprite }
-- x/y/z/sprite are the toilet that was used, if any.
function Commands.wipe(player, args)
    local itemType = args.itemType
    local bodilyFunction = args.bodilyFunction
    local tables = {
        usingDrainable = BF_WipingConfig.drainableWipeables,
        usingOneTime = BF_WipingConfig.oneTimeWipeables,
        usingClothTool = BF_WipingConfig.clothToolWipeables,
        usingBook = BF_WipingConfig.bookWipeables,
    }
    local configTable = tables[args.wipeType]
    local config = configTable and type(itemType) == "string" and configTable[itemType]
    if not config or (bodilyFunction ~= "pee" and bodilyFunction ~= "poop") then
        reply(player, { requestId = args.requestId, ok = false, reason = "IGUI_BF_WipeRejected" })
        return
    end

    local records = BF.BuildReachableItemRecords(player)
    local junk = {}
    local efficiency
    if args.wipeType == "usingDrainable" then
        efficiency = wipeWithDrainable(records, itemType, config, junk)
    elseif args.wipeType == "usingOneTime" then
        efficiency = wipeWithOneTime(records, itemType, config, junk)
    elseif args.wipeType == "usingClothTool" then
        efficiency = wipeWithClothTool(player, records, itemType, config, bodilyFunction, junk)
    else
        efficiency = wipeWithBook(player, records, itemType, config, junk)
    end

    -- Only defecation leaves soiled junk. After using a toilet with Toilets
    -- Store Items on, it goes into the toilet.
    if bodilyFunction == "poop" then
        local toiletStorage = args.sprite and findToiletStorage(player, args)
        for junkType, count in pairs(junk) do
            giveJunk(player, toiletStorage, junkType, count)
        end
    end

    reply(player, { requestId = args.requestId, ok = true, efficiency = efficiency })
end

-- args = { x, y, z, wipeType, itemType, requestId }. Wipes up a urine puddle
-- next to the player with a wipeable item and soap (BF_PuddleWipe). With too
-- little of either, only part of the puddle is wiped up.
function Commands.wipePuddle(player, args)
    local P = BF_PuddleWipe
    local function fail(reason)
        reply(player, { requestId = args.requestId, ok = false, reason = reason })
    end

    local square = squareInReach(player, args, REACH_WIPE_PUDDLE)
    local puddle = square and BF_Sewage.puddle(square)
    if not P.canWipe(puddle) or not P.config(args.wipeType, args.itemType) then
        return fail("IGUI_BF_WipeRejected")
    end

    local liters = BF_Sewage.volume(puddle)
    local records = BF.BuildReachableItemRecords(player)
    local share = P.share(records, args.wipeType, args.itemType, liters)
    if share <= 0 then return fail("IGUI_BF_WipePuddleMissing") end

    local needed = P.wipesNeeded(liters)
    local used = P.consume(player, records, args.wipeType, args.itemType, needed * share)
    local wiped = math.min(share, used / needed)
    P.useSoap(records, math.ceil(P.soapNeeded(liters) * wiped - 0.0001))
    BF_Sewage.setVolume(puddle, liters * (1 - wiped))
    reply(player, { requestId = args.requestId, ok = true, share = wiped })
end

-- -----------------------------------------------------
-- Washing
-- -----------------------------------------------------

-- args = { itemId, cleanerId, x, y, z, sprite, requestId }
function Commands.wash(player, args)
    local function fail(reason)
        reply(player, { requestId = args.requestId, ok = false, reason = reason })
    end

    local inventory = player:getInventory()
    local item = isNumber(args.itemId) and inventory:getItemWithID(args.itemId)
    if not item then return fail("IGUI_BF_WashItemMissing") end

    local junk = BF.WashableJunk[item:getFullType()]
    local cost = junk and junk.water or BF.WashWaterCost.garment

    local source = findObjectBySprite(squareInReach(player, args, REACH_WASH), args.sprite, function(object)
        return object:hasWater() and object:getFluidAmount() >= cost
    end)
    if not source then return fail("IGUI_BF_WashNoWater") end

    local usedCleaner = false
    if junk then
        -- Rags and towels come clean with water alone, so no agent is spent on them.
        local favorite = item:isFavorite()
        inventory:Remove(item)
        sendRemoveItemFromContainer(inventory, item)
        local clean = inventory:AddItem(junk.clean)
        if clean then
            clean:setFavorite(favorite)
            sendAddItemToContainer(inventory, clean)
        end
    else
        local cleaner = findRecordById(BF.BuildReachableItemRecords(player), args.cleanerId)
        usedCleaner = cleaner ~= nil and BF.ConsumeCleaningAgent(cleaner.item)
    end

    source:useFluid(cost)
    reply(player, { requestId = args.requestId, ok = true, usedCleaner = usedCleaner })
end

-- -----------------------------------------------------
-- Toilets
-- -----------------------------------------------------

local TOILET_USE_INTERVAL_MS = 1000
local lastToiletUse = {}

-- With Lifestyle: Hobbies active, its own toilet system reads this flag.
local function setNeedFlush(object)
    local modData = object:getModData()
    modData.movableData = modData.movableData or {}
    modData.movableData.needFlush = true
    object:transmitModData()
end

-- args = { x, y, z, sprite, poop, amount }. Sent when peeing or pooping in a
-- toilet ends; amount is the share of it that was done (0 to 1).
function Commands.toiletUse(player, args)
    local toilet = findObjectBySprite(squareInReach(player, args, REACH_TOILET), args.sprite, BF_Toilets.kind)
    if not toilet then return end

    local now = getTimestampMs()
    local username = player:getUsername() or "local"
    if lastToiletUse[username] and now - lastToiletUse[username] < TOILET_USE_INTERVAL_MS then return end
    lastToiletUse[username] = now

    if not BF_Toilets.active() then
        if BF_Toilets.kind(toilet) == "flush" then setNeedFlush(toilet) end
        if args.poop == true then BF_Toilets.depositFeces(toilet, player) end
        return
    end
    local amount = isNumber(args.amount) and args.amount or 1
    BF_Toilets.applyUse(toilet, player, amount, args.poop == true)
end

-- -----------------------------------------------------

local function onClientCommand(module, command, player, args)
    if module ~= MODULE or not player or type(args) ~= "table" then return end
    if player:isDead() then return end
    local handler = Commands[command]
    if handler then
        handler(player, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)