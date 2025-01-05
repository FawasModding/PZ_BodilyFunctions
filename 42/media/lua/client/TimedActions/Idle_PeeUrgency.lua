Idle_PeeUrgency = ISBaseTimedAction:derive("Idle_PeeUrgency")
function Idle_PeeUrgency:isValid()
	return true
end

function Idle_PeeUrgency:update()

end

function Idle_PeeUrgency:start()

	self:setActionAnim("idleUrgencyPee")

end

function Idle_PeeUrgency:stop()
	ISBaseTimedAction.stop(self)
end

function Idle_PeeUrgency:perform()
	ISBaseTimedAction.perform(self)
end

function Idle_PeeUrgency:new(character, time, stopWalk, stopRun)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	return o
end