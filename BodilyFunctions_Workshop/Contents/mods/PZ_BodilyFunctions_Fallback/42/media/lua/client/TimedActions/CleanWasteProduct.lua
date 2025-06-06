CleanWasteProduct = ISBaseTimedAction:derive("CleanWasteProduct")
function CleanWasteProduct:isValid()
	return true
end

function CleanWasteProduct:update()
end

function CleanWasteProduct:start()
    -- Equip the cleaning item in the primary hand if it's not already equipped
    if self.cleaningItem and self.character:getPrimaryHandItem() ~= self.cleaningItem then
        self.character:setPrimaryHandItem(self.cleaningItem)
    end

    -- Determine animation based on the cleaning item
    if self.cleaningItem and self.cleaningItem:getType() == "Mop" then
        self:setActionAnim("ScrubFloor_Mop")
        self:setOverrideHandModels(self.cleaningItem, nil)
        self.sound = self.character:playSound("CleanBloodScrub")
    elseif self.cleaningItem and self.cleaningItem:getType() == "ToiletBrush" then
        self:setActionAnim("ScrubFloor_ToiletBrush")
        self:setOverrideHandModels(self.cleaningItem, nil)
        self.sound = self.character:playSound("CleanBloodScrub")
    else
        self:setActionAnim("ScrubFloor")
        self:setOverrideHandModels(self.cleaningItem, nil)
        self.sound = self.character:playSound("CleanBloodScrub")
    end
end

function CleanWasteProduct:stop()
    self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
end

function CleanWasteProduct:perform()
    self.character:stopOrTriggerSound(self.sound)

	-- Remove the puddle from the world
    if self.puddleToRemove and self.square then
        self.square:transmitRemoveItemFromSquare(self.puddleToRemove)
        print("Urine puddle removed successfully.")
    end

	ISBaseTimedAction.perform(self)
end

function CleanWasteProduct:new(character, time, square, puddleToRemove, cleaningItem)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.square = square
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = time
	o.puddleToRemove = puddleToRemove
    o.cleaningItem = cleaningItem
    o.caloriesModifier = 5
	return o
end 
