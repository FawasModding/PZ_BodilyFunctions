UrinateAction = ISBaseTimedAction:derive("UrinateAction")
function UrinateAction:isValid()
	return true
end

function UrinateAction:update()
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

function UrinateAction:start()
	--Checks if character peed on ground or in toilet, has animation for male/female
	if self.usingToilet then
		if self.character:isFemale() then --If female, sit
			self:setActionAnim("bathroomSitToilet")
		else --If male, stand
			self:setActionAnim("bathroomStandToilet")
		end
	else
		if self.character:isFemale() then --If female, squat
			self:setActionAnim("bathroomSquat")
		else --If male, stand
			self:setActionAnim("bathroomStandPee")
		end
	end
end

function UrinateAction:stop()
	ISBaseTimedAction.stop(self)
end

function UrinateAction:perform()
	local urinateValue = BathroomFunctions.GetUrinateValue()


	self.character:getModData().urinateValue = 0.0 --RESET URINE VALUE
	ISBaseTimedAction.perform(self)
end

function UrinateAction:new(character, time, stopWalk, stopRun, peedSelf, usingToilet, toiletObject)
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