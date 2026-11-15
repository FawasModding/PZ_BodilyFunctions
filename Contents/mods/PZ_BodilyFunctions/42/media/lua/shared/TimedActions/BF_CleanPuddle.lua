-- =====================================================
--
-- BF_CleanPuddle
--
-- Cleans a puddle with a sponge or toilet brush and cleaner ("clean"), or covers
-- one on soil with a shovel ("bury").
--
-- In shared so the server runs complete() in multiplayer. B42 rebuilds the
-- action on the server from new()'s parameter names, so each parameter is kept
-- under the same field name.
--
-- =====================================================

require "TimedActions/ISBaseTimedAction"
require "BF_Sewage"
require "Util/BuildingHelper"

BF_CleanPuddle = ISBaseTimedAction:derive("BF_CleanPuddle")
local W = BF_Sewage

function BF_CleanPuddle:resources()
	self.tools = self.tools or W.items(self.character)
	local inv = self.character:getInventory()
	local function owned(item) return item and inv:containsRecursive(item) end
	local function intact(item) return owned(item) and not item:isBroken() end
	if self.operation == "clean" then
		return intact(self.tools.brush) and owned(self.tools.cleaner)
			and W.isMix(self.tools.cleaner:getFluidContainer(), W.cleaningAgents(),
				self._bfStarted and 0.0001 or W.WASH_START)
	end
	if self.operation == "bury" then return intact(self.tools.shovel) end
	return false
end

function BF_CleanPuddle:isValid()
	local square = self.target and self.target:getSquare()
	if not square or self.target:getObjectIndex() < 0 or not W.isPuddle(self.target) then return false end
	if not W.near(self.character, square) or not self:resources() then return false end
	if self.operation == "bury" then return W.onSoil(square) end
	return true
end

function BF_CleanPuddle:waitToStart()
	self.character:faceThisObject(self.target)
	return self.character:shouldBeTurning()
end

function BF_CleanPuddle:start()
	self._bfStarted = true
	self:resources()
	local second = nil
	if self.operation == "bury" then
		self:setActionAnim(BuildingHelper.getShovelAnim(self.tools.shovel))
		self.sound = self.character:playSound("Shoveling")
		self:setOverrideHandModels(self.tools.shovel, nil)
	else
		local brush = self.tools.brush and self.tools.brush:getType() == "ToiletBrush"
		self:setActionAnim(brush and "ScrubFloor_ToiletBrush" or "ScrubFloor")
		if not brush then second = self.tools.cleaner end
		self.sound = self.character:playSound(brush and "CleanBloodScrub" or "CleanBloodBleach")
		self:setOverrideHandModels(self.tools.brush, second)
	end
end

function BF_CleanPuddle:update()
	self.character:faceThisObject(self.target)
	self.character:setMetabolicTarget(Metabolics.LightWork)
end

function BF_CleanPuddle:stopSound()
	if self.sound then
		self.character:stopOrTriggerSound(self.sound)
		self.sound = nil
	end
end

function BF_CleanPuddle:stop()
	self:stopSound()
	ISBaseTimedAction.stop(self)
end

function BF_CleanPuddle:complete()
	if not self:isValid() then return false end
	if self.operation == "bury" then
		BF_Sewage.setVolume(self.target, 0)
	else
		-- Cleaner is used by volume; with too little, only part of the puddle is cleaned.
		local fc = self.tools.cleaner:getFluidContainer()
		local liters = BF_Sewage.volume(self.target)
		local used = math.min(liters * W.SPILL_MIX, fc:getAmount())
		fc:removeFluid(used, false)
		self.tools.cleaner:syncItemFields()
		BF_Sewage.setVolume(self.target, liters - used / W.SPILL_MIX)
	end
	return true
end

function BF_CleanPuddle:perform()
	self:stopSound()
	ISBaseTimedAction.perform(self)
end

function BF_CleanPuddle:getDuration()
	if self.character:isTimedActionInstant() then return 1 end
	if self.operation == "bury" then return 200 end
	return math.max(60, 60 * BF_Sewage.volume(self.target))
end

function BF_CleanPuddle:new(character, target, operation)
	local o = ISBaseTimedAction.new(self, character)
	o.target, o.operation = target, operation
	o.maxTime = o:getDuration()
	o.ignoreDynamicTime = true
	o.stopOnWalk, o.stopOnRun, o.stopOnAim = true, true, true
	return o
end

return BF_CleanPuddle