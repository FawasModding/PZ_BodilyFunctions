--

-- KNOWN BUGS TO FIX!!!

-- 2. Each TP item needs its own pooped variant (WORKING)
-- 4. For each TP item that doesn't have its own variant, it must simply not give a wiped junk item'

--

WipeSelf = ISBaseTimedAction:derive("WipeSelf")
function WipeSelf:isValid()
	return true
end

function WipeSelf:update()
    print(self.wipeType)
end

function WipeSelf:start()
    
end

function WipeSelf:stop()
	ISBaseTimedAction.stop(self)
end

function WipeSelf:perform()
    ISBaseTimedAction.perform(self)
    local wipeEfficiency = 1.0 -- Default to 100% wipe

    -- Check for drainable items (e.g., Toilet Paper)
    if self.wipeType == "usingDrainable" then
        local itemType = self.wipingWith:getType()
        local requiredUses = BF_WipingConfig.drainableWipeables[itemType].usesRequired
        local availableUses = self.wipingWith:getCurrentUses()
        wipeEfficiency = math.min(availableUses / requiredUses, 1.0)
        for i = 1, math.min(availableUses, requiredUses) do
            -- Reduce the drainable item's uses left
            self.wipingWith:Use()
        end
    end

    -- Check for non-drainable wipeables (Tissue, Magazines, Newspapers, etc.)
    if self.wipeType == "usingOneTime" then
        local itemType = self.wipingWith:getType()
        local requiredUses = BF_WipingConfig.oneTimeWipeables[itemType].usesRequired
        local availableItems = self.character:getInventory():getNumberOfItem(itemType)
        wipeEfficiency = math.min(availableItems / requiredUses, 1.0)
        
        -- Consume up to the required number of items
        local itemsToConsume = math.min(availableItems, requiredUses)
        for i = 1, itemsToConsume do
            self.character:getInventory():RemoveOneOf(itemType)
            -- Add pooped variant for each consumed item
            local poopedItem = itemType .. "Pooped"
            self.character:getInventory():AddItem("BathroomFunctions." .. poopedItem)
        end
        print("DEBUG: Consumed " .. itemsToConsume .. " items and added " .. itemsToConsume .. " pooped items: " .. itemType .. "Pooped")
    end

    -- Apply soiling penalty if wipeEfficiency < 1.0 and wiping poop
    if (self.wipeType == "usingOneTime" or self.wipeType == "usingDrainable") and wipeEfficiency < 1.0 and self.bodilyFunction == "poop" then
        local soilPenalty = 5 * (1 - wipeEfficiency) -- e.g., 2.5 for 50% efficiency
        local applied = false
        local underwearLocations = {"UnderwearBottom", "Underwear"} -- Potential underwear locations

        -- Get unequipped clothing from modData
        local removedClothing = self.character:getModData().removedClothing or {}
        print("DEBUG: Unequipped clothing check:")

        -- First, check for unequipped underwear
        print("DEBUG: Checking unequipped underwear locations: " .. table.concat(underwearLocations, ", "))
        for _, bodyLocation in ipairs(underwearLocations) do
            for _, entry in ipairs(removedClothing) do
                if entry:getBodyLocation() == bodyLocation then
                    local clothingItem = entry
                    local modData = clothingItem:getModData()
                    modData.pooped = true
                    modData.poopedSeverity = (modData.poopedSeverity or 0) + soilPenalty
                    modData.poopedSeverity = math.min(modData.poopedSeverity, 100)
                    print("DEBUG: Applied " .. soilPenalty .. "% soiling to unequipped " .. clothingItem:getType() .. " at " .. bodyLocation)
                    applied = true
                    return -- Stop after soiling underwear
                end
            end
        end

        -- If no underwear, soil unequipped non-underwear items
        if not applied then
            local soilableClothing = BathroomFunctions.GetSoilableClothing()
            local nonUnderwearLocations = {}
            for _, loc in ipairs(soilableClothing) do
                if not (loc == "UnderwearBottom" or loc == "Underwear") then
                    table.insert(nonUnderwearLocations, loc)
                end
            end
            print("DEBUG: Checking unequipped non-underwear locations: " .. table.concat(nonUnderwearLocations, ", "))
            for _, bodyLocation in ipairs(nonUnderwearLocations) do
                for _, entry in ipairs(removedClothing) do
                    if entry:getBodyLocation() == bodyLocation then
                        local clothingItem = entry
                        local modData = clothingItem:getModData()
                        modData.pooped = true
                        modData.poopedSeverity = (modData.poopedSeverity or 0) + soilPenalty
                        modData.poopedSeverity = math.min(modData.poopedSeverity, 100)
                        print("DEBUG: Applied " .. soilPenalty .. "% soiling to unequipped " .. clothingItem:getType() .. " at " .. bodyLocation)
                        applied = true
                        return -- Stop after soiling non-underwear
                    end
                end
            end
            if not applied then
                print("DEBUG: No unequipped soilable clothing found, no soiling penalty applied")
            end
        end
    end

    -- Check for clothing wipeables (e.g., UnderwearBottom, UnderwearTop)
    if self.wipeType == "usingClothing" then
        local modData = self.wipingWith:getModData()
        local itemType = self.wipingWith:getBodyLocation()
        local config = BF_WipingConfig.clothingWipeables[itemType]
        local soilPenalty = config.soilPenalty or 5

        if self.bodilyFunction == "pee" then
            modData.peed = true
            modData.peedSeverity = (modData.peedSeverity or 0) + soilPenalty
            modData.peedSeverity = math.min(modData.poopedSeverity, 100)
        elseif self.bodilyFunction == "poop" then
            modData.pooped = true
            modData.poopedSeverity = (modData.poopedSeverity or 0) + soilPenalty
            modData.poopedSeverity = math.min(modData.poopedSeverity, 100)
        end
        print("DEBUG: Applied " .. soilPenalty .. "% soiling to wiping clothing " .. self.wipingWith:getType() .. " at " .. itemType)
    end

    --BathroomFunctions.ResetRemovedClothing(self.character) -- reset removed clothing
    --self.character:getModData().removedClothing = nil
end

function WipeSelf:new(character, time, wipeType, wipingWith, bodilyFunction)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = time
    o.wipeType = wipeType
    o.wipingWith = wipingWith
    o.bodilyFunction = bodilyFunction
	return o
end