---@class ToiletDefecate : ISBaseTimedAction
---@field character IsoPlayer
ToiletDefecate = ISBaseTimedAction:derive("ToiletDefecate")

-- True when the character is on/next to the toilet, OR already seated on it.
local function canUseToilet(character, toiletObject)
	if not toiletObject then return false end
	if character:isSittingOnFurniture() then
		return true
	end
	local objSq = toiletObject:getSquare()
	local charSq = character and character:getCurrentSquare()
	if not objSq or not charSq then return false end
	if objSq:getZ() ~= charSq:getZ() then return false end
	local dx = math.abs(objSq:getX() - charSq:getX())
	local dy = math.abs(objSq:getY() - charSq:getY())
	return dx <= 1 and dy <= 1
end

function ToiletDefecate:isValid()
	return canUseToilet(self.character, self.toiletObject)
end

function ToiletDefecate:update()
	-- Reduce bowel + bladder proportionally to elapsed time.
	local delta = self:getJobDelta()

	local newDefecate = self.initialDefecateValue - (delta * self.initialDefecateValue)
	self.character:getModData().defecateValue = math.max(newDefecate, 0)

	local newUrinate = self.initialUrinateValue - (delta * self.initialUrinateValue)
	self.character:getModData().urinateValue = math.max(newUrinate, 0)

	-- When seated (vanilla pose), don't steer facing.
	if not self.character:isSittingOnFurniture() then
		self.character:setDir(self.toiletObject:getFacing())
	end
end

function ToiletDefecate:start()
	self.initialDefecateValue = self.character:getModData().defecateValue or 0
	self.initialUrinateValue = self.character:getModData().urinateValue or 0
	self.removedClothing = {}

	-- Seated (vanilla pose) needs no mod animation, like reading while seated.
	-- Standing fallback keeps the mod's sit animation.
	if not self.character:isSittingOnFurniture() then
		self:setActionAnim("bathroomSitToilet")
	end

	self.sound = self.character:getEmitter():playSound("BF_Poop_Self_Light")
end

function ToiletDefecate:stop()
	ISBaseTimedAction.stop(self)

	BF.ReequipBottomClothing(self.character)
	BF.ResetRemovedClothing(self.character)

	self:stopSound()
end

function ToiletDefecate:perform()
	self.character:getModData().defecateValue = 0.0 -- reset bowel
	self.character:getModData().urinateValue = 0.0  -- reset bladder
	ISBaseTimedAction.perform(self)

	BF.ReequipBottomClothing(self.character)

	self:stopSound()
end

function ToiletDefecate:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function ToiletDefecate:new(character, time, stopWalk, stopRun, toiletObject, seated)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	o.toiletObject = toiletObject
	o.seated = seated
	return o
end
