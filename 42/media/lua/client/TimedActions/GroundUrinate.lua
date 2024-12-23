GroundUrinate = ISBaseTimedAction:derive("GroundUrinate")
function GroundUrinate:isValid()
	return true
end

function GroundUrinate:update()

end

function GroundUrinate:start()

	if self.character:isFemale() then --If female, squat
		self:setActionAnim("bathroomSquat")
	else --If male, stand
		self:setActionAnim("bathroomStandPee")
	end

end

function GroundUrinate:stop()
	ISBaseTimedAction.stop(self)
end

function GroundUrinate:perform()
	local urinateValue = BathroomFunctions.GetUrinateValue()


	self.character:getModData().urinateValue = 0.0 --RESET URINE VALUE
	ISBaseTimedAction.perform(self)
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