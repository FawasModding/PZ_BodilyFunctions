---@class WashSoiled : ISBaseTimedAction
---@field character IsoPlayer
---@field soiledItem Clothing
---@field cleaningItem InventoryItem
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

	-- Debug logging
    --print("WashSoiled: Attempting to restore name")
    --print("soiledItem type: " .. tostring(self.soiledItem))

    if self.soiledItem then
        local modData = self.soiledItem:getModData()
        print("modData: " .. tostring(modData))

        if modData then
            print("originalName: " .. tostring(modData.originalName))

            if modData.originalName then
                self.soiledItem:setName(modData.originalName)
                modData.originalName = nil
            else
                print("WARNING: No original name found in mod data")
            end
        else
            print("WARNING: modData is nil")
        end
    else
        print("WARNING: soiledItem is nil")
    end

	self.soiledItem:setWetness(100)
	self.soiledItem:setDirtiness(0)
	-- Clear dirt per covered body part instead
	--local washCoveredParts = BloodClothingType.getCoveredParts(self.soiledItem:getBloodClothingType())
	--if washCoveredParts then
	--	for j = 0, washCoveredParts:size() - 1 do
	--		self.soiledItem:setDirt(washCoveredParts:get(j), 0)
	--	end
	--end

	if self.soiledItem:getModData().peed == true then --Do stuff if clothing peed
		self.soiledItem:getModData().peed = false
		self.soiledItem:getModData().peedSeverity = 0;
	end

	if self.soiledItem:getModData().pooped == true then
		-- Remove stain visuals
		local coveredParts = BloodClothingType.getCoveredParts(self.soiledItem:getBloodClothingType())
		if coveredParts then
			for j = 0, coveredParts:size() - 1 do
				self.soiledItem:setBlood(coveredParts:get(j), 0)
				self.soiledItem:setDirt(coveredParts:get(j), 0)
			end
		end

		self.soiledItem:setRunSpeedModifier(self.soiledItem:getRunSpeedModifier() + 0.2)

		local severity = self.soiledItem:getModData().poopedSeverity or 0

		if self.cleaningItem and self.cleaningItem:getCurrentUses() > 0 then
			self.cleaningItem:UseAndSync()
			self.soiledItem:getModData().pooped = false
			self.soiledItem:getModData().poopedSeverity = 0
		else
			if severity > 50 then
				self.soiledItem:getModData().poopedSeverity = ZombRand(5, 11) -- 5-10%
			elseif severity <= 10 then
				self.soiledItem:getModData().pooped = false
				self.soiledItem:getModData().poopedSeverity = 0
			end
		end
	end



	self.character:resetModelNextFrame()
	triggerEvent("OnClothingUpdated", self.character)

	--ISTakeWaterAction.SendTakeWaterCommand(self.character, self.storeWater, 15)

	-- If the garment was being worn before washing, put it back on using the
	-- game's own wear action (queued after this one). Doing it manually mid-action
	-- desyncs the model and the inventory UI, so we let ISWearClothing handle it.
	if self.wasEquipped and self.soiledItem and self.soiledItem:IsClothing()
		and not self.soiledItem:isEquipped() then
		ISTimedActionQueue.add(ISWearClothing:new(self.character, self.soiledItem))
	end

	ISBaseTimedAction.perform(self)
end

function WashSoiled:new(character, time, square, soiledItem, cleaningItem, storeWater, wasEquipped)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.square = square
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = time
	o.cleaningItem = cleaningItem
	o.soiledItem = soiledItem
	o.storeWater = storeWater
	o.wasEquipped = wasEquipped
	return o
end 
