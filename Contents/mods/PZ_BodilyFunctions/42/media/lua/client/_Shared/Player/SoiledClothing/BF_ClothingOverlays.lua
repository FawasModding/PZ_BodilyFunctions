---@diagnostic disable: duplicate-set-field

-- ============================================================================
-- BF_Overlays
-- ----------------------------------------------------------------------------
-- Responsible for applying, refreshing, and removing visual stain overlays
-- (pee / poop) on worn clothing based on severity stored in item modData.
--
-- This system:
--   • Determines correct overlay models per clothing category --TODO: improve explanation
--   • Applies overlays only when severity thresholds are met
--   • Keeps overlays in sync when clothing is worn or removed
--   • Tries to prevent inventory messiness during overlay refreshes
-- ============================================================================
BF_Overlays = BF_Overlays or {}

-- ============================================================================
-- Initialization
-- ============================================================================
Events.OnLoad.Add(function()
    BF_Overlays.RefreshOverlaysForPlayer(getPlayer(), "peed")
    BF_Overlays.RefreshOverlaysForPlayer(getPlayer(), "pooped")
end)

-- ============================================================================
-- Overlay Lookup
-- ============================================================================
-- Returns the [overlay definition table] for the given clothing item and stain.
-- Falls back to a default overlay if no category match is found.
--
-- @param item       InventoryItem currently worn
-- @param stainType  "peed" or "pooped"
-- @return           [Overlay definition table] or fallback overlay type
function BF_Overlays.GetOverlayBySeverity(item, stainType)
    local itemType = item:getType()

    for _, category in pairs(BF_Overlays.clothingModels) do
        if BF_Utils.tableContains(category.types, itemType) then
            if stainType == "peed" then
                return category.overlays.pee
            else
                return category.overlays.poop
            end
        end
    end

    return nil
end

-- ============================================================================
-- Overlay Application (Single Item)
-- ============================================================================
-- Applies the right overlay item to the specified body location
-- based on stored stain severity.
--
-- Overlays are only applied if severity meets the minimum threshold.
--
-- @param player       IsoPlayer instance
-- @param wornItem     Clothing item producing the stain
-- @param stainType    "peed" or "pooped"
-- @param bodyLocation BodyLocation slot for the overlay
function BF_Overlays.ApplyOverlayToSlot(player, wornItem, stainType, bodyLocation)
    local modData = wornItem:getModData()
    local severityKey = stainType == "peed" and "peedSeverity" or "poopedSeverity"

    -- Define minimum severity threshold (25% for both pee and poop)
    -- previously 10 for pooped, 25 for peed (maybe go back?)
    local minSeverity = 25

    -- STOP if severity is below threshold (or null)
    if not modData[severityKey] or modData[severityKey] < minSeverity then
        return
    end

    local overlayTable = BF_Overlays.GetOverlayBySeverity(wornItem, stainType)
    if not overlayTable or not overlayTable.single then
        return
    end

    -- TODO: For now, we are using single overlay items only.
    -- TODO: This will be expanded later to support severity-based overlays.
    local overlayItemType = overlayTable.single

    -- Select overlay based on severity thresholds
    --local overlayItemType
    --if stainType == "peed" then
    --    if severity >= 100 then
    --        overlayItemType = overlayTable.fresh["100"]
    --    elseif severity >= 75 then
    --        overlayItemType = overlayTable.fresh["75"]
    --    elseif severity >= 50 then
    --        overlayItemType = overlayTable.fresh["50"]
    --    elseif severity >= 25 then
    --        overlayItemType = overlayTable.fresh["25"]
    --    end
    --elseif stainType == "pooped" then
    --    if severity >= 100 then
    --        overlayItemType = overlayTable.fresh["100"]
    --    elseif severity >= 75 then
    --        overlayItemType = overlayTable.fresh["75"]
    --    elseif severity >= 50 then
    --        overlayItemType = overlayTable.fresh["50"]
    --    elseif severity >= 25 then
    --        overlayItemType = overlayTable.fresh["25"]
    --    end
    --end

    if overlayItemType then
        local existing = player:getWornItem(bodyLocation)
        if not existing or existing:getType() ~= overlayItemType then
            local itemToWear = player:getInventory():AddItem(overlayItemType)
            if itemToWear then
                player:setWornItem(bodyLocation, itemToWear)
                modData[stainType .. "OverlayItemType"] = overlayItemType
            else
                print("[WARNING] Overlay item type '" .. overlayItemType .. "' not found. Skipping.")
            end
        end
    end
end

-- ============================================================================
-- Overlay Removal (Single Item)
-- ============================================================================
-- Removes the overlay item associated with a specific stained clothing item.
-- The stored overlay reference in modData is intentionally preserved.
--
-- @param player    IsoPlayer instance
-- @param wornItem  Clothing item that owns the overlay
-- @param stainType "peed" or "pooped"
function BF_Overlays.RemoveOverlayFromSlot(player, wornItem, stainType)
    if not wornItem then
        return
    end
    local modData = wornItem:getModData()
    local overlayKey = stainType .. "OverlayItemType"
    if modData[overlayKey] then
        local inventory = player:getInventory()
        local overlayItem = inventory:getItemFromType(modData[overlayKey])
        if overlayItem then
            inventory:Remove(overlayItem)
            player:removeWornItem(overlayItem)
        end
        
        -- DO NOT clear modData[overlayKey] here!
        -- It must persist until the stain is removed *entirely*.
    end
end

