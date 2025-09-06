---@diagnostic disable: duplicate-set-field
BF_Overlays = BF_Overlays or {}

-- Only run on player creation to avoid load-order issues
Events.OnCreatePlayer.Add(function(_, player)
    if not player then return end
    BF_Overlays.RefreshOverlaysForPlayer(player, "peed")
    BF_Overlays.RefreshOverlaysForPlayer(player, "pooped")
end)

function BF_Overlays.GetOverlayBySeverity(item, stainType)
    if not item or not stainType then return nil end
    local itemType = item:getType()
    if not itemType then return nil end
    if not BF_Overlays.clothingModels then
        return (stainType == "peed") and "BF.BoxingShorts_Peed" or "BF.BoxingShorts_Pooped"
    end
    for _, category in pairs(BF_Overlays.clothingModels) do
        if category and category.types and BF_Utils and BF_Utils.tableContains then
            if BF_Utils.tableContains(category.types, itemType) then
                local overlayKey = (stainType == "peed") and "peeOverlay" or "poopOverlay"
                local overlay = category[overlayKey]
                if overlay and type(overlay) == "string" then
                    return overlay
                else
                    print("[WARN] GetOverlayBySeverity: overlay missing for category of", itemType)
                end
            end
        end
    end
    return (stainType == "peed") and "BF.BoxingShorts_Peed" or "BF.BoxingShorts_Pooped"
end

function BF_Overlays.ApplyOverlayToSlot(player, wornItem, stainType, bodyLocation)
    if not player or not wornItem or not stainType or not bodyLocation then return end
    local modData = wornItem:getModData() or {}
    local severityKey = (stainType == "peed") and "peedSeverity" or "poopedSeverity"
    local minSeverity = (stainType == "peed") and 10 or 25
    if (modData[severityKey] or 0) < minSeverity then return end
    if not modData[stainType] then return end

    local overlayItemType = BF_Overlays.GetOverlayBySeverity(wornItem, stainType)
    if not overlayItemType then
        print("[ERROR] ApplyOverlayToSlot: overlayItemType nil for", wornItem:getType())
        return
    end

    local inv = player:getInventory()
    if not inv then print("[ERROR] ApplyOverlayToSlot: no inventory") return end

    local existing = player:getWornItem(bodyLocation)
    if existing and existing:getType() == overlayItemType then return end

    local itemToWear = inv:AddItem(overlayItemType)
    if not itemToWear then
        print("[ERROR] ApplyOverlayToSlot: AddItem returned nil for", overlayItemType)
        return
    end

    BF_Overlays.ClearAllOverlaysByType(player, stainType)
    player:setWornItem(bodyLocation, itemToWear)
    modData[stainType .. "OverlayItemType"] = overlayItemType
end

function BF_Overlays.RemoveOverlayFromSlot(player, wornItem, stainType)
    if not player or not wornItem or not stainType then return end
    local modData = wornItem:getModData() or {}
    local overlayKey = stainType .. "OverlayItemType"
    local inv = player:getInventory()
    if not inv then return end
    if modData[overlayKey] then
        local overlayItem = inv:getItemFromType(modData[overlayKey])
        if overlayItem then
            pcall(function() player:removeWornItem(overlayItem) end)
            inv:Remove(overlayItem)
        end
        modData[overlayKey] = nil
    end
end

function BF_Overlays.ClearAllOverlaysByType(player, stainType)
    if not player or not stainType then return end
    local inv = player:getInventory()
    if not inv then return end
    local tag = (stainType == "peed") and "PeedOverlay" or "PoopedOverlay"
    local items = inv:getItems()
    if not items then return end
    local toRemove = {}
    for i = 0, items:size()-1 do
        local it = items:get(i)
        if it and it:hasTag and it:hasTag(tag) then table.insert(toRemove, it) end
    end
    for _, it in ipairs(toRemove) do
        for wi = 0, player:getWornItems():size()-1 do
            local worn = player:getWornItems():getItemByIndex(wi)
            if worn and worn:getModData() then
                local md = worn:getModData()
                if md.peedOverlayItemType == it:getType() then md.peedOverlayItemType = nil end
                if md.poopedOverlayItemType == it:getType() then md.poopedOverlayItemType = nil end
            end
        end
        pcall(function() player:removeWornItem(it) end)
        inv:Remove(it)
    end
end

function BF_Overlays.RefreshOverlaysForPlayer(player, stainType)
    if not player or not stainType then return end
    if not BF_Overlays.soilableLocations then
        print("[ERROR] RefreshOverlaysForPlayer: soilableLocations not defined")
        return
    end
    BF_Overlays.ClearAllOverlaysByType(player, stainType)
    for _, loc in ipairs(BF_Overlays.soilableLocations) do
        local wornItem = player:getWornItem(loc)
        if wornItem and (wornItem:getModData() and wornItem:getModData()[stainType]) then
            local bodyLocation
            local isUnder = BF_Overlays.clothingModels and BF_Overlays.clothingModels.MaleUnderwear and BF_Overlays.clothingModels.FemaleUnderwear and
                ((BF_Utils and BF_Utils.tableContains and BF_Utils.tableContains(BF_Overlays.clothingModels.MaleUnderwear.types, wornItem:getType())) or
                 (BF_Utils and BF_Utils.tableContains and BF_Utils.tableContains(BF_Overlays.clothingModels.FemaleUnderwear.types, wornItem:getType())))
            if isUnder then
                bodyLocation = (stainType == "peed") and "PeedOverlay_Underwear" or "PoopedOverlay_Underwear"
            else
                bodyLocation = (stainType == "peed") and "PeedOverlay_Pants" or "PoopedOverlay_Pants"
            end
            BF_Overlays.ApplyOverlayToSlot(player, wornItem, stainType, bodyLocation)
        end
    end
end
