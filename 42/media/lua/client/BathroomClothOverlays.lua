BathroomClothOverlays = {}

-- Table to track previously worn items
--BathroomClothOverlays.previousWornItems = {}

-- Arrays to store the items by type
BathroomClothOverlays.suitTrousersMeshPeedItems = {}
BathroomClothOverlays.maleBoxersPantsItems = {}
BathroomClothOverlays.femaleUnderpantsPeedItems = {}

-- Function to populate the arrays with test items
function BathroomClothOverlays.populateTestItems()
    -- Define lists for each item type
    local suitTrousersMeshItems = {"Trousers_Suit", "Trousers_SuitTEXTURE", "Trousers_Scrubs"}
    local maleBoxersPantsItems = 
    {
        "Boxers_White",
        "Male_Boxers_Pants_2",
        "Male_Boxers_Pants_3",
        "Boxers_Hearts",
        "Boxers_Silk_Black",
        "Boxers_Silk_Red",
        "Boxers_RedStripes"
    }
    local femaleUnderpantsPeedItems =
    {
        "Underpants_White",
        "Bikini_TINT",
        "Underpants_Black",
        "Underpants_RedSpots",
        "Underpants_AnimalPrint",
        "Underpants_Hide",
        "FrillyUnderpants_Black",
        "FrillyUnderpants_Pink",
        "FrillyUnderpants_Red",
        "Briefs_White",
        "Briefs_AnimalPrints",
        "Briefs_SmallTrunks_Black",
        "Briefs_SmallTrunks_Blue",
        "Briefs_SmallTrunks_Red",
        "Briefs_SmallTrunks_WhiteTINT",
        "Shorts_CamoGreenLong",
        "Shorts_CamoUrbanLong",
        "Shorts_OliveDrabLong",
        "Shorts_CamoDesertNewLong",
        "Shorts_CamoMiliusLong",
        "Shorts_CamoTigerStripeLong",
        "Shorts_LongDenim",
        "Shorts_LongDenim_Punk",
        "Shorts_LongSport",
        "Shorts_LongSport_Red",
        "Shorts_BoxingRed",
        "Shorts_BoxingBlue",
        "Shorts_ShortDenim",
        "Shorts_ShortFormal",
        "Shorts_ShortSport",
        "Shorts_FootballPants",
        "Shorts_FootballPants_Black",
        "Shorts_FootballPants_Gold",
        "Shorts_FootballPants_White",
        "Shorts_HockeyPants",
        "Shorts_HockeyPants_Black",
        "Shorts_HockeyPants_Red",
        "Shorts_HockeyPants_UniBlue",
        "Shorts_HockeyPants_White"

    }



    -- Insert the items into their respective arrays
    for _, itemType in ipairs(suitTrousersMeshItems) do
        table.insert(BathroomClothOverlays.suitTrousersMeshPeedItems, itemType)
    end
    for _, itemType in ipairs(maleBoxersPantsItems) do
        table.insert(BathroomClothOverlays.maleBoxersPantsItems, itemType)
    end
    for _, itemType in ipairs(femaleUnderpantsPeedItems) do
        table.insert(BathroomClothOverlays.femaleUnderpantsPeedItems, itemType)
    end
end

-- Call this function to populate the test items when the script starts
Events.OnLoad.Add(function()
    BathroomClothOverlays.populateTestItems()  -- Populate test items
end)

-- Helper function to build a table of currently worn items
function BathroomClothOverlays.getCurrentWornItems(player)
    local currentWornItems = {}
    for i = 0, player:getWornItems():size() - 1 do
        local item = player:getWornItems():getItemByIndex(i)
        if item then
            currentWornItems[item] = true
        end
    end
    return currentWornItems
end

