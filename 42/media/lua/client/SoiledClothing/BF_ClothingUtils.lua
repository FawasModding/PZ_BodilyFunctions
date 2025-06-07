-- Helper function to check if the player is wearing any of the specified clothing
function BF.HasClothingOn(player, ...)
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
function BF.DirtyBottomsEffects()
    local player = getPlayer()
    local totalPoopedSeverity = 0
    local totalPeedSeverity = 0

    -- Iterate over all worn items
    for i = 0, player:getWornItems():size() - 1 do
        local item = player:getWornItems():getItemByIndex(i)

        -- Ensure the item is not nil before calling UpdateSoiledSeverity
        if item ~= nil then
            -- Update values for pooped and peed states based on item mod data
            local itemUpdatedPooped, itemUpdatedPeed = BF.UpdateSoiledSeverity(item)

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
        BF.SetPoopedSelfValue(totalPoopedSeverity)
    else
        BF.SetPoopedSelfValue(0)
    end
    if totalPeedSeverity > 0 then
        BF.SetPeedSelfValue(totalPeedSeverity)
    else
        BF.SetPeedSelfValue(0)
    end
end

-- FOR ITEMS IN GENERAL
function BF.SetClothing(item, isLeak)
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

-- FOR CLOTHING SPECIFICALLY
function BF.UpdateSoiledSeverity(clothing)
    local updatedPooped = false
    local updatedPeed = false

    -- Ensure 'clothing' and its 'modData' are valid before proceeding
    if clothing ~= nil and clothing:getModData() ~= nil then
        local modData = clothing:getModData()

        if modData.pooped ~= nil then -- Check if the worn item is defecated
            BF.SetPoopedSelfValue(modData.poopedSeverity)
            updatedPooped = true
        else
            -- If no pooped state, set to 0 (can be skipped here if handled at the end of the loop)
            BF.SetPoopedSelfValue(0)
        end

        if modData.peed ~= nil then -- Check if the worn item is urinated
            BF.SetPeedSelfValue(modData.peedSeverity)
            updatedPeed = true
        else
            -- If no peed state, set to 0 (can be skipped here if handled at the end of the loop)
            BF.SetPeedSelfValue(0)
        end
    else
        print("Error: Clothing or mod data is nil in UpdateSoiledSeverity.")
    end

    -- Debugging output
    --print("Updated PeedSelfValue: " .. BF.GetPeedSelfValue())
    --print("Updated PoopedSelfValue: " .. BF.GetPoopedSelfValue())

    return updatedPooped, updatedPeed
end