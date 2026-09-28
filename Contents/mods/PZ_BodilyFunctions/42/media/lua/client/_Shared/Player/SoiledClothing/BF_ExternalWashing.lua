---@diagnostic disable: duplicate-set-field

-- ============================================================================
-- BF_ExternalWashing
-- ----------------------------------------------------------------------------
-- The mod's own "Wash Soiled Items" menu is not the only way a player expects
-- to get a garment clean. This file makes soiling respond to:
--
--   * clothing washers, combination washer/dryers and stacked washer/dryers
--   * the vanilla "Wash" action performed at a sink
--
-- It also pushes the player's bowel and bladder values to the server whenever
-- they change, so a multiplayer client's reset is not undone by the server's
-- stale copy.
-- ============================================================================

BF = BF or {}

-- Soiling points a running washer removes per in-game minute.
BF.WasherSoilRemovedPerMinute = 25

-- How far from the player washers are looked for. Machines outside loaded
-- chunks do not run at all, so there is nothing to catch further out.
local WASHER_SWEEP_RADIUS = 8

local hooksRegistered = false

-- ----------------------------------------------------------------------------
-- Soiling removal
-- ----------------------------------------------------------------------------

-- Wipes the stain visuals off an item. Wetness and dirtiness only exist on
-- Clothing, so junk items get the per-body-part treatment only.
local function clearStainVisuals(item)
    local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
    if coveredParts then
        for j = 0, coveredParts:size() - 1 do
            item:setBlood(coveredParts:get(j), 0)
            item:setDirt(coveredParts:get(j), 0)
        end
    end

    item:setBloodLevel(0)

    if item:IsClothing() then
        item:setWetness(100)
        item:setDirtiness(0)
    end
end

-- Refreshes the worn overlay models so a cleaned garment stops showing a stain
-- without waiting for the next equip or unequip.
local function refreshOverlays(character)
    if not character or not BF_Overlays then return end
    BF_Overlays.RefreshOverlaysForPlayer(character, "peed")
    BF_Overlays.RefreshOverlaysForPlayer(character, "pooped")
    character:resetModelNextFrame()
end

function BF.IsItemSoiled(item)
    if not item then return false end
    local modData = item:getModData()
    if not modData then return false end
    return modData.pooped == true or modData.peed == true
end

-- Takes `amount` off both soiling meters and clears the flags once a meter
-- reaches zero. Returns true when the item changed.
function BF.ReduceItemSoiling(item, amount, character)
    if not BF.IsItemSoiled(item) then return false end

    local modData = item:getModData()

    if modData.peed == true then
        local severity = math.max((modData.peedSeverity or 0) - amount, 0)
        modData.peedSeverity = severity
        modData.peed = severity > 0
    end

    if modData.pooped == true then
        local severity = math.max((modData.poopedSeverity or 0) - amount, 0)
        modData.poopedSeverity = severity
        modData.pooped = severity > 0
    end

    clearStainVisuals(item)

    if modData.pooped ~= true and modData.peed ~= true and modData.originalName then
        item:setName(modData.originalName)
        modData.originalName = nil
    end

    if character and isClient() then
        syncItemFields(character, item)
    end

    refreshOverlays(character)

    return true
end

-- Removes all soiling in one go. Used by the vanilla wash hook, which is a
-- complete wash by the game's own standards.
function BF.ClearItemSoiling(item, character)
    return BF.ReduceItemSoiling(item, 100, character)
end

-- ----------------------------------------------------------------------------
-- Washing machines
-- ----------------------------------------------------------------------------

-- Combination units wash only in washer mode, and stacked units expose the
-- washer half separately from the dryer half.
function BF.IsWasherRunning(object)
    if not object then return false end

    if instanceof(object, "IsoStackedWasherDryer") then
        return object:isWasherActivated()
    end

    if instanceof(object, "IsoCombinationWasherDryer") then
        return object:isActivated() and object:isModeWasher()
    end

    if instanceof(object, "IsoClothingWasher") then
        return object:isActivated()
    end

    return false
end

-- A stacked unit holds a drum per half, so the washer drum is asked for by name
-- and everything is only swept when that lookup finds nothing.
local function forEachWasherContainer(object, callback)
    if instanceof(object, "IsoStackedWasherDryer") then
        local washerDrum = object:getContainerByType("clothingwasher")
        if washerDrum then
            callback(washerDrum)
            return
        end
    end

    for i = 0, object:getContainerCount() - 1 do
        local container = object:getContainerByIndex(i)
        if container then
            callback(container)
        end
    end
end

local function cleanContainerContents(container)
    local items = container:getItems()
    if not items then return end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if BF.IsItemSoiled(item) then
            BF.ReduceItemSoiling(item, BF.WasherSoilRemovedPerMinute, nil)
        end
    end
end

function BF.SweepWashingMachines()
    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    local cell = getCell()
    if not playerSquare or not cell then return end

    local px, py, pz = playerSquare:getX(), playerSquare:getY(), playerSquare:getZ()

    for dx = -WASHER_SWEEP_RADIUS, WASHER_SWEEP_RADIUS do
        for dy = -WASHER_SWEEP_RADIUS, WASHER_SWEEP_RADIUS do
            local square = cell:getGridSquare(px + dx, py + dy, pz)
            if square then
                local objects = square:getObjects()
                for i = 0, objects:size() - 1 do
                    local object = objects:get(i)
                    if BF.IsWasherRunning(object) then
                        forEachWasherContainer(object, cleanContainerContents)
                    end
                end
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- Vanilla sink washing
-- ----------------------------------------------------------------------------

local function hookVanillaWashing()
    if not ISWashClothing or ISWashClothing._BF_originalComplete then return end

    ISWashClothing._BF_originalComplete = ISWashClothing.complete

    function ISWashClothing:complete()
        local result = ISWashClothing._BF_originalComplete(self)
        BF.ClearItemSoiling(self.item, self.character)
        return result
    end
end

-- ----------------------------------------------------------------------------
-- Multiplayer value sync
-- ----------------------------------------------------------------------------

local lastDefecateValue = nil
local lastUrinateValue = nil

local function syncPlayerValues()
    if not isClient() then return end

    local player = getPlayer()
    if not player then return end

    local modData = player:getModData()
    if modData.defecateValue == lastDefecateValue and modData.urinateValue == lastUrinateValue then
        return
    end

    lastDefecateValue = modData.defecateValue
    lastUrinateValue = modData.urinateValue
    player:transmitModData()
end

-- ----------------------------------------------------------------------------

Events.OnGameStart.Add(function()
    if hooksRegistered then return end
    hooksRegistered = true

    hookVanillaWashing()
    Events.EveryOneMinute.Add(BF.SweepWashingMachines)
    Events.EveryOneMinute.Add(syncPlayerValues)
end)
