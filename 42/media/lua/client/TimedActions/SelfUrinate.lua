SelfUrinate = ISBaseTimedAction:derive("SelfUrinate")
function SelfUrinate:isValid()
	return true
end

function SelfUrinate:update()
	-- Reduce urination value proportionally to the elapsed time
    local delta = self:getJobDelta() -- Get the progress of the action (0.0 to 1.0)
    local initialValue = self.character:getModData().urinateValue
    local newValue = self.initialUrinateValue - (delta * self.initialUrinateValue)
    self.character:getModData().urinateValue = math.max(newValue, 0) -- Ensure it doesn't go below 0
end

function SelfUrinate:start()
	-- Save the initial urination value at the start of the action
    self.initialUrinateValue = self.character:getModData().urinateValue or 0
end

function SelfUrinate:stop()
	ISBaseTimedAction.stop(self)
end

function SelfUrinate:perform()
	local urinateValue = BathroomFunctions.GetUrinateValue()

	-- Ensure urinateValue is fully reset at the end of the action
	self.character:getModData().urinateValue = 0.0
	ISBaseTimedAction.perform(self)
end

function SelfUrinate:new(character, time, stopWalk, stopRun, peedSelf, usingToilet, toiletObject)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	o.peedSelf = peedSelf
	o.usingToilet = usingToilet
	o.toiletObject = toiletObject
	return o
end