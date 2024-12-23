GroundDefecate = ISBaseTimedAction:derive("GroundDefecate")
function GroundDefecate:isValid()
	return true
end

function GroundDefecate:update()

end

function GroundDefecate:start()
	-- Remove clothing items before starting the defecation
    self.removedClothing = {}

	self:setActionAnim("bathroomSquat")
end

function GroundDefecate:stop()
	ISBaseTimedAction.stop(self)
end

function GroundDefecate:perform()
	local defecateValue = BathroomFunctions.GetDefecateValue()

	self.character:getModData().defecateValue = 0.0 --RESET DEFECATE VALUE
	ISBaseTimedAction.perform(self)
end

function GroundDefecate:new(character, time, stopWalk, stopRun)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	return o
end