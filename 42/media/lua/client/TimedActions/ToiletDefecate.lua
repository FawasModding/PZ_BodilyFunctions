ToiletDefecate = ISBaseTimedAction:derive("ToiletDefecate")
function ToiletDefecate:isValid()
	return true
end

function ToiletDefecate:update()
	-- Reduce defecation value proportionally to the elapsed time
    local delta = self:getJobDelta() -- Get the progress of the action (0.0 to 1.0)
    local initialValue = self.character:getModData().defecateValue
    local newValue = self.initialDefecateValue - (delta * self.initialDefecateValue)
    self.character:getModData().defecateValue = math.max(newValue, 0) -- Ensure it doesn't go below 0

	-- Reduce urination value proportionally to the elapsed time
    local delta = self:getJobDelta() -- Get the progress of the action (0.0 to 1.0)
    local initialValue = self.character:getModData().urinateValue
    local newValue = self.initialUrinateValue - (delta * self.initialUrinateValue)
    self.character:getModData().urinateValue = math.max(newValue, 0) -- Ensure it doesn't go below 0

	local props = self.toiletObject:getProperties()

	if (props:Val("Facing") == "N") then
		self.character:setDir(IsoDirections.N)
	elseif (props:Val("Facing") == "E") then
		self.character:setDir(IsoDirections.E)
	elseif (props:Val("Facing") == "S") then
		self.character:setDir(IsoDirections.S)
	elseif (props:Val("Facing") == "W") then
		self.character:setDir(IsoDirections.W)
	end
end

function ToiletDefecate:start()
	-- Save the initial defecation value at the start of the action
    self.initialDefecateValue = self.character:getModData().defecateValue or 0

	-- Save the initial urination value at the start of the action
    self.initialUrinateValue = self.character:getModData().urinateValue or 0

	-- Remove clothing items before starting the defecation
    self.removedClothing = {}

	--Character poops in toilet
	self:setActionAnim("bathroomSitToilet")

	-- Play poop toilet sound
    self.sound = self.character:getEmitter():playSound("BF_Poop_Self_Light")

end

function ToiletDefecate:stop()
	ISBaseTimedAction.stop(self)

	-- If ending early, don't keep the items stored
	BF.ResetRemovedClothing(self.character)

	self:stopSound() -- Stop pooping sound
end

function ToiletDefecate:perform()
	local defecateValue = BF.GetDefecateValue()

	self.character:getModData().defecateValue = 0.0 --RESET DEFECATE VALUE
	self.character:getModData().urinateValue = 0.0 --RESET URINE VALUE
	ISBaseTimedAction.perform(self)

	-- Put back on bottom clothing afterwards
    BF.ReequipBottomClothing(self.character)
end

function ToiletDefecate:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound);
	end
end

function ToiletDefecate:new(character, time, stopWalk, stopRun, toiletObject)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	o.toiletObject = toiletObject
	return o
end