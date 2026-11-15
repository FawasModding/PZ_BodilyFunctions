-- =====================================================
--
-- BF_ServiceToilet
--
-- Toilet care, one operation per action:
--   flush    uses the toilet's water; see BF_Toilets.flush for failure cases
--   clean    sponge or toilet brush; with cleaning liquid or bleach it takes
--            off all the dirt, without it only a little and never below
--            S.DRY_FLOOR (BF_Toilets.washable); progress kept if interrupted
--   unclog   plunger; progress kept if interrupted, flushed automatically after
--   fill     pours water from a container into a tank that isn't on the mains
--   empty    scoops a chemical toilet's tank into an empty bucket
--   refill   adds a dose of bleach (1 L) to a chemical toilet
--
-- In shared so the server runs it in multiplayer. B42 rebuilds the action on
-- the server from new()'s parameter names, so each parameter is kept under the
-- same field name. The server does not run update(), so it applies cleaning and
-- unclogging progress from an emulated anim event instead.
--
-- =====================================================

require "TimedActions/ISBaseTimedAction"
require "BF_Toilets"

BF_ServiceToilet = ISBaseTimedAction:derive("BF_ServiceToilet")
local S, R, W = BF_Toilets, BF_ToiletRules, BF_Sewage

-- One action per toilet at a time, by square.
S.locks = S.locks or {}
local LOCK_MS = 15000

-- True when the character holds a usable cleaner with at least `least` liters.
function BF_ServiceToilet:hasCleaner(least)
	self.tools = self.tools or W.items(self.character)
	local cleaner = self.tools.cleaner
	return cleaner ~= nil and self.character:getInventory():containsRecursive(cleaner)
		and W.isMix(cleaner:getFluidContainer(), W.cleaningAgents(), least)
end

function BF_ServiceToilet:resources()
	self.tools = self.tools or W.items(self.character)
	local inv = self.character:getInventory()
	local function owned(item) return item and inv:containsRecursive(item) end
	local function intact(item) return owned(item) and not item:isBroken() end
	local op = self.operation
	if op == "clean" then
		-- The cleaner is optional. A wash started with it stops if it runs out.
		if not intact(self.tools.brush) then return false end
		return self.dry ~= false or self:hasCleaner(0.0001)
	end
	if op == "unclog" then return intact(self.tools.plunger) end
	if op == "empty" then return owned(self.tools.bucket) and self.tools.bucket:getFluidContainer():isEmpty() end
	if op == "refill" then
		return owned(self.tools.bleach) and W.isMix(self.tools.bleach:getFluidContainer(), { Fluid.Bleach }, 1)
	end
	if op == "fill" then return owned(self.source) and S.tankSource(S.tank(self.target), self.source) ~= nil end
	return op == "flush"
end

function BF_ServiceToilet:isValid()
	if not self.target or not self.target:getSquare() or self.target:getObjectIndex() < 0 then return false end
	if not S.active() or not W.near(self.character, self.target:getSquare()) or not self:resources() then return false end
	if self.lockKey and (not S.locks[self.lockKey] or S.locks[self.lockKey].action ~= self) then return false end
	local op, kind, state = self.operation, S.kind(self.target), S.state(self.target)
	if op == "flush" then return kind == "flush" and S.load(self.target) > 0 and S.hasWater(self.target) end
	if op == "clean" then
		if state.clogged then return false end
		return self._bfStarted or S.washable(state.dirt, self:hasCleaner(W.WASH_START)) > 0
	end
	if op == "unclog" then return kind ~= "wooden" and (self._bfStarted or state.clogged) end
	if op == "empty" then return kind == "chemical" and state.chemicalLoad > 0 end
	if op == "refill" then return kind == "chemical" and R.dose(state) < 1 end
	if op == "fill" then return kind == "flush" and S.tank(self.target) ~= nil end
	return false
end

function BF_ServiceToilet:acquire()
	local key = W.key(self.target:getSquare())
	local lock = S.locks[key]
	if lock and lock.action ~= self and getTimestampMs() - lock.time < LOCK_MS then return false end
	S.locks[key] = { action = self, time = getTimestampMs() }
	self.lockKey = key
	local state = S.ensure(self.target)
	-- Without cleaning liquid or bleach a wash removes less dirt (S.washable).
	self.dry = not self:hasCleaner(W.WASH_START)
	self.washTotal = S.washable(state.dirt, not self.dry)
	self.remainingUnclog = 1 - state.unclogProgress
	self.applied = 0
	return true
end

