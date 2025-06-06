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

    -- Check for drainable items (e.g., Toilet Paper)
    if self.wipeType == "usingDrainable" then
        -- Reduce the drainable item's uses left
        self.wipingWith:Use()
        return
    end

    -- Check for non-drainable wipeables (Tissue, Magazines, Newspapers, etc.)
    if self.wipeType == "usingOneTime" then
        local itemType = self.wipingWith:getType()
        local poopedItem = nil

        -- Remove original item
        self.character:getInventory():Remove(self.wipingWith)

        -- Determine which shared pooped item to give
        if string.find(itemType, "Newspaper") then
            poopedItem = "NewspaperPooped"
        elseif string.find(itemType, "Magazine") then
            poopedItem = "MagazinePooped"
        elseif itemType == "HottieZ_New" or itemType == "HottieZ" then
            poopedItem = "HottieZPooped"
        elseif itemType == "HunkZ" then
            poopedItem = "HunkZPooped"
        else
            -- Fallback if none of the above, try to append "Pooped" to the type
            poopedItem = self.wipingWith:getType() .. "Pooped"
        end

        -- Add the appropriate pooped version if defined
        if poopedItem then
            self.character:getInventory():AddItem("BathroomFunctions." .. poopedItem)
            
            -- Debug line: Print what item was added
            print("DEBUG: Added pooped item: " .. poopedItem)
        end

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

        -- FIX THIS NEXT PATCH
        --BathroomFunctions.SetClothing(wipingWith)

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