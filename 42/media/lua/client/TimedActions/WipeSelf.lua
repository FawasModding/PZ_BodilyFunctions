WipeSelf = ISBaseTimedAction:derive("WipeSelf")
function WipeSelf:isValid()
	return true
end

function WipeSelf:update()

end

function WipeSelf:start()

end

function WipeSelf:stop()
	ISBaseTimedAction.stop(self)
end

function WipeSelf:perform()
	ISBaseTimedAction.perform(self)

	
end

function WipeSelf:new(character, time, stopWalk, stopRun)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	return o
end