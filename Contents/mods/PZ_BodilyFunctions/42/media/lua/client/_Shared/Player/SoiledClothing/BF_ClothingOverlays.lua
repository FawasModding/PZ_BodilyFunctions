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
    print("[WARN] Missing overlay config for " .. tostring(itemType) .. " using fallback: " .. fallback)
    return fallback
end

function BF_Overlays.GetOverlayBase(item, stainType)
    local itemType = item:getType()
    for _, category in pairs(BF_Overlays.clothingModels) do
        if BF_Utils.tableContains(category.types, itemType) then
            local overlayKey = stainType == "peed" and "peeOverlay" or "poopOverlay"
            return category[overlayKey]
        end
    end
    local fallback = stainType == "peed" and "BF.Female_Underpants_Peed" or "BF.BoxingShorts_Pooped"
    print("[WARN] Missing overlay config for " .. tostring(itemType) .. " using fallback: " .. fallback)
    return fallback
end

local function getTextureChoiceIndex(severity)
    if severity >= 100 then return 3
    elseif severity >= 75 then return 2
    elseif severity >= 50 then return 1
    elseif severity >= 25 then return 0 end
    return nil
end

function BF_Overlays.ApplyOverlayToSlot(player, wornItem, stainType, bodyLocation)
    if not wornItem then return end

    local modData = wornItem:getModData()
    local severityKey = stainType == "peed" and "peedSeverity" or "poopedSeverity"
    local minSeverity = stainType == "peed" and 10 or 25

    if not modData[severityKey] or modData[severityKey] < minSeverity then return end
    if not modData[stainType] then return end

    local overlayItemType = BF_Overlays.GetOverlayBase(wornItem, stainType)
    if not overlayItemType then return end

    local existing = player:getWornItem(bodyLocation)
    if not existing or existing:getType() ~= overlayItemType then
        local itemToWear = player:getInventory():AddItem(overlayItemType)
        if itemToWear then
            player:setWornItem(bodyLocation, itemToWear)
            existing = itemToWear
            modData[stainType .. "OverlayItemType"] = overlayItemType
        else
            print("[ERROR] Could not add overlay item " .. overlayItemType)
            return
        end
    end

    -- apply severity texture OR restore saved choice
    local savedChoice = modData[stainType .. "TextureChoice"]
    local choiceIndex = getTextureChoiceIndex(modData[severityKey]) or savedChoice
    if choiceIndex and existing:getTextureChoice() ~= choiceIndex then
        existing:setTextureChoice(choiceIndex)
        existing:resetModel()
        modData[stainType .. "TextureChoice"] = choiceIndex
        print("Set " .. overlayItemType .. " " .. stainType .. " textureChoice = " .. choiceIndex)
    end
end

function BF_Overlays.RemoveOverlayFromSlot(player, wornItem, stainType)
    if not wornItem then return end
    local modData = wornItem:getModData()
    local overlayKey = stainType .. "OverlayItemType"
    if modData[overlayKey] then
        local inventory = player:getInventory()
        local overlayItem = inventory:getItemFromType(modData[overlayKey])
        if overlayItem then
            inventory:Remove(overlayItem)
            player:removeWornItem(overlayItem)
        end
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
                bodyLocation = stainType == "peed" and "PeedOverlay_Underwear" or "PoopedOverlay_Underwear"
            else
                bodyLocation = stainType == "peed" and "PeedOverlay_Pants" or "PoopedOverlay_Pants"
            end
            -- always re-apply (handles severity decreasing)
            BF_Overlays.ApplyOverlayToSlot(player, wornItem, stainType, bodyLocation)
        end
    end
end

-- Patch ISWearClothing.perform
if ISWearClothing and ISWearClothing.perform then
    ISWearClothing.o_perform = ISWearClothing.perform
    function ISWearClothing:perform()
        local ok, err
        if self.o_perform then
            ok, err = pcall(self.o_perform, self)
            if not ok then
                print("[ERROR] ISWearClothing perform failed: " .. tostring(err))
            end
        end
        -- overlays logic...
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
    print("[WARN] ISWearClothing.perform not found, skipping patch")
end

-- Patch ISUnequipAction.perform
if ISUnequipAction and ISUnequipAction.perform then
    ISUnequipAction.o_perform = ISUnequipAction.perform
    function ISUnequipAction:perform()
        local ok, err
        if self.o_perform then
            ok, err = pcall(self.o_perform, self)
            if not ok then
                print("[ERROR] ISUnequipAction perform failed: " .. tostring(err))
            end
        end
        local player = getPlayer()
        if player then
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
        else
            print("[ERROR] ISUnequipAction: Player is nil")
        end
    end
else
    print("[WARN] ISUnequipAction.perform not found, skipping patch")
end

