DefecateAction = ISBaseTimedAction:derive("DefecateAction")
function DefecateAction:isValid()
	return true
end

function DefecateAction:update()
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

function DefecateAction:start()
	-- Remove clothing items before starting the defecation
    self.removedClothing = {}

	if self.usingToilet then
		self:setActionAnim("bathroomSitToilet")
	else
		self:setActionAnim("bathroomSquat")
	end
end

function DefecateAction:stop()
	ISBaseTimedAction.stop(self)
end

function DefecateAction:perform()
	local defecateValue = BathroomFunctions.GetDefecateValue()

	self.character:getModData().defecateValue = 0.0 --RESET DEFECATE VALUE
	ISBaseTimedAction.perform(self)
end

function DefecateAction:new(character, time, stopWalk, stopRun, poopedSelf, usingToilet, toiletObject)
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