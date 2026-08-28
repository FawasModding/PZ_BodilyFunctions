---@class ToiletUrinate : ISBaseTimedAction
---@field character IsoPlayer
---@field toiletObject IsoObject
ToiletUrinate = ISBaseTimedAction:derive("ToiletUrinate")

-- True when the character is on/next to the toilet, OR already seated on it.
local function canUseToilet(character, toiletObject)
	if not toiletObject then return false end
	-- If we're sitting on this furniture (vanilla seated state), we're good.
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

function ToiletUrinate:isValid()
	return canUseToilet(self.character, self.toiletObject)
end

function ToiletUrinate:update()
	-- Reduce bladder proportionally to elapsed time.
	local delta = self:getJobDelta()
	local newValue = self.initialUrinateValue - (delta * self.initialUrinateValue)
	self.character:getModData().urinateValue = math.max(newValue, 0)

	-- When seated (vanilla pose), the seated state owns facing. When standing
	-- (male / adjacent fallback), face TOWARD the toilet based on where it is
	-- relative to the character (getFacing() points the way the toilet faces,
	-- i.e. away from the user, so we compute the direction ourselves).
	if not self.character:isSittingOnFurniture() and self.toiletObject then
		local objSq = self.toiletObject:getSquare()
		local charSq = self.character:getCurrentSquare()
		if objSq and charSq then
			local dx = objSq:getX() - charSq:getX()
			local dy = objSq:getY() - charSq:getY()
			if math.abs(dx) >= math.abs(dy) then
				self.character:setDir(dx >= 0 and IsoDirections.E or IsoDirections.W)
			else
				self.character:setDir(dy >= 0 and IsoDirections.S or IsoDirections.N)
			end
		end
	end
end

function ToiletUrinate:start()
	self.initialUrinateValue = self.character:getModData().urinateValue or 0

	-- If the character is seated on the toilet (vanilla Rest pose), don't apply
	-- the mod's sitting animation — the engine already holds the correct pose,
	-- exactly like reading while seated. Standing characters get the stand anim.
	if not self.character:isSittingOnFurniture() then
		self:setActionAnim("bathroomStandToilet")
	end

	self.sound = self.character:getEmitter():playSound("BF_Pee_Toilet_Light")
end

function ToiletUrinate:stop()
	ISBaseTimedAction.stop(self)

	-- Ending early: re-dress so the character isn't left undressed.
	BF.ReequipBottomClothing(self.character)
	BF.ResetRemovedClothing(self.character)

	self:stopSound()
end

function ToiletUrinate:perform()
	self.character:getModData().urinateValue = 0.0 -- reset bladder
	ISBaseTimedAction.perform(self)

	if self.character:isFemale() == true then
		BF.ReequipBottomClothing(self.character)
	end

	self:stopSound()
end

function ToiletUrinate:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function ToiletUrinate:new(character, time, stopWalk, stopRun, toiletObject, seated)
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
