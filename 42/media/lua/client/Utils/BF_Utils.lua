-- Tooltips helper function
function BathroomFunctions.AddTooltip(option, description)
    if option then
        local tooltip = ISToolTip:new()
        tooltip:initialise()
        tooltip:setVisible(false)
        tooltip.description = description
        option.toolTip = tooltip
    end
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

-- =====================================================
--
-- PEED / POOPED GETTER / SETTER
--
-- =====================================================

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
-- GET CLOTHING LISTS
--
-- =====================================================

--[[
Function defining all of the soilable clothing.
]]--
function BathroomFunctions.GetSoilableClothing()
    local bodyLocations = {"UnderwearBottom", "Underwear", "Torso1Legs1", "Legs1", "Pants", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume", "ShortPants", "ShortsShort"}
    return bodyLocations
end

--[[
Clothes that need to be removed before using the bathroom. Includes dresses and skirts, which cannot be soiled (yet)
]]--
function BathroomFunctions.GetExcreteObstructiveClothing()
    local bodyLocations = {
    "UnderwearBottom", "Underwear", "Torso1Legs1", "Legs1", "Pants", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume", "ShortPants", "ShortsShort",
    "LongDress", "Dress", "LongSkirt", "Skirt"
    }

    return bodyLocations
end

-- =====================================================
--
-- GET WIPING LISTS
--
-- =====================================================

--[[
Items (usually paper variants) that can be used to wipe either for peeing (females only) or for defecation.
]]--

-- These ones are things that have multiple per, like toilet paper
function BathroomFunctions.GetDrainableWipeables()
    local wipeItems = {
    "ToiletPaper" }

    return wipeItems
end
-- These ones are things that can only be used once. So paper, to poop you'll need 4 individual Paper items
function BathroomFunctions.GetOneTimeWipeables()
    local wipeItems = {
    "Tissue", "PaperNapkins2", "GraphPaper", "Paperwork",
    "SheetPaper2", "Receipt", "RippedSheets",
    "Newspaper_Old", "Newspaper_Recent", "Newspaper_New", "Newspaper_Dispatch_New", "Newspaper_Herald_New", "Newspaper_Knews_New", "Newspaper_Times_New",
    "TVMagazine", "Magazine_Art", "Magazine_Business", "Magazine_Car", "Magazine_Childs", "Magazine_Cinema", "Magazine_Crime",
    "Magazine_Fashion", "Magazine_Firearm", "Magazine_Gaming", "Magazine_Golf", "Magazine_Health", "Magazine_Hobby", "Magazine_Horror", "Magazine_Humor", "Magazine_Military",
    "Magazine_Music", "Magazine_Outdoors", "Magazine_Police", "Magazine_Popular", "Magazine_Rich", "Magazine_Science", "Magazine_Sports", "Magazine_Tech", "Magazine_Teens",
    "HottieZ_New", "HottieZ", "HunkZ"}

    return wipeItems
end
-- These ones are clothing. Sets the peed and pooped values to the ones that happen when you actually pee / poop, only soft / realistic materials can be included here.
function BathroomFunctions.GetClothingWipeables()
    local wipeItems = { -- Bras and underwear bottoms are soft, therefore they'd be useable.
    "UnderwearBottom", "UnderwearTop" }

    return wipeItems
end

-- =====================================================
--
-- GET TOILET / ALTERNATIVES LISTS
--
-- =====================================================

function BathroomFunctions.GetToiletTiles()
    local toiletTiles = {
    "fixtures_bathroom_01_0", "fixtures_bathroom_01_1", "fixtures_bathroom_01_2", "fixtures_bathroom_01_3", 
    "fixtures_bathroom_01_4", "fixtures_bathroom_01_5", "fixtures_bathroom_01_6", "fixtures_bathroom_01_7"}

    return toiletTiles
end

function BathroomFunctions.GetUrinalTiles()
    local urinalTiles = {
    "fixtures_bathroom_01_8", "fixtures_bathroom_01_9", "fixtures_bathroom_01_10", "fixtures_bathroom_01_11" }

    return urinalTiles
end

function BathroomFunctions.GetOuthouseTiles()
    local outhouseTiles = {
    "fixtures_bathroom_02_24", "fixtures_bathroom_02_25", "fixtures_bathroom_02_26", "fixtures_bathroom_02_27",
    "fixtures_bathroom_02_4", "fixtures_bathroom_02_5", "fixtures_bathroom_02_14", "fixtures_bathroom_02_15" }

    return outhouseTiles
end

function BathroomFunctions.GetShowerTiles()
    local showerTiles = {
    "fixtures_bathroom_01_24", "fixtures_bathroom_01_25", "fixtures_bathroom_01_26", "fixtures_bathroom_01_27",
    "fixtures_bathroom_01_32", "fixtures_bathroom_01_33", "fixtures_bathroom_01_52", "fixtures_bathroom_01_53",
    "fixtures_bathroom_01_54", "fixtures_bathroom_01_55"}

    return showerTiles
end