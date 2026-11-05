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

local MODULE = "BF"

-- How far from the player (in squares) a referenced world object may be. A tile
-- of slack over what the client checks, to allow for position lag.
local REACH_WASH = 2
local REACH_TOILET = 2
local REACH_CLEAN_WASTE = 3

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

local function sandboxMax(key)
    local page = SandboxVars and SandboxVars.BathroomFunctions
    local value = page and page[key]
    return isNumber(value) and value or nil
end

-- field -> function returning its upper bound (nil = no upper bound known)
local SYNCED_FIELDS = {
    urinateValue = function() return sandboxMax("BladderMaxValue") end,
    defecateValue = function() return sandboxMax("BowelsMaxValue") end,
    peedSelfValue = function() return 100 end,
    poopedSelfValue = function() return 100 end,
    bodilyFumesValue = function() return 100 end,
    bfBladderStrain = function() return 100 end,
}

-- Stored without re-transmitting: echoing the player's whole modData back could
-- rewind values the client has advanced since it sent these.
function Commands.setValues(player, args)
    if type(args.values) ~= "table" then return end
    local modData = player:getModData()
    for field, value in pairs(args.values) do
        local getMax = SYNCED_FIELDS[field]
        if getMax and isNumber(value) then
            local max = getMax()
            value = math.max(value, 0)
            if max then value = math.min(value, max) end
            modData[field] = value
        end
    end
end

-- -----------------------------------------------------
-- Waste on the ground
-- -----------------------------------------------------

local WASTE_KINDS = {
    pee = { fullType = "BF.Urine_Hydrated_0", option = "CreatePeeObject", scatter = false },
    poop = { fullType = "BF.HumanFeces", option = "CreatePoopObject", scatter = true },
}

function Commands.spawnWaste(player, args)
    local kind = WASTE_KINDS[args.kind]
    if not kind or SandboxVars.BF[kind.option] ~= true then return end

    local now = getTimestampMs()
    local username = player:getUsername() or "local"
    if lastWasteSpawn[username] and now - lastWasteSpawn[username] < WASTE_SPAWN_INTERVAL_MS then return end
    lastWasteSpawn[username] = now

    local square = player:getCurrentSquare()
    if not square then return end

    local x, y = 0, 0
    if kind.scatter then
        x = ZombRandFloat(0.1, 0.5)
        y = ZombRandFloat(0.1, 0.5)
    end
    -- The four-argument form transmits to clients itself.
    square:AddWorldInventoryItem(instanceItem(kind.fullType), x, y, 0)
end

function Commands.cleanWaste(player, args)
    local result = { requestId = args.requestId, ok = false, reason = "IGUI_BF_CleanWasteFailed" }

    local tool = isNumber(args.toolId) and player:getInventory():getItemWithID(args.toolId)
    local square = squareInReach(player, args, REACH_CLEAN_WASTE)
    if tool and BF.WasteCleaningTools[tool:getType()] and square and isNumber(args.itemId) then
        local objects = square:getObjects()
        for i = 0, objects:size() - 1 do
            local object = objects:get(i)
            if object:getObjectName() == "WorldInventoryItem" then
                local item = object:getItem()
                if item and item:getID() == args.itemId and BF.IsCleanableWaste(item) then
                    square:transmitRemoveItemFromSquare(object)
                    result.ok = true
                    result.reason = nil
                    break
                end
            end
        end
    end

    reply(player, result)
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

-- args = { wipeType, itemType, bodilyFunction, requestId }
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

    -- Only defecation leaves soiled junk.
    if bodilyFunction == "poop" then
        for junkType, count in pairs(junk) do
            giveItems(player, junkType, count)
        end
    end

    reply(player, { requestId = args.requestId, ok = true, efficiency = efficiency })
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

local function findToilet(player, args)
    return findObjectBySprite(squareInReach(player, args, REACH_TOILET), args.sprite, BF.GetToiletWaterUse)
end

-- movableData.needFlush is the field Lifestyle: Hobbies reads too.
local function setNeedFlush(object, value)
    local modData = object:getModData()
    modData.movableData = modData.movableData or {}
    modData.movableData.needFlush = value
    object:transmitModData()
end

function Commands.markFlush(player, args)
    local toilet = findToilet(player, args)
    if toilet then setNeedFlush(toilet, true) end
end

function Commands.flush(player, args)
    local toilet = findToilet(player, args)
    if not toilet then return end
    local amount = BF.GetToiletWaterUse(toilet)
    if not toilet:hasWater() or toilet:getFluidAmount() < amount then return end
    toilet:useFluid(amount)
    setNeedFlush(toilet, false)
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
