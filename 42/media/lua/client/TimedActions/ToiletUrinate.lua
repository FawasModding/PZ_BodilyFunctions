ToiletUrinate = ISBaseTimedAction:derive("ToiletUrinate")
function ToiletUrinate:isValid()
	return true
end

function ToiletUrinate:update()
	-- Reduce urination value proportionally to the elapsed time
    local delta = self:getJobDelta() -- Get the progress of the action (0.0 to 1.0)
    local initialValue = self.character:getModData().urinateValue
    local newValue = self.initialUrinateValue - (delta * self.initialUrinateValue)
    self.character:getModData().urinateValue = math.max(newValue, 0) -- Ensure it doesn't go below 0

	local props = self.toiletObject:getProperties()

	-- Set facing direction based on "Facing" property
	if (props:Val("Facing") == "N") then
		self.character:setDir(IsoDirections.N)
	elseif (props:Val("Facing") == "E") then
		self.character:setDir(IsoDirections.E)
	elseif (props:Val("Facing") == "S") then
		self.character:setDir(IsoDirections.S)
	elseif (props:Val("Facing") == "W") then
		self.character:setDir(IsoDirections.W)
	end

	-- If the character is male, face the opposite direction
	if not self.isFemale then
		-- Flip the direction to the opposite
		local currentDir = self.character:getDir()

		if currentDir == IsoDirections.N then
			self.character:setDir(IsoDirections.S)
		elseif currentDir == IsoDirections.E then
			self.character:setDir(IsoDirections.W)
		elseif currentDir == IsoDirections.S then
			self.character:setDir(IsoDirections.N)
		elseif currentDir == IsoDirections.W then
			self.character:setDir(IsoDirections.E)
		end
	end

end

function ToiletUrinate:start()
	-- Save the initial urination value at the start of the action
    self.initialUrinateValue = self.character:getModData().urinateValue or 0

	--Character pees in toilet, has animation for male/female
	if self.character:isFemale() then --If female, sit
		self:setActionAnim("bathroomSitToilet")
	else --If male, stand
		self:setActionAnim("bathroomStandToilet")
	end

end

function ToiletUrinate:stop()
	ISBaseTimedAction.stop(self)

	-- If ending early, don't keep the items stored
	BathroomFunctions.ResetRemovedClothing(self.character)
end

function ToiletUrinate:perform()
	local urinateValue = BathroomFunctions.GetUrinateValue()

	self.character:getModData().urinateValue = 0.0 --RESET URINE VALUE
	ISBaseTimedAction.perform(self)

	-- Put back on bottom clothing afterwards
    if self.character:isFemale() == true then
        BathroomFunctions.ReequipBottomClothing(self.character)
    end
end

function ToiletUrinate:new(character, time, stopWalk, stopRun, toiletObject)
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