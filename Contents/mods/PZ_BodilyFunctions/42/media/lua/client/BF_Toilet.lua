-- =====================================================
--
-- BF_Toilet
--
-- Client side of the toilet system (BF_Toilets): what the relief menus and
-- actions ask about a toilet, the message sent when one is used, and the
-- toilet's care menu.
--
-- The care menu is added to the toilet's vanilla right-click entry. It shows
-- the toilet's dirt and why it can't be used, and has the wash, unclog, flush,
-- fill tank, and empty and refill (chemical toilet) options.
-- Tools, water and cleaners are taken from the inventory, bags and nearby
-- containers in the same room, and put back afterward (BF_Supplies). Ported
-- from Bodily Functions Plus.
--
-- With Lifestyle: Hobbies active there is no care menu; Lifestyle's own
-- toilet menu is used for flushing and cleaning.
--
-- =====================================================

require "BF_Toilets"
require "TimedActions/BF_ServiceToilet"
require "_Shared/Utils/BF_Supplies"

BF_Toilet = {}
local S, R, W = BF_Toilets, BF_ToiletRules, BF_Sewage

local ICONS = {
    Dirt = "media/textures/BF_Icon_Dirt.png", ChemicalFill = "media/textures/BF_Icon_ChemicalFill.png",
    Blocked = "media/textures/BF_Icon_Blocked.png", CleanToilet = "media/textures/BF_Icon_Clean.png",
    UnclogToilet = "media/textures/BF_Icon_Unclog.png", FlushToilet = "media/textures/BF_Icon_Flush.png",
    FillTank = "media/textures/BF_Icon_FillTank.png", EmptyChemical = "media/textures/BF_Icon_Empty.png",
    RefillChemical = "media/textures/BF_Icon_Bleach.png",
}

function BF_Toilet.hasFlushWater(obj)
    return S.hasWater(obj)
end

-- Why the toilet can't be used, as a ContextMenu_BF_ key suffix, or nil.
function BF_Toilet.reason(obj)
    return S.reason(obj)
end

function BF_Toilet.isBlocked(obj)
    return S.reason(obj) ~= nil
end

-- Called when peeing or pooping in a toilet ends. amount is the share of it
-- that was done (0 to 1); a visit stopped right after it started isn't counted.
function BF_Toilet.markUsed(player, obj, poop, amount)
    amount = amount or 1
    if not obj or not S.kind(obj) or amount < 0.05 then return end
    sendClientCommand(player, "BF", "toiletUse", {
        x = obj:getX(), y = obj:getY(), z = obj:getZ(), sprite = obj:getTextureName(),
        poop = poop == true, amount = amount,
    })
end

-- -----------------------------------------------------
-- Care menu
-- -----------------------------------------------------

-- Walks to the square the toilet faces, or next to it when it has no facing.
local function walkToToilet(player, toilet)
    local facing = toilet:getFacing()
    if not facing then return luautils.walkAdj(player, toilet:getSquare(), true) end
    local front = toilet:getSquare():getAdjacentSquare(facing)
    if not front then return luautils.walkAdj(player, toilet:getSquare(), true) end
    if front ~= player:getCurrentSquare() then
        if not AdjacentFreeTileFinder.privTrySquare(toilet:getSquare(), front) then
            return luautils.walkAdj(player, toilet:getSquare(), true)
        end
        ISTimedActionQueue.add(ISWalkToTimedAction:new(player, front))
    end
    return true
end

-- Tool kinds each operation needs. After emptying a chemical toilet, the bucket is kept in hand.
local NEEDS = { clean = { "brush", "cleaner" }, unclog = { "plunger" }, empty = { "bucket" }, refill = { "bleach" } }
local KEEP = { empty = true }

