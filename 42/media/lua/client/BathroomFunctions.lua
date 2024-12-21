BathroomFunctions = {}
BathroomFunctions.didFirstTimer = false
FlySquares = {}










-- =====================================================
--
-- BATHROOM FUNCTIONALITY AND TIMERS
--
-- =====================================================

--[[
Function to handle timed updates for bathroom needs
This function is called periodically (e.g., every 10 in-game minutes).
]]--
function BathroomFunctions.BathroomFunctionTimers()
    if BathroomFunctions.didFirstTimer then
        BathroomFunctions.NewBathroomValues() -- If the initial setup is done, update the player's bathroom values
        BathroomFunctions.CheckForAccident() -- Check whether or not the player has urinated or defecated themselves.
        BathroomFunctions.DirtyBottomsEffects()
    else
        BathroomFunctions.didFirstTimer = true -- If this is the first call, set the flag to true and skip updating values
    end
end

-- Function to update the player's bathroom-related values (urination and defecation)
function BathroomFunctions.NewBathroomValues()
    local player = getPlayer() -- Fetch the current player object

    -- === URINATION ===

    -- Update the urination value
    local urinateValue = BathroomFunctions.GetUrinateValue() -- Get the current urination value
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Get the max bladder value, default to 100 if not set
    local urinateIncrease = 0.005 * bladderMaxValue * SandboxVars.BathroomFunctions.BladderIncreaseMultiplier -- 0.5% of the max bladder value * multiplier

    urinateValue = urinateValue + urinateIncrease -- Increase the urination value by the calculated percentage
    player:getModData().urinateValue = tonumber(urinateValue) -- Save the updated value back to the player's modData
    print("Updated Urinate Value: " .. urinateValue) -- Debug print statement to display the updated urination value

    -- === DEFECATION ===

    -- Update the defecation value
    local defecateValue = BathroomFunctions.GetDefecateValue() -- Get the current defecation value
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Get the max bowel value, default to 100 if not set
    local defecateIncrease = 0.005 * bowelsMaxValue * SandboxVars.BathroomFunctions.BowelsIncreaseMultiplier -- 0.5% of the max bowel value * multiplier

    defecateValue = defecateValue + defecateIncrease -- Increase the defecation value by the calculated percentage
    player:getModData().defecateValue = tonumber(defecateValue) -- Save the updated value back to the player's modData
    print("Updated Defecate Value: " .. defecateValue) -- Debug print statement to display the updated defecation value

end

function BathroomFunctions.CheckForAccident()
    local urinateValue = BathroomFunctions.GetUrinateValue() -- Current bladder level
    local defecateValue = BathroomFunctions.GetDefecateValue() -- Current bowel level
    local player = getPlayer()

    -- Retrieve maximum values from SandboxVars
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Default to 100 if not set
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Default to 100 if not set

    -- Calculate thresholds
    local bladderThreshold = 0.9 * bladderMaxValue -- 90% of max bladder value
    local bowelsThreshold = 0.95 * bowelsMaxValue -- 95% of max bowel value

    -- Check if the player should urinate involuntarily
    if urinateValue >= bladderThreshold then
        BathroomFunctions.UrinateSelf()
    end

    -- Check if the player should defecate involuntarily
    if defecateValue >= bowelsThreshold then
        BathroomFunctions.DefecateSelf()
    end
end












-- =====================================================
--
-- ACCIDENT FUNCTIONS
--
-- =====================================================

-- Function to handle the defecation action when the player has an accident
function BathroomFunctions.DefecateSelf()
    local player = getPlayer() -- Fetch the current player object
    local defecateValue = BathroomFunctions.GetDefecateValue() -- Current bowel level
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Get the max bowel value, default to 100 if not set

    -- Check if player has relevant clothing on and apply the "pooped bottoms" effects
    if BathroomFunctions.HasClothingOn(player, "UnderwearBottom", "Pants", "BathRobe", "FullSuit") then
        BathroomFunctions.DefecateBottoms()
    end

    -- Set the defecate value to 0 as the player has defecated
    BathroomFunctions.SetDefecateValue(0)

    print("Updated Pooped Self Value: " .. BathroomFunctions.GetPoopedSelfValue()) -- Debug print statement to display the updated defecation value
end

