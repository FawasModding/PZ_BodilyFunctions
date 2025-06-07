---@diagnostic disable: duplicate-set-field
BF_ClothingOverlays = {}

Events.OnLoad.Add(function()
    BF_ClothingOverlays.equipAllOverlays(getPlayer(), "peed")
    BF_ClothingOverlays.equipAllOverlays(getPlayer(), "pooped")
end)

function BF_ClothingOverlays.getOverlayItem(item, stainType)
    local itemType = item:getType()
    --print("[DEBUG] getOverlayItem: itemType=" .. tostring(itemType) .. ", stainType=" .. stainType)
    for _, category in pairs(BF_ClothingConfig.clothingModels) do
        if BF_Utils.tableContains(category.types, itemType) then
            local overlayKey = stainType == "peed" and "peeOverlay" or "poopOverlay"
            local overlay = category[overlayKey]
            if overlay then
                --print("[DEBUG] Found overlay: " .. overlay)
                return overlay
            else
                --print("[DEBUG] No overlay found for key: " .. overlayKey)
            end
        end
    end
    local fallback = stainType == "peed" and "BathroomFunctions.Female_Underpants_Peed" or "BathroomFunctions.BoxingShorts_Pooped"
    --print("[DEBUG] Using fallback overlay: " .. fallback)
    return fallback
end

function BF_ClothingOverlays.equipOverlay(player, wornItem, stainType, bodyLocation)
    local modData = wornItem:getModData()
    local severityKey = stainType == "peed" and "peedSeverity" or "poopedSeverity"

    -- Define minimum severity thresholds. 10% if peed, 25% if pooped
    local minSeverity = stainType == "peed" and 10 or 25

    -- Only apply overlay if severity is high enough
    if modData[severityKey] and modData[severityKey] < minSeverity then
        --print("[DEBUG] Overlay not applied: " .. stainType .. " severity too low (" .. tostring(modData[severityKey]) .. "%)")
        return
    end

    if modData[stainType] then
        local overlayItemType = BF_ClothingOverlays.getOverlayItem(wornItem, stainType)
        if overlayItemType then
            local existing = player:getWornItem(bodyLocation)
            if not existing or existing:getType() ~= overlayItemType then
                local itemToWear = player:getInventory():AddItem(overlayItemType)
                if itemToWear then
                    player:setWornItem(bodyLocation, itemToWear)
                    modData[stainType .. "OverlayItemType"] = overlayItemType
                    --print("[DEBUG] Equipped " .. stainType .. " overlay: " .. overlayItemType .. " at " .. bodyLocation)
                else
                    print("[ERROR] Failed to add overlay item: " .. overlayItemType .. " (check item definition or mod load order)")
                end
            end
        else
            print("[ERROR] Overlay not applied: Invalid overlay item type: " .. tostring(overlayItemType))
        end
    else
        --print("[DEBUG] No overlay applied: modData[" .. stainType .. "] is false")
    end
end

function BF_ClothingOverlays.removeOverlay(player, wornItem, stainType)
    if not wornItem then
        --print("[DEBUG] removeOverlay: wornItem is nil, skipping")
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
            --print("[DEBUG] Removed " .. stainType .. " overlay: " .. modData[overlayKey])
        else
            --print("[DEBUG] No overlay item found in inventory for: " .. modData[overlayKey])
        end
        -- DO NOT clear modData[overlayKey] here!
        -- Only clear it when the stain is removed entirely
    end
end

function BF_ClothingOverlays.removeAllOverlays(player, stainType)
    if not player or not player:getInventory() then
        print("[ERROR] removeAllOverlays: Invalid player or inventory")
        return
    end
    local inventory = player:getInventory()
    local tag = stainType == "peed" and "BathroomOverlay" or "PoopedOverlay"
    --print("[DEBUG] Removing all " .. stainType .. " overlays with tag: " .. tag)
    local items = inventory:getItems()
    if not items then
        --print("[DEBUG] No items in inventory")
        return
    end
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
            --print("[DEBUG] Removed " .. stainType .. " overlay item: " .. item:getType())
        end)
        if not success then
            print("[ERROR] Failed to remove overlay item: " .. tostring(result))
        end
    end
end

function BF_ClothingOverlays.equipAllOverlays(player, stainType)
    --print("[DEBUG] Starting equipAll" .. stainType:gsub("^%l", string.upper) .. "Overlays...")
    BF_ClothingOverlays.removeAllOverlays(player, stainType)
    local locations = BF_ClothingConfig.soilableLocations
    for _, location in ipairs(locations) do
        local wornItem = player:getWornItem(location)
        if wornItem and wornItem:getModData()[stainType] then
            local bodyLocation
            if BF_Utils.tableContains(BF_ClothingConfig.clothingModels.MaleUnderwear.types, wornItem:getType()) or
            BF_Utils.tableContains(BF_ClothingConfig.clothingModels.FemaleUnderwear.types, wornItem:getType()) then
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
            BF_ClothingOverlays.equipOverlay(player, wornItem, stainType, bodyLocation)
        end
    end
    --print("[DEBUG] Completed equipAll" .. stainType:gsub("^%l", string.upper) .. "Overlays.")
end

-- Separate event handlers
if ISWearClothing and ISWearClothing.perform then
    ISWearClothing.o_perform = ISWearClothing.perform
    function ISWearClothing:perform()
        --print("[DEBUG] ISWearClothing perform called")
        local success, result = pcall(self.o_perform, self)
        if not success then
            print("[ERROR] ISWearClothing perform failed: " .. tostring(result))
        end
        BF_ClothingOverlays.removeAllOverlays(getPlayer(), "peed")
        BF_ClothingOverlays.removeAllOverlays(getPlayer(), "pooped")
        local delayTicks, tickCount = 10, 0
        local function delayedEquip()
            tickCount = tickCount + 1
            if tickCount >= delayTicks then
                Events.OnTick.Remove(delayedEquip)
                BF_ClothingOverlays.equipAllOverlays(getPlayer(), "peed")
                BF_ClothingOverlays.equipAllOverlays(getPlayer(), "pooped")
                --print("[DEBUG] ISWearClothing delayed equip completed")
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
                BF_ClothingOverlays.removeAllOverlays(player, "peed")
                BF_ClothingOverlays.removeAllOverlays(player, "pooped")
            end)
            if not success then
                print("[ERROR] removeAllOverlays failed: " .. tostring(result))
            end
            local delayTicks, tickCount = 10, 0
            local function delayedEquip()
                tickCount = tickCount + 1
                if tickCount >= delayTicks then
                    Events.OnTick.Remove(delayedEquip)
                    local success, result = pcall(function()
                        BF_ClothingOverlays.equipAllOverlays(player, "peed")
                        BF_ClothingOverlays.equipAllOverlays(player, "pooped")
                    end)
                    if not success then
                        print("[ERROR] equipAllOverlays failed: " .. tostring(result))
                    end
                    --print("[DEBUG] ISUnequipAction delayed equip completed")
                end
            end
            Events.OnTick.Add(delayedEquip)
        else
            print("[ERROR] ISUnequipAction: Player is nil")
        end
    end
else
    --print("[ERROR] ISUnequipAction or perform not found")
end