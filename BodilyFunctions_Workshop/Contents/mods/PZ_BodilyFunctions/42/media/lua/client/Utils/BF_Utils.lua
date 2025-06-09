BF_Utils = {}

-- Tooltips helper function
function BF.AddTooltip(option, description)
    if option then
        local tooltip = ISToolTip:new()
        tooltip:initialise()
        tooltip:setVisible(false)
        tooltip.description = description
        option.toolTip = tooltip
    end
end

function BF_Utils.tableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

function BF_Utils.getWornItems(player)
    local items = {}
    for i = 0, player:getWornItems():size() - 1 do
        local item = player:getWornItems():getItemByIndex(i)
        if item then items[item:getType()] = item end
    end
    return items
end

-- =====================================================
--
-- BODILY VALUE GETTER / SETTER FUNCTIONS
--
-- =====================================================

--[[
Function to retrieve the player's current urination value
If the value isn't set or isn't a valid number, it defaults to 0.0.
]]--
function BF.GetUrinateValue()
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
function BF.GetDefecateValue()
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
function BF.SetUrinateValue(newUrinateValue)
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
function BF.SetDefecateValue(newDefecateValue)
    local player = getPlayer() -- Fetch the current player object

    -- Ensure the new value is a valid number
    if type(newDefecateValue) == "number" then
        player:getModData().defecateValue = tonumber(newDefecateValue) -- Update the defecation value in player's modData
    else
        print("Error: Invalid value for defecateValue. Must be a number.") -- Handle invalid input
    end
end

-- =====================================================
--
-- PEED / POOPED GETTER / SETTER
--
-- =====================================================

--[[
Function to retrieve the player's current peed self value
If the value isn't set or isn't a valid number, it defaults to 0.0.
]]--
function BF.GetPeedSelfValue()
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
function BF.GetPoopedSelfValue()
    local player = getPlayer() -- Fetch the current player object
    local poopedSelfValue = player:getModData().poopedSelfValue -- Retrieve the pooped self value from the player's modData

    if type(poopedSelfValue) ~= "number" then -- Ensure the retrieved value is a valid number
        poopedSelfValue = 0.0 -- Default to 0.0 if the value is invalid or undefined
    end

    return poopedSelfValue -- Return the pooped self value
end

function BF.SetPeedSelfValue(newPeedSelfValue)
    local player = getPlayer() -- Fetch the current player object

    -- Ensure the new value is a valid number
    if type(newPeedSelfValue) == "number" then
        player:getModData().peedSelfValue = tonumber(newPeedSelfValue)
    else
        print("Error: Invalid value for urinateValue. Must be a number.") -- Handle invalid input
    end
end
function BF.SetPoopedSelfValue(newPoopedSelfValue)
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
-- BODILY FUMES GETTER / SETTER
--
-- =====================================================

--[[
Function to retrieve the player's current bodily fumes value (smell moodle)
If the value isn't set or isn't a valid number, it defaults to 0.0.
]]--
function BF.GetBodilyFumesValue()
    local player = getPlayer() -- Fetch the current player object
    local bodilyFumesValue = player:getModData().bodilyFumesValue -- Retrieve the bodily fumes value from the player's modData

    if type(bodilyFumesValue) ~= "number" then -- Ensure the retrieved value is a valid number
        bodilyFumesValue = 0.0 -- Default to 0.0 if the value is invalid or undefined
    end

    return bodilyFumesValue -- Return the bodily fumes value
end

--[[
Function to set the player's current bodily fumes value (smell moodle)
Ensures the value is a valid number and updates the player's modData.
]]
function BF.SetBodilyFumesValue(newBodilyFumesValue)
    local player = getPlayer() -- Fetch the current player object

    -- Ensure the new value is a valid number
    if type(newBodilyFumesValue) == "number" then
        player:getModData().bodilyFumesValue = tonumber(newBodilyFumesValue) -- Update the bodily fumes value in player's modData
    else
        print("Error: Invalid value for bodilyFumesValue. Must be a number.") -- Handle invalid input
    end
end

-- =====================================================
--
-- OTHER GETTERS
--
-- =====================================================

function BF.GetMaxBowelValue()
    --local bowelsMaxValue = SandboxVars.BF.BowelsMaxValue or 500
    local bowelsMaxValue = SandboxVars.BF.BowelsMaxValue or 100

    return bowelsMaxValue
end
function BF.GetMaxBladderValue()
    --local bladderMaxValue = SandboxVars.BF.BladderMaxValue or 800
    local bladderMaxValue = SandboxVars.BF.BladderMaxValue or 100

    return bladderMaxValue
end