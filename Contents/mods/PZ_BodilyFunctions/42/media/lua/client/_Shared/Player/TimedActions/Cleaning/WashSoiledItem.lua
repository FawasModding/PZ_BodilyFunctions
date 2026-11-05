---@class WashSoiledItem : ISBaseTimedAction
---@field character IsoPlayer
---@field soiledItem InventoryItem
---@field soapItem InventoryItem
WashSoiledItem = ISBaseTimedAction:derive("WashSoiledItem")
function WashSoiledItem:isValid()
	return true
end

function WashSoiledItem:update()
end

function WashSoiledItem:start()
	self:setActionAnim("Loot")
	self:setAnimVariable("LootPosition", "")
	self:setOverrideHandModels(nil, nil)
	self.sound = self.character:playSound("WashYourself")
	self.character:reportEvent("EventWashClothing")
end

function WashSoiledItem:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function WashSoiledItem:stop()
	self:stopSound()
    ISBaseTimedAction.stop(self)
end

function WashSoiledItem:perform()
	self:stopSound()

    -- The server swaps the item for its clean version: an item a client makes on
    -- its own can't be moved afterwards. These don't use a cleaning agent.
    if self.soiledItem and self.storeWater then
        BF.SendTrackedCommand(self.character, "wash", BF.BuildWashArgs(self.soiledItem, nil, self.storeWater))
    end

	ISBaseTimedAction.perform(self)
end

function WashSoiledItem:new(character, time, square, soiledItem, soapItem, storeWater)
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
