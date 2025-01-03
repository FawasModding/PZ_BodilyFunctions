-- =====================================================
--
-- BATHROOM VALUE GETTER / SETTER FUNCTIONS
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

--[[
Function defining all of the soilable clothing.
]]--
function BathroomFunctions.GetSoilableClothing()
    local bodyLocations = {"UnderwearBottom", "Underwear", "Torso1Legs1", "Legs1", "Pants", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume", "ShortPants"}
    return bodyLocations
end
