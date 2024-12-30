WashSoiled = ISBaseTimedAction:derive("WashSoiled")
function WashSoiled:isValid()
	return true
end

function WashSoiled:update()
end

function WashSoiled:start()
	self:setActionAnim("Loot")
	self:setAnimVariable("LootPosition", "")
	self:setOverrideHandModels(nil, nil)
	self.sound = self.character:playSound("WashYourself")
	self.character:reportEvent("EventWashClothing")
end

function WashSoiled:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function WashSoiled:stop()
	self:stopSound()
    ISBaseTimedAction.stop(self)
end

function WashSoiled:perform()
	self:stopSound()

	self.soiledItem:setName(self.soiledItem:getModData().originalName)
	self.soiledItem:getModData().originalName = nil

	self.soiledItem:setWetness(100)
	self.soiledItem:setDirtyness(0)

	if self.soiledItem:getModData().peed == true then --Do stuff if clothing peed
		self.soiledItem:getModData().peed = false
		self.soiledItem:getModData().peedSeverity = 0;
	end

	if self.soiledItem:getModData().pooped == true then --Do stuff if clothing pooped
		--Remove poop stain
		local coveredParts = BloodClothingType.getCoveredParts(self.soiledItem:getBloodClothingType())
		if coveredParts then
			for j = 0, coveredParts:size() - 1 do
				self.soiledItem:setBlood(coveredParts:get(j), 0)
				self.soiledItem:setDirt(coveredParts:get(j), 0)
			end
		end

		self.soiledItem:setRunSpeedModifier(self.soiledItem:getRunSpeedModifier() + 0.2)

		if self.soapItem:getCurrentUses() > 0 then
            self.soapItem:UseAndSync()
        end

		self.soiledItem:getModData().pooped = false
		self.soiledItem:getModData().poopedSeverity = 0;
	end

	self.character:resetModelNextFrame()
	triggerEvent("OnClothingUpdated", self.character)

	--ISTakeWaterAction.SendTakeWaterCommand(self.character, self.storeWater, 15)

	ISBaseTimedAction.perform(self)
end

function WashSoiled:new(character, time, square, soiledItem, soapItem, storeWater)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.square = square
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = time
	o.soapItem = soapItem
	o.soiledItem = soiledItem
	o.storeWater = storeWater
	return o
end 
