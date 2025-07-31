Idle_PoopUrgency = ISBaseTimedAction:derive("Idle_PoopUrgency")
function Idle_PoopUrgency:isValid()
	return true
end

function Idle_PoopUrgency:update()

end

function Idle_PoopUrgency:start()

	UIManager.getSpeedControls():SetCurrentGameSpeed(1)
	self:setActionAnim("idleUrgencyPoop")

end

function Idle_PoopUrgency:stop()
	ISBaseTimedAction.stop(self)
end

function Idle_PoopUrgency:perform()
	ISBaseTimedAction.perform(self)
end

function Idle_PoopUrgency:new(character, time, stopWalk, stopRun)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	return o
end