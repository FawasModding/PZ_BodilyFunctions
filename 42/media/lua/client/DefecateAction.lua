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
	if self.usingToilet then
		self:setActionAnim("bathroomSitToilet")
	elseif not self.peedSelf then
		self:setActionAnim("bathroomSquat")
	end
end

function DefecateAction:stop()
	ISBaseTimedAction.stop(self)
end

function DefecateAction:perform()
	local defecateValue = BathroomFunctions.GetUrinateValue()

	if self.poopedSelf then --Pooping on self
		BathroomFunctions.DefecateBottoms()
	end

	if self.usingToilet then --Pooping in toilet
		getSoundManager():PlayWorldSound("ToiletFlush", self.character:getCurrentSquare(), 0, 10, 0, false)
	end
	
	if not self.poopedSelf and not self.usingToilet then --Pooping on ground
		self.character:getStats():setFatigue(self.character:getStats():getFatigue() + 0.025)

		--Manage poop puddles, poops should be different dependant on defecate value, diarrhea, and corn
		if SandboxVars.BathroomFunctions.CreatePoopObject == true then
			local fecesItem = InventoryItemFactory.CreateItem("BathroomFunctions.HumanFeces")
			self.character:getCurrentSquare():AddWorldInventoryItem(fecesItem, 0, 0, 0)
		end
	end

	--self.character:getModData().needsWipe = true
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