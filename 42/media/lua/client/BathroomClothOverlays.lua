BathroomClothOverlays = {}

-- Table to track previously worn items
--BathroomClothOverlays.previousWornItems = {}

-- Arrays to store the items by type
BathroomClothOverlays.peedModelsSuitTrousersMesh = {}
BathroomClothOverlays.peedModelsMaleBoxers = {}
BathroomClothOverlays.peedModelsFemalePanties = {}

function BathroomClothOverlays.PopulatePeedModels()
    -- Define lists for which model each clothing item uses.
    local peedModelsSuitTrousersMesh = {
        "Trousers_Suit", "Trousers_SuitTEXTURE", "Trousers_Scrubs" }
    local peedModelsMaleBoxers = {
        "Boxers_White",
        "Male_Boxers_Pants_2", "Male_Boxers_Pants_3", "Boxers_Hearts",
        "Boxers_Silk_Black", "Boxers_Silk_Red", "Boxers_RedStripes" }
    local peedModelsFemalePanties = {
        "Underpants_White", "Bikini_TINT", "Underpants_Black", "Underpants_RedSpots",
        "Underpants_AnimalPrint", "Underpants_Hide", "FrillyUnderpants_Black", "FrillyUnderpants_Pink",
        "FrillyUnderpants_Red", "Briefs_White", "Briefs_AnimalPrints", "Briefs_SmallTrunks_Black",
        "Briefs_SmallTrunks_Blue", "Briefs_SmallTrunks_Red", "Briefs_SmallTrunks_WhiteTINT",
        "Shorts_CamoGreenLong", "Shorts_CamoUrbanLong", "Shorts_OliveDrabLong", "Shorts_CamoDesertNewLong",
        "Shorts_CamoMiliusLong", "Shorts_CamoTigerStripeLong", "Shorts_LongDenim", "Shorts_LongDenim_Punk",
        "Shorts_LongSport", "Shorts_LongSport_Red", "Shorts_BoxingRed", "Shorts_BoxingBlue", "Shorts_ShortDenim",
        "Shorts_ShortFormal", "Shorts_ShortSport", "Shorts_FootballPants", "Shorts_FootballPants_Black",
        "Shorts_FootballPants_Gold", "Shorts_FootballPants_White", "Shorts_HockeyPants", "Shorts_HockeyPants_Black",
        "Shorts_HockeyPants_Red", "Shorts_HockeyPants_UniBlue", "Shorts_HockeyPants_White" }

    -- Insert the items into their respective arrays
    for i = 1, #peedModelsSuitTrousersMesh do
        table.insert(BathroomClothOverlays.peedModelsSuitTrousersMesh, peedModelsSuitTrousersMesh[i])
    end
    for i = 1, #peedModelsMaleBoxers do
        table.insert(BathroomClothOverlays.peedModelsMaleBoxers, peedModelsMaleBoxers[i])
    end
    for i = 1, #peedModelsFemalePanties do
        table.insert(BathroomClothOverlays.peedModelsFemalePanties, peedModelsFemalePanties[i])
    end
end

-- Populate when the game starts.
Events.OnLoad.Add(function()
    BathroomClothOverlays.PopulatePeedModels()
    BathroomClothOverlays.removeAllPeedOverlays(getPlayer())
    BathroomClothOverlays.equipAllPeedOverlays(getPlayer())
end)

function table.contains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- =====================================================
--
-- MAIN UNEQUIP / EQUIP FUNCTIONS
--
-- =====================================================

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

-- Helper function to determine which overlay should be used
function BathroomClothOverlays.getPeedOverlayItem(item)
    if table.contains(BathroomClothOverlays.peedModelsSuitTrousersMesh, item:getType()) then
        return "BathroomFunctions.SuitTrousersMesh_Peed"
    elseif table.contains(BathroomClothOverlays.peedModelsMaleBoxers, item:getType()) then
        return "BathroomFunctions.Male_Boxers_Peed"
    elseif table.contains(BathroomClothOverlays.peedModelsFemalePanties, item:getType()) then
        return "BathroomFunctions.Female_Underpants_Peed"
    end
    return "BathroomFunctions.SuitTrousersMesh_Peed" -- Default is trousers. Most undefined clothing is pants