local function service(player, toilet, operation)
    local tools = BF_Supplies.tools(BF_Supplies.records(player, toilet:getSquare()))
    local borrowed = {}
    for _, kind in ipairs(NEEDS[operation] or {}) do borrowed[#borrowed + 1] = tools[kind] end
    BF_Supplies.queue(player, borrowed, function(character)
        if walkToToilet(character, toilet) then
            ISTimedActionQueue.add(BF_ServiceToilet:new(character, toilet, operation))
        end
    end, KEEP[operation])
end

local function fillTank(player, toilet, record)
    BF_Supplies.queue(player, { record }, function(character)
        if not walkToToilet(character, toilet) then return end
        ISWorldObjectContextMenu.equip(character, character:getPrimaryHandItem(), record.item, true)
        ISTimedActionQueue.add(BF_ServiceToilet:new(character, toilet, "fill", record.item))
    end)
end

-- The toilet's vanilla right-click entry, or a new entry with the same name if there isn't one.
local function menuFor(context, obj)
    local props = obj:getSprite():getProperties()
    local name = props:get("CustomName")
    if props:has("GroupName") then name = props:get("GroupName") .. " " .. name end
    name = Translator.getMoveableDisplayName(name)
    local option = context:getOptionFromName(name)
    if option and option.subOption then return context:getSubMenu(option.subOption) end
    local found = BF.FindToiletSubMenu and BF.FindToiletSubMenu(context)
    if found then return found end
    local top = context:addOption(name)
    local icon = getTexture(obj:getTextureName())
    if icon then top.iconTexture = icon:splitIcon() end
    local menu = ISContextMenu:getNew(context)
    context:addSubMenu(top, menu)
    return menu
end

local function withTooltip(option, text)
    option.toolTip = ISToolTip:new()
    option.toolTip:initialise()
    option.toolTip.description = text
    return option
end

local function addInfo(menu, text, icon)
    local option = menu:addOption(text)
    option.notAvailable = true
    option.iconTexture = getTexture(icon)
    return option
end

-- An option that's available unless `problem` (a translation key) or `idle`
-- is set. A problem is shown as a one-line tooltip; idle disables it with no tooltip,
-- for when there's nothing to do. `note` is a tooltip for an available option.
local function addOption(menu, label, player, toilet, operation, problem, idle, note)
    local option = menu:addOption(getText("ContextMenu_BF_" .. label), player, service, toilet, operation)
    option.iconTexture = getTexture(ICONS[label])
    if idle then
        option.notAvailable = true
    elseif problem then
        option.notAvailable = true
        withTooltip(option, getText(problem))
    elseif note then
        withTooltip(option, note)
    end
    return option
end

local function addFillOptions(menu, player, toilet, records)
    local tank = S.tank(toilet)
    if not tank then return end
    local sources = {}
    for _, record in ipairs(records) do
        if S.tankSource(tank, record.item) then sources[#sources + 1] = record end
    end
    local option = menu:addOption(getText("ContextMenu_BF_FillTank"))
    option.iconTexture = getTexture(ICONS.FillTank)
    local level = getText("ContextMenu_BF_FillTankAmount") .. " " .. math.floor(tank:getAmount())
        .. " / " .. math.floor(tank:getCapacity()) .. " L."
    if #sources == 0 then
        option.notAvailable = true
        withTooltip(option, level .. " " .. getText(tank.reserve and "ContextMenu_BF_NeedCleanWater" or "ContextMenu_BF_NeedWater"))
        return
    end
    withTooltip(option, level)
    local sub = ISContextMenu:getNew(menu)
    menu:addSubMenu(option, sub)
    for _, record in ipairs(sources) do
        local item = record.item
        local amount = math.floor(item:getFluidContainer():getAmount() * 10) / 10
        local entry = sub:addOption(item:getName() .. " (" .. amount .. ")", player, fillTank, toilet, record)
        entry.itemForTexture = item
    end
end

-- Wash option: the problem as a translation key, whether there's nothing to
-- clean, and a note when there's no cleaner and only part of the dirt comes off.
local function washState(state, records, tools)
    if state.dirt <= 0 then return nil, true end
    if state.clogged then return "ContextMenu_BF_UnclogFirst" end
    if not tools.brush then return "ContextMenu_BF_NoBrush" end
    if tools.cleaner then return nil end
    if S.washable(state.dirt, false) <= 0 then return "ContextMenu_BF_NeedCleaner" end
    return nil, false, getText("ContextMenu_BF_WashDry")
end

local function addCareMenu(context, player, toilet)
    local kind = S.kind(toilet)
    local state = S.state(toilet)
    local records = BF_Supplies.records(player, toilet:getSquare())
    local tools = BF_Supplies.tools(records)
    local menu = menuFor(context, toilet)

    addInfo(menu, getText("ContextMenu_BF_Dirt") .. ": " .. math.floor(state.dirt) .. "%", ICONS.Dirt)
    local reason = S.reason(toilet)
    if reason then addInfo(menu, getText("ContextMenu_BF_" .. reason), ICONS.Blocked) end

    local problem, idle, note = washState(state, records, tools)
    addOption(menu, "CleanToilet", player, toilet, "clean", problem, idle, note)

    if kind ~= "wooden" then
        local progress = state.unclogProgress > 0
            and (getText("ContextMenu_BF_UnclogProgress") .. " " .. math.floor(state.unclogProgress * 100) .. "%") or nil
        addOption(menu, "UnclogToilet", player, toilet, "unclog",
            not tools.plunger and "ContextMenu_BF_NoPlunger" or nil, not state.clogged, progress)
    end

    if kind == "flush" then
        local problem = not S.hasWater(toilet) and "ContextMenu_BF_NoWater" or nil
        local note = state.clogged and getText("ContextMenu_BF_FlushClogged") or nil
        addOption(menu, "FlushToilet", player, toilet, "flush", problem, S.load(toilet) <= 0, note)
        addFillOptions(menu, player, toilet, records)
    elseif kind == "chemical" then
        local share = state.chemicalLoad / R.CHEMICAL_CAPACITY
        addInfo(menu, getText("ContextMenu_BF_ChemicalFill") .. ": " .. math.floor(share * 100) .. "%", ICONS.ChemicalFill)
        addOption(menu, "EmptyChemical", player, toilet, "empty",
            not tools.bucket and "ContextMenu_BF_NoBucket" or nil, state.chemicalLoad <= 0)
        addOption(menu, "RefillChemical", player, toilet, "refill",
            not tools.bleach and "ContextMenu_BF_NoBleach" or nil, R.dose(state) >= 1)
    end
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if test or not S.active() then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    -- All tiles, not only worldObjects[1]'s. A controller's first object is the player's own tile.
    local objects = BF.GetContextMenuObjects(worldObjects)
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if S.kind(obj) then addCareMenu(context, player, obj) end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

-- Stains are saved with the toilet, but redrawn on load in case they weren't saved.
local function onLoadGridsquare(square)
    if not S.active() then return end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        local md = obj:hasModData() and obj:getModData()
        if md and md.movableData and md.movableData.bfSanitation and S.kind(obj) then
            BF_ToiletVisuals.apply(obj, BF_ToiletVisuals.stage(md.movableData.bfSanitation.dirt), false)
        end
    end
end

Events.LoadGridsquare.Add(onLoadGridsquare)
