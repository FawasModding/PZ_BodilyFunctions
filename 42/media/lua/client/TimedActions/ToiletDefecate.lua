ToiletDefecate = ISBaseTimedAction:derive("ToiletDefecate")
function ToiletDefecate:isValid()
	return true
end

function ToiletDefecate:update()
	if self.usingToilet then
		local props = self.toiletObject:getProperties()

		if (props:Val("Facing") == "N") then
			self.character:setDir(IsoDirections.N)
		elseif (props:Val("Facing") == "E") then
			self.character:setDir(IsoDirections.E)
		elseif (props:Val("Facing") == "S") then
			self.character:setDir(IsoDirections.S)
		elseif (props:Val("Facing") == "W") then
			self.character:setDir(IsoDirections.W)
		end
	end
end

function ToiletDefecate:start()
	-- Remove clothing items before starting the defecation
    self.removedClothing = {}

	--Character poops in toilet
	self:setActionAnim("bathroomSitToilet")

end

function ToiletDefecate:stop()
	ISBaseTimedAction.stop(self)
end

function ToiletDefecate:perform()
	local defecateValue = BathroomFunctions.GetDefecateValue()

	self.character:getModData().defecateValue = 0.0 --RESET DEFECATE VALUE
	ISBaseTimedAction.perform(self)
end

function ToiletDefecate:new(character, time, stopWalk, stopRun, toiletObject)
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