function BF_ServiceToilet:release()
	local lock = self.lockKey and S.locks[self.lockKey]
	if lock and lock.action == self then S.locks[self.lockKey] = nil end
end

function BF_ServiceToilet:serverStart()
	if not self:isValid() or not self:acquire() then self.netAction:forceComplete(); return end
	self._bfStarted = true
	emulateAnimEvent(self.netAction, 1000, "BFService", nil)
end

function BF_ServiceToilet:waitToStart()
	self.character:faceThisObject(self.target)
	return self.character:shouldBeTurning()
end

function BF_ServiceToilet:start()
	if not isClient() and not self:acquire() then self:forceStop(); return end
	self._bfStarted = true
	self:resources()
	local op = self.operation
	local tool = (op == "unclog" and self.tools.plunger)
		or (op == "clean" and self.tools.brush)
		or (op == "refill" and self.tools.bleach)
		or (op == "empty" and self.tools.bucket)
		or (op == "fill" and self.source)
	local second = nil
	if op == "clean" then
		local brush = tool and tool:getType() == "ToiletBrush"
		self:setActionAnim(brush and "ScrubWall_ToiletBrush" or "ScrubWall")
		if not brush and not self.dry then second = self.tools.cleaner end
		self.sound = self.character:playSound((brush or self.dry) and "CleanBloodScrub" or "CleanBloodBleach")
	elseif op == "unclog" then
		self:setActionAnim("ScrubFloor_Mop")
	elseif op == "flush" then
		self:setActionAnim("Loot")
		self.character:SetVariable("LootPosition", "Mid")
	elseif op == "fill" then
		self:setAnimVariable("PourType", self.source:getPourType())
		self:setActionAnim("fill_container_tap")
		self.sound = self.character:playSound("PourWaterIntoObject")
	elseif op == "refill" then
		self:setActionAnim("Pour")
	else
		self:setActionAnim("Loot")
		self.character:SetVariable("LootPosition", "Low")
	end
	self:setOverrideHandModels(tool, second)
end

-- Applies cleaning or unclogging up to `progress` (0 to 1) of the action.
function BF_ServiceToilet:applyProgress(progress)
	if not self.lockKey or self.finished then return end
	if not S.locks[self.lockKey] or S.locks[self.lockKey].action ~= self then return end
	if self.target:getObjectIndex() < 0 or not W.near(self.character, self.target:getSquare()) then
		self:release()
		return
	end
	local delta = math.max(0, math.min(1, progress) - (self.applied or 0))
	self.applied = math.max(self.applied or 0, progress)
	if delta <= 0 then return end
	local op = self.operation
	if op == "clean" then
		if not self:resources() then return end
		local state = S.ensure(self.target)
		local wanted = self.washTotal * delta
		if self.dry then
			state.dirt = math.max(0, state.dirt - wanted)
		else
			local fluid = self.tools.cleaner:getFluidContainer()
			local removed = math.min(wanted, fluid:getAmount() / S.WASH_MIX)
			state.dirt = math.max(0, state.dirt - removed)
			fluid:removeFluid(removed * S.WASH_MIX, false)
			self.tools.cleaner:syncItemFields()
		end
		S.sync(self.target)
	elseif op == "unclog" then
		R.maintain(S.ensure(self.target), op, delta * self.remainingUnclog)
		S.sync(self.target)
	end
end

function BF_ServiceToilet:animEvent(event, parameter)
	if isServer() and event == "BFService" then
		local lock = self.lockKey and S.locks[self.lockKey]
		if lock and lock.action == self then lock.time = getTimestampMs() end
		self:applyProgress(self.netAction:getProgress())
	end
end

-- Action time between plunger sounds; unclog progress after which the plunger sounds clear.
local PLUNGE_TICKS = 40
local PLUNGE_CLEAR = 0.7
-- Action time at which the flush sound plays.
local FLUSH_PRESS_TICKS = 24

function BF_ServiceToilet:flushSound()
	if self.flushed then return end
	self.flushed = true
	self.character:getEmitter():playSound("BF_Toilet_Flush")
end

function BF_ServiceToilet:plungeSound()
	local stroke = math.floor((self:getJobDelta() * self.maxTime - PLUNGE_TICKS / 2) / PLUNGE_TICKS)
	if stroke < 0 or stroke == self.plunged then return end
	self.plunged = stroke
	local clear = S.state(self.target).unclogProgress >= PLUNGE_CLEAR
	self.character:getEmitter():playSound(clear and "BFP_PlungerClear" or "BFP_PlungerClogged")
end

