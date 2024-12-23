SelfDefecate = ISBaseTimedAction:derive("SelfDefecate")
function SelfDefecate:isValid()
	return true
end

function SelfDefecate:update()
	-- Reduce urination value proportionally to the elapsed time
    local delta = self:getJobDelta() -- Get the progress of the action (0.0 to 1.0)
    local initialValue = self.character:getModData().defecateValue
    local newValue = self.initialDefecateValue - (delta * self.initialDefecateValue)
    self.character:getModData().defecateValue = math.max(newValue, 0) -- Ensure it doesn't go below 0
end

function SelfDefecate:start()
	-- Save the initial defecate value at the start of the action
    self.initialDefecateValue = self.character:getModData().defecateValue or 0
end

function SelfDefecate:stop()
	ISBaseTimedAction.stop(self)
end

function SelfDefecate:perform()
	local defecateValue = BathroomFunctions.GetDefecateValue()

	self.character:getModData().defecateValue = 0.0 --RESET DEFECATE VALUE
	ISBaseTimedAction.perform(self)
end

function SelfDefecate:new(character, time, stopWalk, stopRun, poopedSelf, usingToilet, toiletObject)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	o.poopedSelf = poopedSelf
	o.usingToilet = usingToilet
	o.toiletObject = toiletObject
	return o
end