-- Function to add the correct peed item to the player, based on worn items and only if it's not already in the inventory
function BathroomClothOverlays.equipPeedOverlays(player)
    -- Get the player's worn items
    local currentWornItems = BathroomClothOverlays.getCurrentWornItems(player)

    -- Default peed item
    local appliedPeedItem = "Female_Underpants_Peed"
    local hasSuitTrousersMesh = false
    local hasMaleBoxersPants = false
    local hasFemaleUnderpants = false
    local isDefault = true

    -- Check which item the player is wearing and select the corresponding "peed" item
    for wornItem, _ in pairs(currentWornItems) do
        if wornItem:getModData().peed == true then
            -- Detect if the player is wearing a "peed" item
            if table.contains(BathroomClothOverlays.suitTrousersMeshPeedItems, wornItem:getType()) then
                hasSuitTrousersMesh = true
                isDefault = false  -- Not default if we find a match
            elseif table.contains(BathroomClothOverlays.maleBoxersPantsItems, wornItem:getType()) then
                hasMaleBoxersPants = true
                isDefault = false  -- Not default if we find a match
            elseif table.contains(BathroomClothOverlays.femaleUnderpantsPeedItems, wornItem:getType()) then
                hasFemaleUnderpants = true
                isDefault = false  -- Not default if we find a match
            end
        end
    end

    -- If this specific item is not defined in the tables, fall back to the default trouser pee ovelray
    if isDefault then
        if not currentWornItems["BathroomFunctions.SuitTrousersMesh_Peed"] then
            local itemToWear = player:getInventory():AddItem("BathroomFunctions.SuitTrousersMesh_Peed")
            player:setWornItem("PeedOverlay", itemToWear)
            --print("Equipped Female_Underpants_Peed (default)")
        end
        return
    end

    -- Check if the selected "peed" items are already in the player's inventory
    -- Add the correct "peed" items based on what the player is wearing
    if hasSuitTrousersMesh and not currentWornItems["BathroomFunctions.SuitTrousersMesh_Peed"] then
        local itemToWear = player:getInventory():AddItem("BathroomFunctions.SuitTrousersMesh_Peed")
        player:setWornItem("PeedOverlay2", itemToWear)
        --print("Equipped SuitTrousersMesh_Peed")
    end
    if hasMaleBoxersPants and not currentWornItems["BathroomFunctions.Male_Boxers_Peed"] then
        local itemToWear = player:getInventory():AddItem("BathroomFunctions.Male_Boxers_Peed")
        player:setWornItem("PeedOverlay", itemToWear)
        --print("Equipped Male_Boxers_Peed")
    end
    if hasFemaleUnderpants and not currentWornItems["BathroomFunctions.Female_Underpants_Peed"] then
        local itemToWear = player:getInventory():AddItem("BathroomFunctions.Female_Underpants_Peed")
        player:setWornItem("PeedOverlay", itemToWear)
        --print("Equipped Female_Underpants_Peed")
    end
end

-- Helper function to check if an item type is in a list
function table.contains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Function to remove all instances of peed overlays from the player's inventory
function BathroomClothOverlays.removePeedOverlays(player)
    -- Get the player's inventory
    local inventory = player:getInventory()
    
    -- Create a list of items to remove to avoid modifying the inventory during iteration
    local itemsToRemove = {}

    -- Collect items tagged as "BathroomOverlay", the tag used by peed overlays (and maybe pooped overlays if I decide I want to watch the world burn)
    for i = 0, inventory:getItems():size() - 1 do
        local item = inventory:getItems():get(i)
        if item and item:hasTag("BathroomOverlay") then
            table.insert(itemsToRemove, item)
        end
    end

    -- Remove collected items from the inventory
    for _, item in ipairs(itemsToRemove) do
        inventory:Remove(item)
        player:removeWornItem(item)
        --print("Removed BathroomOverlay item: " .. tostring(item:getDisplayName()))
    end
end

-- Function to handle the clothing check
function BathroomClothOverlays.OnClothingChanged(player)

    -- THIS IS THE OVERARCHING BOOL THAT DECIDES IF THIS FEATURE WORKS IN-GAME
    if SandboxVars.BathroomFunctions.VisiblePeeStain == true then

        local player = getPlayer() -- needed because of EveryOneMinute

        -- Always remove the overlay first to ensure no (or, less than there would be lmao) duplicates
        -- Kind of inefficient but this has already taken too much time :|   If you're reading this, fix it and propose a change
        BathroomClothOverlays.removePeedOverlays(player)

        -- store all "peed" items from the inventory
        local peedItems = {}

        -- Check the player's inventory for "peed" items
        local inventory = player:getInventory()
        for i = 0, inventory:getItems():size() - 1 do
            local item = inventory:getItems():get(i)
            if item and item:getModData().peed == true then
                --print("Found peed item in inventory: " .. tostring(item:getDisplayName()))
                table.insert(peedItems, item) -- Add to the peed items array
            end
        end

        -- If no "peed" items are found in the inventory, return, since the rest is unnecessary
        if #peedItems == 0 then
            --print("No peed items found in inventory. Overlay removed.")
            return
        end

        -- Perform the actual check of worn items
        local currentWornItems = BathroomClothOverlays.getCurrentWornItems(player)

        local equipped = false

        for wornItem, _ in pairs(currentWornItems) do
            for _, peedItem in ipairs(peedItems) do
                -- Compare worn item and inventory item by their unique types
                if wornItem:getModData() and wornItem:getModData().peed == true then
                    --print("Player is wearing a peed item: " .. tostring(wornItem:getDisplayName()))
                    BathroomClothOverlays.equipPeedOverlays(player)
                    equipped = true
                end
            end
        end

        -- If no worn items match the "peed" items array, overlay stays removed
        if not equipped then
            --print("No peed items worn. Overlay removed.")
        end

    end
end

Events.OnClothingUpdated.Add(BathroomClothOverlays.OnClothingChanged)
--Events.EveryTenMinutes.Add(BathroomClothOverlays.OnClothingChanged)

-- Lazy fix for the onclothingchanged not detecting things properly problem, not very optimized
Events.EveryOneMinute.Add(BathroomClothOverlays.OnClothingChanged)