function BF_ServiceToilet:update()
	self.character:faceThisObject(self.target)
	if self.operation == "unclog" and not isServer() then self:plungeSound() end
	if self.operation == "flush" and not isServer() and self:getJobDelta() * self.maxTime >= FLUSH_PRESS_TICKS then
		self:flushSound()
	end
	self.character:setMetabolicTarget(Metabolics.LightWork)
	if not isClient() then
		local lock = self.lockKey and S.locks[self.lockKey]
		if lock and lock.action == self then lock.time = getTimestampMs() end
		self:applyProgress(self:getJobDelta())
	end
end

function BF_ServiceToilet:stopSound()
	if self.sound then
		self.character:stopOrTriggerSound(self.sound)
		self.sound = nil
	end
end

function BF_ServiceToilet:stop()
	self:stopSound()
	if not isClient() then
		self:applyProgress(self:getJobDelta())
		self:release()
	end
	ISBaseTimedAction.stop(self)
end

function BF_ServiceToilet:serverStop()
	self:applyProgress(self.netAction:getProgress())
	self:release()
end

function BF_ServiceToilet:complete()
	if self.finished then return true end
	if not self.lockKey then return false end
	self:applyProgress(1)
	local op = self.operation
	if op ~= "clean" and op ~= "unclog" and not self:isValid() then
		self:release()
		return false
	end
	if op == "flush" then
		-- The spill sound is only played in singleplayer; a server can't play it on the client from here.
		if S.flush(self.target) == "spilled" and not isServer() then
			self.character:playSound("BFP_SewageSpill")
		end
	elseif op == "empty" then
		local state = S.ensure(self.target)
		local bucket = self.tools.bucket:getFluidContainer()
		local urine, feces = R.scoop(state, bucket:getCapacity())
		if urine > 0 then bucket:addFluid(W.fluid("HumanUrine"), urine) end
		if feces > 0 then bucket:addFluid(W.fluid("HumanFeces"), feces) end
		self.tools.bucket:syncItemFields()
		if state.chemicalLoad <= 0 then state.load, state.visits = 0, 0 end
		S.sync(self.target)
	elseif op == "refill" then
		self.tools.bleach:getFluidContainer():removeFluid(1, false)
		self.tools.bleach:syncItemFields()
		S.ensure(self.target).chemicalDose = 1
		S.sync(self.target)
	elseif op == "fill" then
		local tank = S.tank(self.target)
		local from = S.tankSource(tank, self.source)
		local amount = math.min(from:getAmount(), tank:getCapacity() - tank:getAmount())
		local fluid = from:getPrimaryFluid()
		from:removeFluid(amount, false)
		tank:addFluid(fluid, amount)
		self.source:syncItemFields()
		self.target:sync()
	end
	self.finished = true
	self:release()
	return true
end

function BF_ServiceToilet:perform()
	self:stopSound()
	if self.operation == "flush" and not isServer() then self:flushSound() end
	-- After unclogging, a toilet with contents is flushed automatically if there is water.
	if self.operation == "unclog" and S.kind(self.target) == "flush" and S.load(self.target) > 0 and S.hasWater(self.target) then
		self:beginAddingActions()
		ISTimedActionQueue.add(BF_ServiceToilet:new(self.character, self.target, "flush"))
		self:endAddingActions()
	end
	ISBaseTimedAction.perform(self)
end

function BF_ServiceToilet:getDuration()
	if self.character:isTimedActionInstant() then return 1 end
	local op = self.operation
	if op == "clean" then
		local dirt = S.washable(S.state(self.target).dirt, self:hasCleaner(W.WASH_START))
		return math.max(60, dirt * 4)
	end
	if op == "unclog" then return math.max(60, 1200 * (1 - S.state(self.target).unclogProgress)) end
	if op == "empty" then return 300 end
	if op == "refill" then return 150 end
	if op == "flush" then return 72 end
	if op == "fill" then
		local tank = S.tank(self.target)
		local from = S.tankSource(tank, self.source)
		if not from or not tank then return 40 end
		return math.max(6, math.min(from:getAmount(), tank:getCapacity() - tank:getAmount())) * 7
	end
	return 40
end

function BF_ServiceToilet:new(character, target, operation, source)
	local o = ISBaseTimedAction.new(self, character)
	o.target, o.operation, o.source = target, operation, source
	o.maxTime = o:getDuration()
	o.ignoreDynamicTime = true
	o.stopOnWalk, o.stopOnRun, o.stopOnAim = true, true, true
	return o
end

return BF_ServiceToilet