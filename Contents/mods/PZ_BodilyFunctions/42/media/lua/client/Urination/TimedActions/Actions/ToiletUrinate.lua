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

    local facing = self.toiletObject:getFacing()

    -- Males face opposite direction, females face toilet direction
    if not self.character:isFemale() then
        facing = IsoDirections.reverse(facing)
    end

    self.character:setDir(facing)
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

    -- Play toilet pee loop
    self.sound = self.character:getEmitter():playSound("BF_Pee_Toilet_Light")

end

function ToiletUrinate:stop()
	ISBaseTimedAction.stop(self)

	-- If ending early, don't keep the items stored
	BF.ResetRemovedClothing(self.character)

    self:stopSound() -- Stop peeing sound
end

function ToiletUrinate:perform()
	local urinateValue = BF.GetUrinateValue()

	self.character:getModData().urinateValue = 0.0 --RESET URINE VALUE
	ISBaseTimedAction.perform(self)

	-- Put back on bottom clothing afterwards
    if self.character:isFemale() == true then
        BF.ReequipBottomClothing(self.character)
    end

    self:stopSound() -- Stop peeing sound
end

function ToiletUrinate:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound);
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