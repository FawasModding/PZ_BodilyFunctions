BathroomClothOverlays = {}

-- Table to track previously worn items
BathroomClothOverlays.previousWornItems = {}

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

-- Helper function to check if the Female_Underpants_Peed is already in the inventory
function BathroomClothOverlays.isFemaleUnderpantsPeedInInventory(player)
    local inventory = player:getInventory()
    -- Iterate through all the items in the inventory and check if the item exists
    for i = 0, inventory:getItems():size() - 1 do
        local item = inventory:getItems():get(i)
        if item and item:getType() == "BathroomFunctions.Female_Underpants_Peed" then
            return true -- Found the item, return true
        end
    end
    return false -- Item not found
end

-- Function to add Female_Underpants_Peed to the player, but only if it's not already in the inventory
function BathroomClothOverlays.equipFemaleUnderpantsPeed(player)
    local femaleUnderpantsPeed = player:getInventory():AddItem("BathroomFunctions.Female_Underpants_Peed") -- Replace with the correct item type if needed
    player:setWornItem("PeedOverlay", femaleUnderpantsPeed) -- Equip the item
    print("Equipped Female_Underpants_Peed")
end

-- Function to remove all instances of Female_Underpants_Peed from the player's inventory
function BathroomClothOverlays.removeFemaleUnderpantsPeed(player)
    -- Get the player's inventory
    local inventory = player:getInventory()
    
    -- Create a list of items to remove to avoid modifying the inventory during iteration
    local itemsToRemove = {}

    -- Collect items tagged as "BathroomOverlay"
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
        print("Removed BathroomOverlay item: " .. tostring(item:getDisplayName()))
    end
end

-- Store a global variable for the timer
local delayTimer = nil

-- Function to handle the delayed clothing check
function BathroomClothOverlays.OnClothingChanged(player)

    local player = getPlayer()

    -- Always remove the overlay first to ensure it's in sync with current state
    BathroomClothOverlays.removeFemaleUnderpantsPeed(player)

    -- Array to store all "peed" items from the inventory
    local peedItems = {}

    -- Check the player's inventory for "peed" items
    local inventory = player:getInventory()
    for i = 0, inventory:getItems():size() - 1 do
        local item = inventory:getItems():get(i)
        if item and item:getModData().peed == true then
            print("Found peed item in inventory: " .. tostring(item:getDisplayName()))
            table.insert(peedItems, item) -- Add to the peed items array
        end
    end

    -- If no "peed" items are found in the inventory, no need to proceed further
    if #peedItems == 0 then
        print("No peed items found in inventory. Overlay removed.")
        return
    end

    -- Function to check after the delay has passed
    local function delayedCheck()
        -- Perform the actual check of worn items
        local currentWornItems = BathroomClothOverlays.getCurrentWornItems(player)

        for wornItem, _ in pairs(currentWornItems) do
            for _, peedItem in ipairs(peedItems) do
                -- Compare worn item and inventory item by their unique types
                if wornItem:getModData() and wornItem:getModData().peed == true then
                    print("Player is wearing a peed item: " .. tostring(wornItem:getDisplayName()))
                    BathroomClothOverlays.equipFemaleUnderpantsPeed(player)
                    return -- Exit early since we only need to equip once
                end
            end
        end

        -- If no worn items match the "peed" items array, overlay stays removed
        print("No peed items worn. Overlay removed.")
    end

    delayedCheck()
end

-- Add the event listener for clothing changes
Events.OnClothingUpdated.Add(BathroomClothOverlays.OnClothingChanged)
--Events.EveryTenMinutes.Add(BathroomClothOverlays.OnClothingChanged)

-- Lazy fix for the onclothingchanged not detecting things properly problem, not very optimized
Events.EveryOneMinute.Add(BathroomClothOverlays.OnClothingChanged)