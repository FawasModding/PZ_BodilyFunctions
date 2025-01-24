--

-- KNOWN BUGS TO FIX!!!

-- 1. Wiping clothing doesn't do anything
-- 2. Each TP item needs its own pooped variant (WORKING)
-- 3. Actual TP stops being useable once used, even if it's only once!'
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

    -- Check for drainable items (e.g., Toilet Paper)
    if self.wipeType == "usingDrainable" then
        -- Reduce the drainable item's uses left
        self.wipingWith:Use()
        return
    end

    -- Check for non-drainable wipeables (e.g., Tissue, Paper Napkins, etc.)
    if self.wipeType == "usingOneTime" then
        -- Remove the one-time use item from inventory
        self.character:getInventory():Remove(self.wipingWith)

        -- Add an item of the type wipeType:getType() .. "Pooped"
        local poopedItem = self.wipingWith:getType() .. "Pooped"
        self.character:getInventory():AddItem("BathroomFunctions." .. poopedItem)

        return
    end

    -- Check for clothing wipeables (e.g., Bra, Underwear, etc.)
    if self.wipeType == "usingClothing" then
        local modData = self.wipingWith:getModData()
            
        if self.bodilyFunction == "pee" then
            -- Ensure 'peedSeverity' is initialized if it doesn't exist
            if modData.peedSeverity == nil then
                modData.peedSeverity = 0
            end

            -- Mark the clothing as soiled by urine
            modData.peed = true
            modData.peedSeverity = modData.peedSeverity + 5

            -- Cap the 'peedSeverity' at 100
            if modData.peedSeverity >= 100 then
                modData.peedSeverity = 100
            end

        elseif self.bodilyFunction == "poop" then
            -- Ensure 'poopedSeverity' is initialized if it doesn't exist
            if modData.poopedSeverity == nil then
                modData.poopedSeverity = 0
            end

            -- Mark the clothing as soiled by feces
            modData.pooped = true
            modData.poopedSeverity = modData.poopedSeverity + 5

            -- Cap the 'poopedSeverity' at 100
            if modData.poopedSeverity >= 100 then
                modData.poopedSeverity = 100
            end

        end

        BathroomFunctions.SetClothing(wipingWith)

        return
    end
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