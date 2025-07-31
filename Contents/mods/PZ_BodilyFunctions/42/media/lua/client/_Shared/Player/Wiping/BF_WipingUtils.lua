function BF.CheckForWipeables(player)
    local usingDrainable = "usingDrainable"
    local usingOneTime = "usingOneTime"
    local usingClothing = "usingClothing"

    -- Check for drainable items
    local drainableItems = BF.GetDrainableWipeables()
    for _, itemType in ipairs(drainableItems) do
        local items = player:getInventory():getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item:getType() == itemType and item:getCurrentUses() >= 1 then
                local requiredUses = BF_WipingConfig.drainableWipeables[itemType].usesRequired
                local wipeEfficiency = math.min(item:getCurrentUses() / requiredUses, 1.0)
                return usingDrainable, item, wipeEfficiency
            end
        end
    end

    -- Check for non-drainable wipeables
    local nonDrainableItems = BF.GetOneTimeWipeables()
    for _, itemType in ipairs(nonDrainableItems) do
        local availableItems = player:getInventory():getNumberOfItem(itemType)
        if availableItems >= 1 then
            local requiredUses = BF_WipingConfig.oneTimeWipeables[itemType].usesRequired
            local wipeEfficiency = math.min(availableItems / requiredUses, 1.0)
            local item = player:getInventory():getFirstType(itemType)
            return usingOneTime, item, wipeEfficiency
        end
    end

    -- Check for clothing wipeables
    local clothingWipeables = BF.GetClothingWipeables()
    for _, bodyLocation in ipairs(clothingWipeables) do
        local items = player:getInventory():getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item:IsClothing() and item:getBodyLocation() == bodyLocation then
                return usingClothing, item, 0
            end
        end
    end

    return nil, nil, 0
end