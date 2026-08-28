
-- Returns true if an item is a soiled paper/rag/grass junk item that can be
-- washed. Matches the universal used-paper junk plus the legacy variants.
function BF.IsSoiledJunk(item)
    if not item then return false end
    local t = item:getType()
    -- Only cloth rags can be washed and reused. Grass and paper are disposable.
    if t == "RippedSheetsPooped" then
        return true
    end
    return false
end

function BF.WashingRightClick(player, context, worldObjects)
	--local player = getPlayer()
    player = getSpecificPlayer(player)

	local hasSoiledItem = false
	local soiledClothingEquipped = false
	local cleaningItem = nil

	-- All soiled clothing pieces and all soiled junk items (so the menu can list
	-- each of them separately, not just the last one found).
	local soiledClothingList = {}
    local soiledItems = {}

	-- Soiled clothing / rags are searched on the player (worn + main inventory).
	for i = 0, player:getInventory():getItems():size() - 1 do
		local item = player:getInventory():getItems():get(i)

		if item:getModData().peed == true or item:getModData().pooped == true then
			hasSoiledItem = true
			if item:isEquipped() then
				soiledClothingEquipped = true
			end
			table.insert(soiledClothingList, item)
		end

        -- Track any soiled junk item (used paper, rags, grass, etc.).
		if BF.IsSoiledJunk(item) then
			hasSoiledItem = true
			table.insert(soiledItems, item)
		end
	end

	-- Cleaning agent (soap/bleach) may live in bags or nearby, not just main inv.
	cleaningItem = BF.FindReachableItem(player, function(it)
		local t = it:getType()
		return t == "Soap2" or t == "Bleach" or t == "CleaningLiquid2"
	end)

	if hasSoiledItem then
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

		-- Nest under vanilla's "Sink" submenu when washing at a sink fixture;
        -- otherwise fall back to a standalone top-level entry.
        local vanillaSinkSubMenu = BF.IsSinkObject(storeWater) and BF.FindSinkSubMenu(context) or nil

        local washOption, subMenu
        if vanillaSinkSubMenu then
            washOption = vanillaSinkSubMenu:addOption("Wash Soiled Items", nil, nil)
            subMenu = ISContextMenu:getNew(vanillaSinkSubMenu)
            vanillaSinkSubMenu:addSubMenu(washOption, subMenu)
        else
            washOption = context:addOptionOnTop("Wash Soiled Items", nil, nil)
            subMenu = ISContextMenu:getNew(context)
            context:addSubMenu(washOption, subMenu)
        end
        washOption.iconTexture = getTexture("media/ui/PeedSelf.png")

		-- Soiled CLOTHING Options (one per soiled garment)
		for _, soiledClothing in ipairs(soiledClothingList) do
			if not soiledClothing:getModData().originalName then
				soiledClothing:getModData().originalName = soiledClothing:getScriptItem():getDisplayName()
			end

			local thisEquipped = soiledClothing:isEquipped()
			local option = subMenu:addOption(soiledClothing:getName(), player, BF.WashSoiled, square, soiledClothing, cleaningItem, storeWater, thisEquipped)

			local waterRemaining = storeWater:getFluidAmount()
			if waterRemaining < 15 then
				option.notAvailable = true
			end

			-- Estimate post-wash severity (use whichever soiling is present)
			local currentSeverity = math.max(soiledClothing:getModData().poopedSeverity or 0, soiledClothing:getModData().peedSeverity or 0)
			local estimatedSeverity

			if cleaningItem and cleaningItem:getCurrentUses() > 0 then
				estimatedSeverity = 0
			elseif currentSeverity > 50 then
				estimatedSeverity = ZombRand(5, 11)
			elseif currentSeverity <= 10 then
				estimatedSeverity = 0
			else
				estimatedSeverity = currentSeverity
			end

			local toolTip = ISWorldObjectContextMenu.addToolTip()
			toolTip:setName(soiledClothing:getName())
			local cleaningName = (cleaningItem and (cleaningItem:getDisplayName() or cleaningItem:getName())) or "Water"
			local severityFormatted = string.format("%5.1f%%", estimatedSeverity)
			toolTip.description = "Cleaning With: " .. cleaningName .. " | New Severity: " .. severityFormatted
			option.toolTip = toolTip
		end

        -- Soiled ITEM Option
        for _, item in ipairs(soiledItems) do
            local option = subMenu:addOption(item:getName(), player, BF.WashSoiledItem, square, item, cleaningItem, storeWater)

            local waterRemaining = storeWater:getFluidAmount()
            if waterRemaining < 5 then -- Less water needed for items
                option.notAvailable = true
            end

            -- Require a cleaning item for pooped items
            --if cleaningItem == nil or cleaningItem:getCurrentUses() <= 0 then
            --    option.notAvailable = true
            --end
        end
	end
end


function BF.WashSoiled(playerObj, square, soiledItem, bleachItem, storeWater, soiledItemEquipped)
	if not square or not luautils.walkAdj(playerObj, square, true) then
		return
	end

	if soiledItemEquipped then --Unequip soiled clothing before washing
		ISTimedActionQueue.add(ISUnequipAction:new(playerObj, soiledItem, 50))
	end
	
	ISTimedActionQueue.add(WashSoiled:new(playerObj, 400, square, soiledItem, bleachItem, storeWater, soiledItemEquipped))
end
function BF.WashSoiledItem(playerObj, square, soiledItem, bleachItem, storeWater)
	if not square or not luautils.walkAdj(playerObj, square, true) then
		return
	end
	
	ISTimedActionQueue.add(WashSoiledItem:new(playerObj, 400, square, soiledItem, bleachItem, storeWater))
end

function BF.RemoveBottomClothing(player)
    -- Every worn garment that gets in the way, tights and modded legwear included
    local removedClothing = BF.GetExcreteObstructiveWornItems(player)

    -- Take the outermost layers off first
    for i = #removedClothing, 1, -1 do
        ISTimedActionQueue.add(ISUnequipAction:new(player, removedClothing[i], 50))
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