-- ============================================================================
-- Overlay Removal (ALL))
-- ============================================================================
-- Removes all overlay items of a given stain type from inventory and worn slots.
-- Items are collected first to avoid modifying inventory during iteration.
--
-- @param player    IsoPlayer instance
-- @param stainType "peed" or anything else (treated as "pooped")
-- TODO: stainType checking will be changed when vomit overlays are added
function BF_Overlays.ClearAllOverlaysByType(player, stainType)

    -- Ensure we have a valid player and inventory
    if not player or not player:getInventory() then
        print("[ERROR] ClearAllOverlaysByType: Invalid player or inventory")
        return
    end

    local inventory = player:getInventory()

    -- Decide which item tag we are looking for
    --   If stainType is NOT "peed",
    --   it will default to the pooped overlay tag.
    local tag = (stainType == "peed")
        and BFTags.PeedOverlay
        or  BFTags.PoopedOverlay

    -- Get all items in the inventory
    local items = inventory:getItems()
    if not items then return end

    -- It collects items first instead of removing them immediately
    -- to avoid modifying the inventory while iterating over it
    local itemsToRemove = {}

    -- Scan every inventory item
    for i = 0, items:size() - 1 do
        local item = items:get(i)

        -- Only mark items that HAVE the overlay tag
        if item and item:hasTag(tag) then
            table.insert(itemsToRemove, item)
        end
    end

    -- Remove all matched overlay items
    for _, item in ipairs(itemsToRemove) do
        local success, result = pcall(function()
            -- Remove from inventory
            inventory:Remove(item)
            -- Remove from worn
            player:removeWornItem(item)
        end)

        -- If it fails give an error
        if not success then
            print("[ERROR] Failed to remove overlay item: " .. tostring(result))
        end
    end
end

-- ============================================================================
-- Overlay Refresh
-- ============================================================================
-- Re-evaluates all worn clothing and reapplies overlays for a given stain type.
-- Existing overlays are cleared first to ensure correct layering.
--
-- @param player    IsoPlayer instance
-- @param stainType "peed" or "pooped"
function BF_Overlays.RefreshOverlaysForPlayer(player, stainType)
    BF_Overlays.ClearAllOverlaysByType(player, stainType)

    for _, bodyLocation in ipairs(BF_Overlays.soilableBodyLocations) do
        local wornItem = player:getWornItem(bodyLocation)

        if wornItem and wornItem:getModData()[stainType] then
            local overlaySlot

            if BF_Utils.tableContains(BF_Overlays.clothingModels.MaleUnderwear.types, wornItem:getType()) or
               BF_Utils.tableContains(BF_Overlays.clothingModels.FemaleUnderwear.types, wornItem:getType()) then

                -- Underwear uses dedicated overlay slot
                overlaySlot = (stainType == "peed")
                    and BFBodyLocations.PeedOverlay_Underwear
                    or  BFBodyLocations.PoopedOverlay_Underwear
            else -- Pants / outerwear use lower body overlay slots
                overlaySlot = (stainType == "peed")
                    and BFBodyLocations.PeedOverlay_Pants
                    or  BFBodyLocations.PoopedOverlay_Pants
            end

            BF_Overlays.ApplyOverlayToSlot(player, wornItem, stainType, overlaySlot)
        end
    end
end

-- ============================================================================
-- Clothing Wear Hook
-- ============================================================================
-- Ensures overlays are refreshed after clothing is equipped.
-- Refresh has to be delayed due to Zomboid engine timing.
if ISWearClothing and ISWearClothing.perform then
    ISWearClothing.o_perform = ISWearClothing.perform

    function ISWearClothing:perform()
        local success, result = pcall(self.o_perform, self)
        if not success then
            print("[ERROR] ISWearClothing perform failed: " .. tostring(result))
        end

        BF_Overlays.ClearAllOverlaysByType(getPlayer(), "peed")
        BF_Overlays.ClearAllOverlaysByType(getPlayer(), "pooped")

        local delayTicks, tickCount = 10, 0

        local function delayedEquip()
            tickCount = tickCount + 1
            if tickCount >= delayTicks then
                Events.OnTick.Remove(delayedEquip)
                BF_Overlays.RefreshOverlaysForPlayer(getPlayer(), "peed")
                BF_Overlays.RefreshOverlaysForPlayer(getPlayer(), "pooped")
            end
        end

        Events.OnTick.Add(delayedEquip)
    end
else
    print("[ERROR] ISWearClothing or perform not found")
end

-- ============================================================================
-- Clothing Unequip Hook
-- ============================================================================
-- Mirrors wear logic to ensure overlays remain consistent after removal.
if ISUnequipAction and ISUnequipAction.perform then
    ISUnequipAction.o_perform = ISUnequipAction.perform

    function ISUnequipAction:perform()
        local success, result = pcall(self.o_perform, self)
        if not success then
            print("[ERROR] ISUnequipAction perform failed: " .. tostring(result))
        end

        local player = getPlayer()
        if not player then
            print("[ERROR] ISUnequipAction: Player is nil")
            return
        end

        BF_Overlays.ClearAllOverlaysByType(player, "peed")
        BF_Overlays.ClearAllOverlaysByType(player, "pooped")

        local delayTicks, tickCount = 10, 0

        local function delayedEquip()
            tickCount = tickCount + 1
            if tickCount >= delayTicks then
                Events.OnTick.Remove(delayedEquip)
                BF_Overlays.RefreshOverlaysForPlayer(player, "peed")
                BF_Overlays.RefreshOverlaysForPlayer(player, "pooped")
            end
        end

        Events.OnTick.Add(delayedEquip)
    end
end