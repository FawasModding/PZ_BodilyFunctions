-- Helper function to check if the player is wearing any of the specified clothing
function BathroomFunctions.HasClothingOn(player, ...)
    local bodyLocations = {...} -- Receive the clothing items to check

    -- Iterate through the clothing items to check if the player is wearing any of them
    for i = 1, #bodyLocations do
        local clothing = player:getWornItem(bodyLocations[i])
        if clothing then
            return true -- If the player is wearing any of these clothing items, return true
        end
    end

    return false -- If none of the clothing items are found, return false
end

--[[
Use this to call function to to show the wearing urinated and defecated garments moodles. As well as affect the mood over time.
]]--
function BathroomFunctions.DirtyBottomsEffects()
    local player = getPlayer()
    local totalPoopedSeverity = 0
    local totalPeedSeverity = 0

    -- Iterate over all worn items
    for i = 0, player:getWornItems():size() - 1 do
        local item = player:getWornItems():getItemByIndex(i)

        -- Ensure the item is not nil before calling UpdateSoiledSeverity
        if item ~= nil then
            -- Update values for pooped and peed states based on item mod data
            local itemUpdatedPooped, itemUpdatedPeed = BathroomFunctions.UpdateSoiledSeverity(item)

            -- Accumulate the total pooped and peed severity
            if itemUpdatedPooped and item:getModData().poopedSeverity then
                totalPoopedSeverity = totalPoopedSeverity + item:getModData().poopedSeverity
            end
            if itemUpdatedPeed and item:getModData().peedSeverity then
                totalPeedSeverity = totalPeedSeverity + item:getModData().peedSeverity
            end
        else
            print("Error: Worn item is nil at index " .. i)
        end
    end

    -- Update global values for pooped and peed after all items are processed
    if totalPoopedSeverity > 0 then
        BathroomFunctions.SetPoopedSelfValue(totalPoopedSeverity)
    else
        BathroomFunctions.SetPoopedSelfValue(0)
    end
    if totalPeedSeverity > 0 then
        BathroomFunctions.SetPeedSelfValue(totalPeedSeverity)
    else
        BathroomFunctions.SetPeedSelfValue(0)
    end
end

-- FOR ITEMS IN GENERAL
function BathroomFunctions.SetClothing(item, isLeak)
    -- Get the player object
    local player = getSpecificPlayer(0)
    local bodyDamage = player:getBodyDamage()
    
    -- If the item is marked as "peed" (wet), modify the item's properties
    if item:getModData().peed == true then
        if item:IsClothing() then
            local severity = item:getModData().peedSeverity / 100
            -- Scale wetness and dirtyness based on severity
            item:setWetness(math.min(500 * severity, 500))
            item:setDirtyness(math.min(100 * severity, 100))
        end
    end

    -- If the item is marked as "pooped" (dirty), modify the item's properties
    if item:getModData().pooped == true then
        if item:IsClothing() then
            -- Calculate severity for the fecal leak
            local severity = item:getModData().poopedSeverity / 100
            -- Scale dirtyness based on severity
            item:setDirtyness(math.min(100 * severity, 100))
        end
    end
end