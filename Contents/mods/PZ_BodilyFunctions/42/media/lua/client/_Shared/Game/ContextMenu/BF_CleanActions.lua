function BF.CleaningRightClick(player, context, worldObjects)
    local playerObj = getSpecificPlayer(player)
    local inventory = playerObj:getInventory()

    local potentialCleaningItems = {"Mop", "ToiletBrush", "DishCloth", "BathTowel"}
    local urinePuddle = false
    local puddleToRemove = nil  -- Store puddle item to remove later
    local puddleSquare = nil    -- Store square where the puddle is located
    local detectionRadius = 2

    -- Search for urine puddles nearby
    local playerSquare = playerObj:getSquare()
    if playerSquare then
        for dx = -detectionRadius, detectionRadius do
            for dy = -detectionRadius, detectionRadius do
                local nearbySquare = getCell():getGridSquare(playerSquare:getX() + dx, playerSquare:getY() + dy, playerSquare:getZ())
                if nearbySquare then
                    for i = 0, nearbySquare:getObjects():size() - 1 do
                        local item = nearbySquare:getObjects():get(i)
                        if item and item:getObjectName() == "WorldInventoryItem" then
                            local worldItem = item:getItem()
                            if worldItem and worldItem:getType() == "Urine_Hydrated_0" then
                                urinePuddle = true
                                puddleToRemove = item
                                puddleSquare = nearbySquare
                                break
                            end
                        end
                    end
                end
                if urinePuddle then break end
            end
            if urinePuddle then break end
        end
    end

    -- If a urine puddle was found, add cleaning options
    if urinePuddle and puddleSquare and puddleToRemove then
        for _, itemName in ipairs(potentialCleaningItems) do
            -- Check if the player has any cleaning item in the inventory
            if inventory:contains(itemName) then
                local cleaningItem = inventory:getFirstType(itemName)  -- Get the first item of this type

                -- Add context menu option for cleaning
                local cleanOption = context:addOption("Clean Urine With " .. itemName, worldObjects, function()

                    -- Timed action to walk to the puddle's square'
                    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, puddleSquare))

                    -- Trigger the cleaning Timed Action with the correct cleaning item
                    ISTimedActionQueue.add(CleanWasteProduct:new(playerObj, 150, puddleSquare, puddleToRemove, cleaningItem)) -- 150 = duration

                end)
                cleanOption.iconTexture = getTexture("media/textures/Mop.png");

                return
            end
        end
    end
end


-- Overwriting the base grab function so that you cannot pick up human urine
-- TODO: Remove display name for urine so it doesn't show in the inventory, and implement custom cleaning mechanic with mop
ISGrabItemAction.o_transferItem = ISGrabItemAction.transferItem

function ISGrabItemAction:transferItem(item)
    local itemObject = item:getItem()
    if itemObject:getType() == "Urine_Hydrated_0" then
        local modOptions = PZAPI.ModOptions:getOptions("BF")

        local playerSayStatus = modOptions:getOption("6")
	    if(playerSayStatus:getValue(1)) then
            self.character:Say(getText("IGUI_announce_CantPickUpPee"))
        end
        --print("Blocked picking up Urine_Hydrated_0!")
    else
        self:o_transferItem(item)
    end
end

function BF.CleanUrine()

end

Events.OnFillWorldObjectContextMenu.Add(BF.CleaningRightClick)