
function BF.WashingRightClick(player, context, worldObjects)
	local player = getPlayer()

	local hasSoiledClothing = false
	local soiledClothingEquipped = false
	local soiledClothing = nil
	local soapItem = nil

	-- Track soiled rags and GrassTufts, items that can be cleaned after wiping
    local soiledItems = {}

	for i = 0, player:getInventory():getItems():size() - 1 do
		local item = player:getInventory():getItems():get(i)

		if item:getType() == "Soap2" then
			soapItem = item
		end

		if item:getModData().peed == true or item:getModData().pooped == true then
			hasSoiledClothing = true
			if item:isEquipped() then
				soiledClothingEquipped = true
			end
			soiledClothing = item
		end

        -- Track soiled rags and grass tufts
		if item:getType() == "RippedSheetsPooped" or item:getType() == "GrassTuftPooped" then
			hasSoiledClothing = true
			table.insert(soiledItems, item)
		end

	end

	if hasSoiledClothing then
		local storeWater = nil
		local firstObject = nil

		for i = 1, #worldObjects do
			if not firstObject then
				firstObject = worldObjects[i]
			end
		end

		local square = firstObject:getSquare()
		local worldObjects = square:getObjects()
		for i = 0, worldObjects:size() - 1 do
			local object = worldObjects:get(i)
			if object:getTextureName() and object:hasWater() then --Anything that can usually be used to wash
				storeWater = object
			end
		end

		if storeWater == nil then return end
		if storeWater:getSquare():DistToProper(player:getSquare()) > 10 then return end

		local washOption = context:addOptionOnTop("Wash Soiled Items", nil, nil)
		washOption.iconTexture = getTexture("media/ui/PeedSelf.png")
		local subMenu = ISContextMenu:getNew(context)
		context:addSubMenu(washOption, subMenu)

		-- Original soiled clothing option
		if soiledClothing then
			if not soiledClothing:getModData().originalName then
				soiledClothing:getModData().originalName = soiledClothing:getName()
			end

			local option = subMenu:addOption(soiledClothing:getName(), player, BF.WashSoiled, square, soiledClothing, soapItem, storeWater, soiledClothingEquipped)

			local waterRemaining = storeWater:getFluidAmount()
			if waterRemaining < 15 then
				option.notAvailable = true
			end

			if soiledClothing:getModData().pooped then
				if soapItem == nil or soapItem:getCurrentUses() <= 0 then
					option.notAvailable = true
				end
			end
		end

        -- Options for soiled items
        for _, item in ipairs(soiledItems) do
            local option = subMenu:addOption(item:getName(), player, BF.WashSoiledItem, square, item, soapItem, storeWater)

            local waterRemaining = storeWater:getFluidAmount()
            if waterRemaining < 5 then -- Less water needed for items
                option.notAvailable = true
            end

            -- Require soap for pooped items
            if soapItem == nil or soapItem:getCurrentUses() <= 0 then
                option.notAvailable = true
            end
        end

		--local tooltip = ISWorldObjectContextMenu.BF.AddTooltip()
		--tooltip.description = getText("ContextMenu_WaterSource") .. ": " .. source
		--tooltip.description = tooltip.description .. " <LINE> Water: " .. tostring(math.min(waterRemaining, 15)) .. " / " .. tostring(15)
		--tooltip.description = tooltip.description .. " <LINE> Bleach: " .. bleachText .. " / 0.3"
		--tooltip.description = tooltip.description .. " <LINE> Dirty: " .. math.ceil(defecatedItem:getDirtyness()) .. " / 100"
		--option.toolTip = tooltip
	end
end


function BF.WashSoiled(playerObj, square, soiledItem, bleachItem, storeWater, soiledItemEquipped)
	if not square or not luautils.walkAdj(playerObj, square, true) then
		return
	end

	if soiledItemEquipped then --Unequip soiled clothing before washing
		ISTimedActionQueue.add(ISUnequipAction:new(playerObj, soiledItem, 50))
	end
	
	ISTimedActionQueue.add(WashSoiled:new(playerObj, 400, square, soiledItem, bleachItem, storeWater))
end
function BF.WashSoiledItem(playerObj, square, soiledItem, bleachItem, storeWater)
	if not square or not luautils.walkAdj(playerObj, square, true) then
		return
	end
	
	ISTimedActionQueue.add(WashSoiledItem:new(playerObj, 400, square, soiledItem, bleachItem, storeWater))
end

function BF.RemoveBottomClothing(player)
    local removedClothing = {}

    -- Get the list of excretion obstructive clothing body locations
    local excreteObstructive = BF.GetExcreteObstructiveClothing()

    for _, location in ipairs(excreteObstructive) do
        local clothingItem = player:getWornItem(location)
        if clothingItem then
            -- Store the removed item in the array
            table.insert(removedClothing, clothingItem)

            -- Remove the clothing with a timed action
            ISTimedActionQueue.add(ISUnequipAction:new(player, clothingItem, 50))
        end
    end

    -- Store the removed items in the player's mod data for later re-equipping
    player:getModData().removedClothing = removedClothing
end
function BF.ReequipBottomClothing(player)
    local removedClothing = player:getModData().removedClothing

    if removedClothing then
        -- Re-equip each clothing item taken off before
        for _, clothingItem in ipairs(removedClothing) do
            if clothingItem then
                -- Add the item back to the player with a timed action
                ISTimedActionQueue.add(ISWearClothing:new(player, clothingItem))
            end
        end
    end

    -- This was moved to be directly inside of the trigger functions, so it happens after wiping.
     --BF.ResetRemovedClothing(player)
end
function BF.ResetRemovedClothing(player)
    -- Clear the removed clothing list
    player:getModData().removedClothing = nil
end

Events.OnFillWorldObjectContextMenu.Add(BF.WashingRightClick)