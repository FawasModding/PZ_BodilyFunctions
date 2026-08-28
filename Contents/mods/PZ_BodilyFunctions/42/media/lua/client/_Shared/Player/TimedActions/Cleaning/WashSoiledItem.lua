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

    if self.soiledItem then
        local itemType = self.soiledItem:getType()
        -- Remove pooped item
        self.character:getInventory():RemoveOneOf(itemType)
        -- Strip "Pooped" to get the clean item type.
        local cleanItemType = string.gsub(itemType, "Pooped", "")
        -- The clean version of a rag is the VANILLA Base.RippedSheets, not a BF item.
        -- Map known junk back to their real clean counterparts.
        local cleanFullType
        if cleanItemType == "RippedSheets" then
            cleanFullType = "Base.RippedSheets"
        else
            cleanFullType = "BF." .. cleanItemType
        end
        self.character:getInventory():AddItem(cleanFullType)
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
