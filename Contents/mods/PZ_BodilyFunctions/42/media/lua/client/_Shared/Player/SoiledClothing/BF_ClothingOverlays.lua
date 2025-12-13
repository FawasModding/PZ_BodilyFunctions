---@diagnostic disable: duplicate-set-field
BF_Overlays = {}

Events.OnLoad.Add(function()
    --BF_Overlays.RefreshOverlaysForPlayer(getPlayer(), "peed")
    --BF_Overlays.RefreshOverlaysForPlayer(getPlayer(), "pooped")
end)

function BF_Overlays.GetOverlayBySeverity(item, stainType)
    local itemType = item:getType()
    for _, category in pairs(BF_Overlays.clothingModels) do
        if BF_Utils.tableContains(category.types, itemType) then
            local overlayKey = stainType == "peed" and "peeOverlay" or "poopOverlay"
            local overlay = category[overlayKey]
            if overlay then
                return overlay
            end
        end
    end
    local fallback = stainType == "peed" and "BF.Female_Underpants_Peed" or "BF.BoxingShorts_Pooped"
    return fallback
end

function BF_Overlays.ApplyOverlayToSlot(player, wornItem, stainType, bodyLocation)
    local modData = wornItem:getModData()
    local severityKey = stainType == "peed" and "peedSeverity" or "poopedSeverity"

    -- Define minimum severity threshold (25% for both pee and poop)
    -- previously 10 for pooped, 25 for peed (maybe go back?)
    local minSeverity = 25

    -- Only apply overlay if severity is high enough
    if not modData[severityKey] or modData[severityKey] < minSeverity then
        return
    end

    if modData[stainType] then
        local overlayTable = BF_Overlays.GetOverlayBySeverity(wornItem, stainType)
        local severity = modData[severityKey]

        -- Select overlay based on severity thresholds
        local overlayItemType
        if stainType == "peed" then
            if severity >= 100 then
                overlayItemType = overlayTable.fresh["100"]
            elseif severity >= 75 then
                overlayItemType = overlayTable.fresh["75"]
            elseif severity >= 50 then
                overlayItemType = overlayTable.fresh["50"]
            elseif severity >= 25 then
                overlayItemType = overlayTable.fresh["25"]
            end
        elseif stainType == "pooped" then
            if severity >= 100 then
                overlayItemType = overlayTable.fresh["100"]
            elseif severity >= 75 then
                overlayItemType = overlayTable.fresh["75"]
            elseif severity >= 50 then
                overlayItemType = overlayTable.fresh["50"]
            elseif severity >= 25 then
                overlayItemType = overlayTable.fresh["25"]
            end
        end

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
end

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
        -- Only clear it when the stain is removed entirely
    end
end

-- Removes all overlay items of a specific stain type from the player's inventory
-- stainType is expected to be either "peed" or anything else (treated as "pooped")
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

function BF_Overlays.RefreshOverlaysForPlayer(player, stainType)
    BF_Overlays.ClearAllOverlaysByType(player, stainType)
    local locations = BF_Overlays.soilableLocations
    for _, location in ipairs(locations) do
        local wornItem = player:getWornItem(location)
        if wornItem and wornItem:getModData()[stainType] then
            local bodyLocation
            if BF_Utils.tableContains(BF_Overlays.clothingModels.MaleUnderwear.types, wornItem:getType()) or
            BF_Utils.tableContains(BF_Overlays.clothingModels.FemaleUnderwear.types, wornItem:getType()) then
                -- Apply to underwear-specific overlay slot
                if stainType == "peed" then
                    bodyLocation = BFBodyLocations.PeedOverlay_Underwear
                else
                    bodyLocation = BFBodyLocations.PoopedOverlay_Underwear
                end
            else
                -- Apply to pants/outer lower body overlay slot
                if stainType == "peed" then
                    bodyLocation = BFBodyLocations.PeedOverlay_Pants
                else
                    bodyLocation = BFBodyLocations.PoopedOverlay_Pants
                end
            end
            BF_Overlays.ApplyOverlayToSlot(player, wornItem, stainType, bodyLocation)
        end
    end
end

-- Separate event handlers
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

if ISUnequipAction and ISUnequipAction.perform then
    ISUnequipAction.o_perform = ISUnequipAction.perform
    function ISUnequipAction:perform()
        --print("[DEBUG] ISUnequipAction perform called")
        local success, result = pcall(self.o_perform, self)
        if not success then
            print("[ERROR] ISUnequipAction perform failed: " .. tostring(result))
        end
        local player = getPlayer()
        if player then
            local success, result = pcall(function()
                BF_Overlays.ClearAllOverlaysByType(player, "peed")
                BF_Overlays.ClearAllOverlaysByType(player, "pooped")
            end)
            if not success then
                print("[ERROR] ClearAllOverlaysByType failed: " .. tostring(result))
            end
            local delayTicks, tickCount = 10, 0
            local function delayedEquip()
                tickCount = tickCount + 1
                if tickCount >= delayTicks then
                    Events.OnTick.Remove(delayedEquip)
                    local success, result = pcall(function()
                        BF_Overlays.RefreshOverlaysForPlayer(player, "peed")
                        BF_Overlays.RefreshOverlaysForPlayer(player, "pooped")
                    end)
                    if not success then
                        print("[ERROR] RefreshOverlaysForPlayer failed: " .. tostring(result))
                    end
                end
            end
            Events.OnTick.Add(delayedEquip)
        else
            print("[ERROR] ISUnequipAction: Player is nil")
        end
    end
end