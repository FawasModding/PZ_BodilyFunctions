---@diagnostic disable: duplicate-set-field
BF_Overlays = {}

Events.OnLoad.Add(function()
    BF_Overlays.RefreshOverlaysForPlayer(getPlayer(), "peed")
    BF_Overlays.RefreshOverlaysForPlayer(getPlayer(), "pooped")
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

    -- Define minimum severity thresholds. 10% if peed, 25% if pooped
    local minSeverity = stainType == "peed" and 10 or 25

    -- Only apply overlay if severity is high enough
    if modData[severityKey] and modData[severityKey] < minSeverity then return end

    if modData[stainType] then
        local overlayItemType = BF_Overlays.GetOverlayBySeverity(wornItem, stainType)
        if overlayItemType then
            local existing = player:getWornItem(bodyLocation)
            if not existing or existing:getType() ~= overlayItemType then
                local itemToWear = player:getInventory():AddItem(overlayItemType)
                if itemToWear then
                    player:setWornItem(bodyLocation, itemToWear)
                    modData[stainType .. "OverlayItemType"] = overlayItemType
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

function BF_Overlays.ClearAllOverlaysByType(player, stainType)
    if not player or not player:getInventory() then
        print("[ERROR] ClearAllOverlaysByType: Invalid player or inventory")
        return
    end
    local inventory = player:getInventory()
    local tag = stainType == "peed" and "BathroomOverlay" or "PoopedOverlay"
    local items = inventory:getItems()
    if not items then return end
    local itemsToRemove = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:hasTag(tag) then
            table.insert(itemsToRemove, item)
        end
    end
    for _, item in ipairs(itemsToRemove) do
        local success, result = pcall(function()
            inventory:Remove(item)
            player:removeWornItem(item)
        end)
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
                    bodyLocation = "PeedOverlay_Underwear"
                else
                    bodyLocation = "PoopedOverlay_Underwear"
                end
            else
                -- Apply to pants/outer lower body overlay slot
                if stainType == "peed" then
                    bodyLocation = "PeedOverlay_Pants"
                else
                    bodyLocation = "PoopedOverlay_Pants"
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