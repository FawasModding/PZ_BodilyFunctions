BathroomFunctions = {}
BathroomFunctions.didFirstTimer = false
FlySquares = {}

-- =====================================================
--
-- BATHROOM VALUES FUNCTIONS
--
-- =====================================================

--[[
Function to retrieve the player's current urination value
If the value isn't set or isn't a valid number, it defaults to 0.0.
]]--
function BathroomFunctions.GetUrinateValue()
    local player = getPlayer() -- Fetch the current player object
    local urinateValue = player:getModData().urinateValue -- Retrieve the urination value from the player's modData

    if type(urinateValue) ~= "number" then -- Ensure the retrieved value is a valid number
        urinateValue = 0.0 -- Default to 0.0 if the value is invalid or undefined
    end

    return urinateValue -- Return the urination value
end

--[[
Function to retrieve the player's current defecation value
If the value isn't set or isn't a valid number, it defaults to 0.0.
]]--
function BathroomFunctions.GetDefecateValue()
    local player = getPlayer() -- Fetch the current player object
    local defecateValue = player:getModData().defecateValue -- Retrieve the defecation value from the player's modData

    if type(defecateValue) ~= "number" then -- Ensure the retrieved value is a valid number
        defecateValue = 0.0 -- Default to 0.0 if the value is invalid or undefined
    end

    return defecateValue -- Return the defecation value
end

--[[
Function to set the player's current urination value
Ensures the value is a valid number and updates the player's modData.
]]
function BathroomFunctions.SetUrinateValue(newUrinateValue)
    local player = getPlayer() -- Fetch the current player object

    -- Ensure the new value is a valid number
    if type(newUrinateValue) == "number" then
        player:getModData().urinateValue = tonumber(newUrinateValue) -- Update the urination value in player's modData
    else
        print("Error: Invalid value for urinateValue. Must be a number.") -- Handle invalid input
    end
end

--[[
Function to set the player's current defecation value
Ensures the value is a valid number and updates the player's modData.
]]
function BathroomFunctions.SetDefecateValue(newDefecateValue)
    local player = getPlayer() -- Fetch the current player object

    -- Ensure the new value is a valid number
    if type(newDefecateValue) == "number" then
        player:getModData().defecateValue = tonumber(newDefecateValue) -- Update the defecation value in player's modData
    else
        print("Error: Invalid value for defecateValue. Must be a number.") -- Handle invalid input
    end
end

--[[
Function to retrieve the player's current peed self value
If the value isn't set or isn't a valid number, it defaults to 0.0.
]]--
function BathroomFunctions.GetPeedSelfValue()
    local player = getPlayer() -- Fetch the current player object
    local peedSelfValue = player:getModData().peedSelfValue -- Retrieve the peed self value from the player's modData

    if type(peedSelfValue) ~= "number" then -- Ensure the retrieved value is a valid number
        peedSelfValue = 0.0 -- Default to 0.0 if the value is invalid or undefined
    end

    return peedSelfValue -- Return the peed self value
end

--[[
Function to retrieve the player's current pooped self value
If the value isn't set or isn't a valid number, it defaults to 0.0.
]]--
function BathroomFunctions.GetPoopedSelfValue()
    local player = getPlayer() -- Fetch the current player object
    local poopedSelfValue = player:getModData().poopedSelfValue -- Retrieve the pooped self value from the player's modData

    if type(poopedSelfValue) ~= "number" then -- Ensure the retrieved value is a valid number
        poopedSelfValue = 0.0 -- Default to 0.0 if the value is invalid or undefined
    end

    return poopedSelfValue -- Return the pooped self value
end

function BathroomFunctions.SetPeedSelfValue(newPeedSelfValue)
    local player = getPlayer() -- Fetch the current player object

    -- Ensure the new value is a valid number
    if type(newPeedSelfValue) == "number" then
        player:getModData().peedSelfValue = tonumber(newPeedSelfValue)
    else
        print("Error: Invalid value for urinateValue. Must be a number.") -- Handle invalid input
    end
end

function BathroomFunctions.SetPoopedSelfValue(newPoopedSelfValue)
    local player = getPlayer() -- Fetch the current player object

    -- Ensure the new value is a valid number
    if type(newPoopedSelfValue) == "number" then
        player:getModData().poopedSelfValue = tonumber(newPoopedSelfValue)
    else
        print("Error: Invalid value for defecateValue. Must be a number.") -- Handle invalid input
    end
end

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

function BathroomFunctions.DefecateSelf()
    local player = getPlayer() -- Fetch the current player object
    local defecateValue = BathroomFunctions.GetDefecateValue() -- Current bowel level
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Get the max bladder value, default to 100 if not set

    -- Increment the poopedSelfValue to represent the accident
    local poopedSelfValue = BathroomFunctions.GetPoopedSelfValue()
    poopedSelfValue = poopedSelfValue + defecateValue -- Add the current defecation value to the poopedSelfValue
    BathroomFunctions.SetPoopedSelfValue(poopedSelfValue)

    -- The player says that they pooped themselves
    player:Say("I shit myself")

    -- Set the defecate value to 0 as the player has defecated
    BathroomFunctions.SetDefecateValue(0)

    print("Updated Pooped Self Value: " .. BathroomFunctions.GetPoopedSelfValue()) -- Debug print statement to display the updated defecation value
end


function BathroomFunctions.UrinateSelf()
    local player = getPlayer() -- Fetch the current player object
    local urinateValue = BathroomFunctions.GetUrinateValue() -- Current bladder level
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Get the max bladder value, default to 100 if not set

    -- Increment the peedSelfValue to represent the accident
    local peedSelfValue = BathroomFunctions.GetPeedSelfValue()
    peedSelfValue = peedSelfValue + urinateValue -- Add the current urination value to the peedSelfValue
    BathroomFunctions.SetPeedSelfValue(peedSelfValue)

    -- The player says that they peed themselves
    player:Say("I pissed myself")

    -- Set the urinate value to 0 as the player has urinated
    BathroomFunctions.SetUrinateValue(0)

    print("Updated Peed Self Value: " .. BathroomFunctions.GetPeedSelfValue()) -- Debug print statement to display the updated defecation value
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