-- Function to handle the urination action when the player has an accident
function BathroomFunctions.UrinateSelf()
    local player = getPlayer() -- Fetch the current player object
    local urinateValue = BathroomFunctions.GetUrinateValue() -- Current bladder level
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Get the max bladder value, default to 100 if not set

    -- Check if player has relevant clothing on and apply the "peed bottoms" effects
    if BathroomFunctions.HasClothingOn(player, "UnderwearBottom", "Pants", "BathRobe", "FullSuit") then
        BathroomFunctions.UrinateBottoms()
    end

    -- Set the urinate value to 0 as the player has urinated
    BathroomFunctions.SetUrinateValue(0)

    print("Updated Peed Self Value: " .. BathroomFunctions.GetPeedSelfValue()) -- Debug print statement to display the updated urination value
end

-- Function to apply effects when the player has urinated in their clothing
function BathroomFunctions.UrinateBottoms()
    local player = getPlayer()

    local clothing = nil
    local bodyLocations = {"UnderwearBottom", "Torso1Legs1", "Legs1", "Pants", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume"}

    -- Check if the player is wearing any of the specified clothing
    for i = 1, #bodyLocations do
        clothing = player:getWornItem(bodyLocations[i])
        if clothing then
            local modData = clothing:getModData()

            -- Ensure 'peedSeverity' is initialized if it doesn't exist
            if modData.peedSeverity == nil then
                modData.peedSeverity = 0
            end

            -- Mark the clothing as soiled by urine
            modData.peed = true
            modData.peedSeverity = modData.peedSeverity + 25

            -- Cap the 'peedSeverity' at 100
            if modData.peedSeverity >= 100 then
                modData.peedSeverity = 100
            end

            -- Update the clothing's condition after the accident
            BathroomFunctions.PeedPoopedSelfUpdate(clothing)
        end
    end

    -- Update player stats for the accident
    player:getStats():setStress(player:getStats():getStress() + 0.6)
    player:getBodyDamage():setUnhappynessLevel(player:getBodyDamage():getUnhappynessLevel() + 20)

    -- The player says they have urinated themselves
    player:Say("I've pissed myself")
end


-- Function to apply effects when the player has defecated in their clothing
function BathroomFunctions.DefecateBottoms()
    local player = getPlayer()

    local clothing = nil
    local bodyLocations = {"UnderwearBottom", "Torso1Legs1", "Legs1", "Pants", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume"}

    -- Check if the player is wearing any of the specified clothing
    for i = 1, #bodyLocations do
        clothing = player:getWornItem(bodyLocations[i])
        if clothing then
            local modData = clothing:getModData()

            -- Ensure 'poopedSeverity' is initialized if it doesn't exist
            if modData.poopedSeverity == nil then
                modData.poopedSeverity = 0
            end

            -- Mark the clothing as soiled by feces
            modData.pooped = true
            modData.poopedSeverity = modData.poopedSeverity + 25

            -- Cap the 'poopedSeverity' at 100
            if modData.poopedSeverity >= 100 then
                modData.poopedSeverity = 100
            end

            -- Update the clothing item and condition
            BathroomFunctions.SetClothing(clothing)

            -- Update the player's condition after the accident
            BathroomFunctions.PeedPoopedSelfUpdate(clothing)
        end
    end

    -- Update player stats for the accident
    player:getStats():setStress(player:getStats():getStress() + 0.8)
    player:getBodyDamage():setUnhappynessLevel(player:getBodyDamage():getUnhappynessLevel() + 30)
    player:getStats():setFatigue(player:getStats():getFatigue() + 0.025)

    -- Add dirt to simulate the mess
    player:addDirt(BloodBodyPartType.Groin, ZombRand(20, 50), false)
    player:addDirt(BloodBodyPartType.UpperLeg_L, ZombRand(20, 50), false)
    player:addDirt(BloodBodyPartType.UpperLeg_R, ZombRand(20, 50), false)

    player:getVisual():setDirt(BloodBodyPartType.Groin, ZombRand(20, 50))
    player:getVisual():setDirt(BloodBodyPartType.UpperLeg_L, ZombRand(20, 50))
    player:getVisual():setDirt(BloodBodyPartType.UpperLeg_R, ZombRand(20, 50))

    -- The player says they have defecated themselves
    player:Say("I've shit myself")
end


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

function BathroomFunctions.SetClothing(clothing)
    local cleanName = nil

    -- Check if the clothing name contains a parenthesis, which might indicate a status modifier (like "(Peed)" or "(Pooped)")
    if (string.find(clothing:getName(), "%(")) then
        local startIndex = string.find(clothing:getName(), "%(")
        -- Extract the base name of the clothing (without the status modifier in parentheses)
        cleanName = string.sub(clothing:getName(), 0, startIndex - 2)
    else
        cleanName = clothing:getName()
    end

    -- Store the original clean name of the clothing in its mod data
    clothing:getModData().originalName = cleanName

    -- If the clothing is marked as "peed" (wet), modify the clothing's properties
    if clothing:getModData().peed == true then
        -- Update the name to include the "(Peed)" status
        clothing:setName(cleanName .. " (Peed " .. clothing:getModData().peedSeverity .. "%)")
        -- Set the wetness to maximum (500) to indicate the clothing is soaked
        clothing:setWetness(500)
        -- Set the dirtyness to maximum (100) to reflect the soiled condition
        clothing:setDirtyness(100)
    end

    -- If the clothing is marked as "pooped" (dirty), modify the clothing's properties
    if clothing:getModData().pooped == true then
        -- Update the name to include the "(Pooped)" status
        clothing:setName(cleanName .. " (Pooped " .. clothing:getModData().poopedSeverity .. "%)")
        -- Set the dirtyness to maximum (100) to reflect the soiled condition
        clothing:setDirtyness(100)
        -- Reduce the player's run speed to simulate the hindrance caused by having poop in the clothing
        clothing:setRunSpeedModifier(clothing:getRunSpeedModifier() - 0.2) -- Expected effect: slower movement, but may not be very noticeable
    end

    -- If both "peed" and "pooped" statuses are true, update the clothing name to reflect both conditions
    if clothing:getModData().peed and clothing:getModData().pooped then
        clothing:setName(cleanName .. " (Peed " .. clothing:getModData().peedSeverity .. "%" .. " & " .. "Pooped " .. clothing:getModData().poopedSeverity .. "%)")
    end
end

--[[
Use this to call function to show the wearing urinated and defecated garments moodles. As well as affect the mood over time.
]]--
function BathroomFunctions.DirtyBottomsEffects()
    local player = getPlayer()
    local totalPoopedSeverity = 0
    local totalPeedSeverity = 0

    -- Iterate over all worn items
    for i = 0, player:getWornItems():size() - 1 do
        local item = player:getWornItems():getItemByIndex(i)

        -- Ensure the item is not nil before calling PeedPoopedSelfUpdate
        if item ~= nil then
            -- Update values for pooped and peed states based on item mod data
            local itemUpdatedPooped, itemUpdatedPeed = BathroomFunctions.PeedPoopedSelfUpdate(item)

            -- Accumulate the total pooped and peed severity
            if itemUpdatedPooped then
                totalPoopedSeverity = totalPoopedSeverity + item:getModData().poopedSeverity
            end
            if itemUpdatedPeed then
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

function BathroomFunctions.PeedPoopedSelfUpdate(clothing)
    local updatedPooped = false
    local updatedPeed = false

    -- Ensure 'clothing' and its 'modData' are valid before proceeding
    if clothing ~= nil and clothing:getModData() ~= nil then
        local modData = clothing:getModData()

        if modData.pooped ~= nil then -- Check if the worn item is defecated
            BathroomFunctions.SetPoopedSelfValue(modData.poopedSeverity)
            updatedPooped = true
        else
            -- If no pooped state, set to 0 (can be skipped here if handled at the end of the loop)
            BathroomFunctions.SetPoopedSelfValue(0)
        end

        if modData.peed ~= nil then -- Check if the worn item is urinated
            BathroomFunctions.SetPeedSelfValue(modData.peedSeverity)
            updatedPeed = true
        else
            -- If no peed state, set to 0 (can be skipped here if handled at the end of the loop)
            BathroomFunctions.SetPeedSelfValue(0)
        end
    else
        print("Error: Clothing or mod data is nil in PeedPoopedSelfUpdate.")
    end

    -- Debugging output
    print("Updated PeedSelfValue: " .. BathroomFunctions.GetPeedSelfValue())
    print("Updated PoopedSelfValue: " .. BathroomFunctions.GetPoopedSelfValue())

    return updatedPooped, updatedPeed
end



-- =====================================================
--
-- EVENT REGISTRATION
--
-- =====================================================

--[[
Register the BathroomFunctionTimers function to run every 10 in-game minutes
This ensures bathroom values are periodically updated.
]]--
Events.EveryTenMinutes.Add(BathroomFunctions.BathroomFunctionTimers)