end

-- Optimized equipPeedOverlay function
function BathroomClothOverlays.equipPeedOverlay(player, wornItem)

    if wornItem:getModData().peed == true then

        local currentWornItems = BathroomClothOverlays.getCurrentWornItems(player)
        BathroomClothOverlays.removeAllPeedOverlays(player) -- Remove all existing peed overlays
        local overlayItemType = BathroomClothOverlays.getPeedOverlayItem(wornItem) -- Get appropriate overlay item type

        -- Only add overlay if it isn't already worn
        if overlayItemType and not currentWornItems[overlayItemType] then
            local itemToWear = player:getInventory():AddItem(overlayItemType) -- Add overlay item to player's inventory
            player:setWornItem("PeedOverlay", itemToWear) -- Set overlay item as worn by player
            wornItem:getModData().peeOverlayItemType = overlayItemType -- Store type of overlay item in ModData
        end
    end
end

-- Remove the "PeeOverlayItem" associated with the WornItem
function BathroomClothOverlays.removePeedOverlay(player, wornItem)

    if wornItem:getModData().peed then
        local inventory = player:getInventory()

        local overlayItemType = wornItem:getModData().peeOverlayItemType -- Get overlay item type from ModData
        if overlayItemType then
            
            local overlayItem = inventory:getItemFromType(overlayItemType) -- Search for the item in the inventory

            -- If the overlay item is found, remove it
            if overlayItem then
                inventory:Remove(overlayItem)
                player:removeWornItem(overlayItem)
            end

            wornItem:getModData().peeOverlayItemType = nil -- Clean up ModData
        end
    end
end

-- =====================================================
--
-- ACCIDENT FUNCTIONS
--
-- =====================================================

-- Remove all overlays from the inventory
function BathroomClothOverlays.removeAllPeedOverlays(player)
    local inventory = player:getInventory()
    
    -- Create a list of items to remove
    local itemsToRemove = {}

    -- Collect items tagged as "BathroomOverlay", the tag used by peed overlays
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

function BathroomClothOverlays.equipAllPeedOverlays(player)
    -- Get the player's worn items and remove any existing overlays
    local currentWornItems = BathroomClothOverlays.getCurrentWornItems(player)
    BathroomClothOverlays.removeAllPeedOverlays(player)

    -- Loop through worn items to find applicable overlays
    for wornItem, _ in pairs(currentWornItems) do
        if wornItem:getModData().peed == true then
            -- Get the appropriate overlay item type based on the worn item
            local overlayItemType = BathroomClothOverlays.getPeedOverlayItem(wornItem)

            if overlayItemType and not currentWornItems[overlayItemType] then -- Only apply the overlay if it's not already worn
                
                local itemToWear = player:getInventory():AddItem(overlayItemType) -- Add the overlay item to the player's inventory
                player:setWornItem("PeedOverlay", itemToWear) -- Set the overlay item as worn by the player
                wornItem:getModData().peeOverlayItemType = overlayItemType -- Store the overlay item type in ModData (instead of storing the item itself)
            end
        end
    end
end

-- =====================================================
--
-- ACCIDENT FUNCTIONS
--
-- =====================================================

-- Hook to Unequip Action
ISUnequipAction.o_perform = ISUnequipAction.perform
function ISUnequipAction:perform()
    self:o_perform()

    BathroomClothOverlays.removePeedOverlay(self.character, self.item)
end

-- Hook to Equip Action
ISWearClothing.o_perform = ISWearClothing.perform
function ISWearClothing:perform()
    self:o_perform()

    BathroomClothOverlays.equipPeedOverlay(self.character, self.item)
end
