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
	elseif not self.peedSelf then
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

	if self.peedSelf then --Peeing on self
		BathroomFunctions.UrinateBottoms()
	end

	if self.usingToilet then --Peeing in toilet
		getSoundManager():PlayWorldSound("PeeToilet", self.character:getCurrentSquare(), 0, 5, 0, false)
		getSoundManager():PlayWorldSound("ToiletFlush", self.character:getCurrentSquare(), 0, 5, 0, false)
	end

	if not self.peedSelf and not self.usingToilet then --Peeing on ground
		if self.character:isFemale() then --Minor detail, but squatting should give more fatigue than standing
			self.character:getStats():setFatigue(self.character:getStats():getFatigue() + 0.025)
		end
	end

	if not self.usingToilet then --Manage pee puddles (new if statement because it happens when peeing self & on ground)
		--Change this to be an if statement, check 3 different variables for thirst level and create hydrated pee accordingly
		if SandboxVars.BathroomFunctions.CreatePeeObject == true then
			local urineItem = InventoryItemFactory.CreateItem("BathroomFunctions.HumanUrine")
			self.character:getCurrentSquare():AddWorldInventoryItem(urineItem, ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
		end

		getSoundManager():PlayWorldSound("PeeSelf", self.character:getCurrentSquare(), 0, 3, 0, false) --Play pee sound
	end

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