GroundUrinate = ISBaseTimedAction:derive("GroundUrinate")
function GroundUrinate:isValid()
	return true
end

function GroundUrinate:update()
	-- Reduce urination value proportionally to the elapsed time
    local delta = self:getJobDelta() -- Get the progress of the action (0.0 to 1.0)
    local initialValue = self.character:getModData().urinateValue
    local newValue = self.initialUrinateValue - (delta * self.initialUrinateValue)
    self.character:getModData().urinateValue = math.max(newValue, 0) -- Ensure it doesn't go below 0
end

function GroundUrinate:start()
	-- Save the initial urination value at the start of the action
    self.initialUrinateValue = self.character:getModData().urinateValue or 0

	if self.character:isFemale() then --If female, squat
		self:setActionAnim("bathroomSquat")
	else --If male, stand
		self:setActionAnim("bathroomStandPee")
	end

end

function GroundUrinate:stop()
	ISBaseTimedAction.stop(self)

	-- If ending early, don't keep the items stored
	BF.ResetRemovedClothing(self.character)
end

function GroundUrinate:perform()
	local urinateValue = BF.GetUrinateValue()

	if self.character:isFemale() then --Minor detail, but squatting should give more fatigue than standing
		self.character:getStats():setFatigue(self.character:getStats():getFatigue() + 0.025)
	end

	getSoundManager():PlayWorldSound("PeeSelf", self.character:getCurrentSquare(), 0, 10, 0, false)
	--self.character:playSound("PeeSelf")

	if SandboxVars.BF.CreatePeeObject == true then
		local urineItem = instanceItem("BF.Urine_Hydrated_0")
		self.character:getCurrentSquare():AddWorldInventoryItem(urineItem, 0, 0, 0)
	end

	self.character:getModData().urinateValue = 0.0 --RESET URINE VALUE
	ISBaseTimedAction.perform(self)

	-- Put back on bottom clothing afterwards
    if self.character:isFemale() == true then
        BF.ReequipBottomClothing(self.character)
    end
end

function GroundUrinate:new(character, time, stopWalk, stopRun)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	return o
end