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

	local item = self.soiledItem
	if not item then
		ISBaseTimedAction.perform(self)
		return
	end

	local modData = item:getModData()
	local usedCleaner = BF.ConsumeCleaningAgent(self.cleaningItem)

	if modData.peed == true then
		modData.peedSeverity = BF.ReduceSoilSeverity(modData.peedSeverity, usedCleaner)
		modData.peed = modData.peedSeverity > 0
	end

	if modData.pooped == true then
		modData.poopedSeverity = BF.ReduceSoilSeverity(modData.poopedSeverity, usedCleaner)
		modData.pooped = modData.poopedSeverity > 0
	end

	local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
	if coveredParts then
		for j = 0, coveredParts:size() - 1 do
			item:setBlood(coveredParts:get(j), 0)
			item:setDirt(coveredParts:get(j), 0)
		end
	end
	item:setBloodLevel(0)

	if item:IsClothing() then
		item:setWetness(100)
		item:setDirtiness(0)
	end

	if modData.pooped ~= true and modData.peed ~= true and modData.originalName then
		item:setName(modData.originalName)
		modData.originalName = nil
	end

	if isClient() then
		syncItemFields(self.character, item)
	end

	if BF_Overlays then
		BF_Overlays.RefreshOverlaysForPlayer(self.character, "peed")
		BF_Overlays.RefreshOverlaysForPlayer(self.character, "pooped")
	end

	self.character:resetModelNextFrame()
	triggerEvent("OnClothingUpdated", self.character)

	-- If the garment was being worn before washing, put it back on using the
	-- game's own wear action (queued after this one). Doing it manually mid-action
	-- desyncs the model and the inventory UI, so we let ISWearClothing handle it.
	if self.wasEquipped and item:IsClothing() and not item:isEquipped() then
		ISTimedActionQueue.add(ISWearClothing:new(self.character, item))
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
