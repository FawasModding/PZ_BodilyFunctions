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
This value determines how much the player needs to urinate.
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
This value determines how much the player needs to defecate.
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
    local urinateIncrease = SandboxVars.BathroomFunctions.UrinateIncreaseMultiplier -- Get the urination increase rate from SandboxVars

    urinateValue = urinateValue + urinateIncrease -- Increase the urination value by the multiplier
    player:getModData().urinateValue = tonumber(urinateValue) -- Save the updated value back to the player's modData
    print(urinateValue) -- Debug print statement to display the updated urination value

    -- === DEFECATION ===

    -- Update the defecation value
    local defecateValue = BathroomFunctions.GetDefecateValue() -- Get the current defecation value
    local defecateIncrease = 0.5 * SandboxVars.BathroomFunctions.DefecateIncreaseMultiplier -- Calculate the defecation increase rate

    defecateValue = defecateValue + defecateIncrease -- Increase the defecation value by the calculated rate
    player:getModData().defecateValue = tonumber(defecateValue) -- Save the updated value back to the player's modData
    print(defecateValue) -- Debug print statement to display the updated defecation value
end

function BathroomFunctions.CheckForAccident()
    local urinateValue = BathroomFunctions.GetUrinateValue()
    local defecateValue = BathroomFunctions.GetDefecateValue()
    local player = getPlayer()

    -- CALCULATE

    if urinateValue >= 90 then --Can pee self
        BathroomFunctions.UrinateSelf()
    end

    if defecateValue >= 95 then --Can poop self
        BathroomFunctions.DefecateSelf()
    end
end

-- =====================================================
--
-- ACCIDENT FUNCTIONS
--
-- =====================================================

function BathroomFunctions.UrinateSelf()
    local player = getPlayer()

    player:Say("I pissed myself")
end

function BathroomFunctions.DefecateSelf()
    local player = getPlayer()

    player:Say("I shit myself")
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