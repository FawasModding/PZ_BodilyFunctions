function BF.CheckForWipeables(player)
    local usingDrainable = "usingDrainable"
    local usingOneTime = "usingOneTime"
    local usingClothing = "usingClothing"

    -- Check for drainable items
    for itemType, config in pairs(BF_WipingConfig.drainableWipeables) do
        local items = player:getInventory():getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item:getType() == itemType and item:getCurrentUses() >= 1 then
                local requiredUses = config.usesRequired
                local wipeEfficiency = math.min(item:getCurrentUses() / requiredUses, 1.0)
                return usingDrainable, item, wipeEfficiency
            end
        end
    end

    -- Check for one-time use items
    for itemType, config in pairs(BF_WipingConfig.oneTimeWipeables) do
        local availableItems = player:getInventory():getNumberOfItem(itemType)
        if availableItems >= 1 then
            local requiredUses = config.usesRequired
            local wipeEfficiency = math.min(availableItems / requiredUses, 1.0)
            local item = player:getInventory():getFirstType(itemType)
            return usingOneTime, item, wipeEfficiency
        end
    end

    -- Check for clothing wipeables
    for bodyLocation, config in pairs(BF_WipingConfig.clothingWipeables) do
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
