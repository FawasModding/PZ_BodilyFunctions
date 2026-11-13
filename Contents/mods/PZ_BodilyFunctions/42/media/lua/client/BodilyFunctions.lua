BF = BF or {}
BF.didFirstTimer = false

local InventoryUI = require("Starlit/client/ui/InventoryUI")

-- =====================================================
--
-- BATHROOM FUNCTIONALITY AND TIMERS
--
-- =====================================================

--[[
Handle timed updates for bathroom needs
Called every 10 in-game minutes.
]]--
--[[
Runs fn(player) once for each living player on this computer. In split screen there
are up to 4 of them. getPlayer() only returns one of them, and which one changes
while the game runs, so anything that acts on "the player" goes through this or
gets its player passed in.
]]--
function BF.ForEachLocalPlayer(fn)
	for i = 0, getNumActivePlayers() - 1 do
		local player = getSpecificPlayer(i)
		if player and not player:isDead() then
			fn(player)
		end
	end
end

function BF.BathroomFunctionTimers()
	if BF.didFirstTimer then
		BF.ForEachLocalPlayer(function(player)
			BF.UpdateBathroomValues(player) -- If the initial setup is done, update the player's bathroom values.
			BF.HandleInstantAccidents(player) -- Check whether or not the player has urinated or defecated themselves.
			BF.HandleUrgencyHiccup(player) -- Urge waves: the player stops to hold on, with a chance of an accident.
			BF.DirtyBottomsEffects(player)
		end)
	else
		BF.didFirstTimer = true -- If this is the first call, set the flag to true and skip updating values.
	end
end

--[[

Calories:       -2200   >     3700
Protein:        -500    >     1000
Lipids:         -500    >     1000
Carbohydrates:  -500    >     1000

Burn rate: 10 Calories per 10 min
]]

-- Update player's bathroom-related values (urination and defecation)
function BF.UpdateBathroomValues(player)
	player = player or getPlayer()

	BF.UpdateUrinationValues(player)
	BF.UpdateDefecationValues(player)

	-- Decay bodily fumes (smell moodle) by 10% every 10 seconds
	--local currentFumes = BF.GetBodilyFumesValue()
	--local reducedFumes = currentFumes * 0.9
	--BF.SetBodilyFumesValue(reducedFumes)

	-- Instantly clear bodily fumes
	BF.SetBodilyFumesValue(0, player)

end

-- Whether an involuntary accident is allowed right now. kind is "pee" or "poop".
-- Asleep is the bed-accident option, awake is the accident option.
function BF.CanHaveAccident(player, kind)
	local vars = SandboxVars.BF
	if kind == "pee" then
		if not BF.IsUrinationEnabled() then return false end
		if player:isAsleep() then return vars.NightPeeAccidents ~= false end
		return vars.CanHavePeeAccident ~= false
	end
	if not BF.IsDefecationEnabled() then return false end
	if player:isAsleep() then return vars.NightPoopAccidents ~= false end
	return vars.CanHavePoopAccident ~= false
end

-- Make the player urinate / defecate in very "sudden" situations.
-- Like, getting injured (car crash, shot). Overflowing (bladder max capacity).
-- todo: injuries and car crashes don't do anything yet
function BF.HandleInstantAccidents(player)
	player = player or getPlayer()
	local urinateValue = BF.GetUrinateValue(player) -- Current bladder level
	local defecateValue = BF.GetDefecateValue(player) -- Current bowel level

	local bladderMaxValue = BF.GetBladderCapacity(player) -- mL this character holds
	local bowelsMaxValue = BF.GetBowelCapacity(player)

	-- Calculate overflow values
	local bladderThreshold = 0.95 * bladderMaxValue -- 95% of max bladder value
	local bowelsThreshold = 0.98 * bowelsMaxValue -- 98% of max bowel value

	-- Leaking feature for Incontinent traits --------------------------------------------------------------------------

	-- Base leak chance
	local leakChance = 2

	-- Drunk modifier: increase chance of leakage if player is drunk
	if player:getStats():get(CharacterStat.INTOXICATION) > 0 then
		leakChance = leakChance + 5 -- Drunk modifier
	end

	-- Panic modifier: increase chance of leakage if player is panicked
	if player:getMoodles():getMoodleLevel(MoodleType.PANIC) > 0 then
		leakChance = leakChance + (player:getMoodles():getMoodleLevel(MoodleType.PANIC)*2)  -- Increase by Panic level
	end


	-- Leaking feature for urination
	if BF.CanHaveAccident(player, "pee") and BF.HasTrait(player, BFTraits.UrinaryIncontinence) and (urinateValue >= 0.2 * bladderMaxValue) then
		if ZombRand(100) < leakChance then
			BF.TriggerSelfUrinate(player, true)  -- Trigger self urination leak action
		end
	end

	-- Leaking feature for defecation
	if BF.CanHaveAccident(player, "poop") and BF.HasTrait(player, BFTraits.FecalIncontinence) and (defecateValue >= 0.2 * bowelsMaxValue) then
		if ZombRand(100) < leakChance then
			BF.TriggerSelfDefecate(player, true)  -- Trigger self defecation leak action
		end
	end


	-- Handle pee/poop when player is asleep or awake.
	-- If player is asleep and their bladder/bowels are full, it happens automatically and wakes them up.
	-- If player is awake and their bladder/bowels are full, the appropriate self-action (pee/poop) begins.
	if player:isAsleep() then

		-- Check if the player needs to urinate while asleep
		if urinateValue >= bladderThreshold then
			player:forceAwake() -- Wake the player up if they need to pee

			-- If the player has the "Bedwetter" trait, trigger urination accident
			if BF.CanHaveAccident(player, "pee") and BF.HasTrait(player, BFTraits.Bedwetter) then
				BF.UrinateBottoms(player) -- Simulate peeing in bed
				BF.SetUrinateValue(0, player) -- Reset pee value after accident
			end

		-- Check if the player needs to defecate while asleep
		elseif defecateValue >= bowelsThreshold then
			player:forceAwake()  -- Wake the player up if they need to defecate

			-- If the player has the "Bedsoiler" trait, trigger defecation accident
			if BF.CanHaveAccident(player, "poop") and BF.HasTrait(player, BFTraits.Bedsoiler) then
				BF.DefecateBottoms(player) -- Simulate pooping in bed
				BF.SetDefecateValue(0, player)  -- Reset defecate value after accident
			end

		end
	else
		-- If the player is awake, start the pee or poop process based on their bladder/bowel status
		if urinateValue >= bladderThreshold and BF.CanHaveAccident(player, "pee") then
			BF.TriggerSelfUrinate(player)  -- Trigger self urination action
		elseif defecateValue >= bowelsThreshold and BF.CanHaveAccident(player, "poop") then
			BF.TriggerSelfDefecate(player)  -- Trigger self defecation action
		end
	end
end

-- =====================================================
--
-- URGENCY HICCUPS
--
-- =====================================================

--[[
"Hiccup" here means a hitch, a sudden wave of urgency. Not a "hic" hiccup lol

A bladder or bowel's urge comes in waves, and a wave is when control is most likely to slip.
Every 10 minutes the bladder and the bowels each get their own roll:

1. Urge chance. Zero until the organ is fairly full, then it climbs with fullness.
   Scaled by panic, stress, alcohol and diarrhea.
2. A wave passes. That organ can't have another one for a little bit.
3. During a wave the character stops to hold on. Only the organ having the wave
   can have an accident. The chance is small until it's very full; It's made worse by alcohol, panic,
   exhaustion, and running. Sitting down helps.
4. An accident is either a leak or a full loss. The emptier the organ, the likelier
   a leak, and Bladder/Bowel Control turns most accidents into leaks.

Past the overflow point HandleInstantAccidents takes over, so this only covers the
stretch between "I need to go" and "too late".
]]

BF.Urge = {
	pee = {
		urgeStart = 0.60,      -- fullness where urge waves begin (the moderate urge moodle)
		accidentStart = 0.75,  -- fullness where a wave can make you lose control
		overflow = 0.95,       -- HandleInstantAccidents' bladder threshold
		urgeScale = 1.0,
		cooldownTicks = 2,     -- 10-minute ticks before the next wave
	},
	poop = {
		-- The anal sphincter holds better than the bladder neck, so the bowels
		-- start later and push less often. Diarrhea undoes most of that.
		urgeStart = 0.65,
		accidentStart = 0.80,
		overflow = 0.98,       -- HandleInstantAccidents' bowel threshold
		urgeScale = 0.7,
		cooldownTicks = 3,
	},

	-- Incontinence moves both thresholds much lower.
	incontinentUrgeStart = 0.35,
	incontinentAccidentStart = 0.45,
	incontinentAccidentScale = 2.5,

	-- Percent chances. "min" is at the start threshold, "max" at overflow.
	minUrgeChance = 4, maxUrgeChance = 30, urgeChanceCap = 60,
	minAccidentChance = 3, maxAccidentChance = 30, accidentChanceCap = 85,

	-- How far a full-strength diarrhea moves the bowel thresholds down, per point of
	-- the diarrhea multiplier above 1 (which tops out at 5).
	diarrheaThresholdShift = 0.06,

	-- Hold animation length, from a mild wave to one right at overflow.
	minHoldTime = 40, maxHoldTime = 120,
	-- Waves at least this strong (0-1) use the line "can't hold it" and stop the game from being sped up.
	strongUrge = 0.5,
}

-- Actions during which the character is already relieving themselves or doing whatever similar shit.
-- A wave never happens during these.
local URGE_SAFE_ACTIONS = {
	ToiletUrinate = true, FixtureUrinate = true, GroundUrinate = true, SelfUrinate = true,
	ToiletDefecate = true, FixtureDefecate = true, GroundDefecate = true, SelfDefecate = true,
	Idle_PeeUrgency = true, Idle_PoopUrgency = true,
	WipeSelf = true, BF_RedressComplete = true,
}

local function clamp01(x)
	if x < 0 then return 0 end
	if x > 1 then return 1 end
	return x
end

-- How far `fill` is from `start` to `overflow`, 0-1. nil below `start`.
local function progressBetween(fill, start, overflow)
	if fill < start then return nil end
	if overflow <= start then return 1 end
	return clamp01((fill - start) / (overflow - start))
end

-- Fullness of the organ, 0-1.
function BF.GetUrgeFullness(player, kind)
	if kind == "pee" then
		return BF.GetBladderFullness(player)
	end
	return BF.GetBowelFullness(player)
end

local function isIncontinent(player, kind)
	if kind == "pee" then return BF.HasTrait(player, BFTraits.UrinaryIncontinence) end
	return BF.HasTrait(player, BFTraits.FecalIncontinence)
end

local function hasControl(player, kind)
	if kind == "pee" then return BF.HasTrait(player, BFTraits.BladderControl) end
	return BF.HasTrait(player, BFTraits.BowelControl)
end

local function getDiarrhea(player, kind)
	if kind ~= "poop" or not BF.GetDiarrheaMultiplier then return 1 end
	return BF.GetDiarrheaMultiplier(player)
end

-- 0 to 1. Uses the moodle so it doesn't depend on the stat's scale.
local function getDrunkenness(player)
	if not MoodleType.DRUNK then return 0 end
	return player:getMoodles():getMoodleLevel(MoodleType.DRUNK) / 4
end

local function getPanicLevel(player)
	return player:getMoodles():getMoodleLevel(MoodleType.PANIC)
end

local function sandboxMultiplier(name)
	local value = SandboxVars.BF and SandboxVars.BF[name]
	if type(value) ~= "number" then return 1 end
	return math.max(0, value)
end

-- The fullness thresholds for this character right now.
function BF.GetUrgeThresholds(player, kind)
	local cfg = BF.Urge[kind]
	local urgeStart, accidentStart = cfg.urgeStart, cfg.accidentStart
	if isIncontinent(player, kind) then
		urgeStart = math.min(urgeStart, BF.Urge.incontinentUrgeStart)
		accidentStart = math.min(accidentStart, BF.Urge.incontinentAccidentStart)
	end
	local shift = (getDiarrhea(player, kind) - 1) * BF.Urge.diarrheaThresholdShift
	return urgeStart - shift, accidentStart - shift, cfg.overflow
end

-- Percent chance of an urge wave this tick. Second value is how strong it would
-- be (0-1), nil when the organ isn't full enough for one.
function BF.GetUrgeChance(player, kind, fullness)
	local cfg = BF.Urge[kind]
	local urgeStart, _, overflow = BF.GetUrgeThresholds(player, kind)
	local strength = progressBetween(fullness, urgeStart, overflow)
	if not strength then return 0, nil end

	local chance = BF.Urge.minUrgeChance + (BF.Urge.maxUrgeChance - BF.Urge.minUrgeChance) * strength ^ 1.5
	chance = chance * cfg.urgeScale

	-- Fear and stress set the bowels and bladder off.
	chance = chance * (1 + 0.25 * getPanicLevel(player))
	chance = chance * (1 + 0.5 * player:getStats():get(CharacterStat.STRESS))

	-- Alcohol is a diuretic, so it affects the bladder much harder than the bowels.
	local drunk = getDrunkenness(player)
	chance = chance * (1 + (kind == "pee" and 0.6 or 0.25) * drunk)

	-- Diarrhea means cramping waves, one after another.
	chance = chance * getDiarrhea(player, kind) ^ 0.75

	-- Small/Large Bladder and Bowels need nothing here: they ONLY change capacity.
	-- NOTE: Important, don't forget.

	chance = chance * sandboxMultiplier("UrgeFrequencyMultiplier")
	return math.min(chance, BF.Urge.urgeChanceCap), strength
end

-- Percent chance that a wave becomes an accident.
function BF.GetUrgeAccidentChance(player, kind, fullness)
	local _, accidentStart, overflow = BF.GetUrgeThresholds(player, kind)
	local panic = getPanicLevel(player)

	local chance = 0
	local pressure = progressBetween(fullness, accidentStart, overflow)
	if pressure then
		chance = BF.Urge.minAccidentChance + (BF.Urge.maxAccidentChance - BF.Urge.minAccidentChance) * pressure ^ 2
	end

	-- Fear can loosen things even before the organ is very full.
	chance = chance + panic * 1.5
	chance = chance * (1 + 0.2 * panic)

	-- Drunkness negatively impacts the "hold it" reflex.
	chance = chance * (1 + 1.5 * getDrunkenness(player))

	-- Worn-out muscles are worse at holding.
	local endurance = player:getStats():get(CharacterStat.ENDURANCE)
	chance = chance * (1 + 0.5 * (1 - endurance))

	-- Running jostles, sitting down helps you clench.
	-- note: verify in a better test.
	if player:isSprinting() then
		chance = chance * 1.75
	elseif player:isRunning() then
		chance = chance * 1.3
	elseif player:isSitOnGround() then
		chance = chance * 0.6
	end

	chance = chance * getDiarrhea(player, kind) ^ 0.75

	if isIncontinent(player, kind) then
		chance = chance * BF.Urge.incontinentAccidentScale
	elseif hasControl(player, kind) then
		chance = chance * 0.5
	end

	chance = chance * sandboxMultiplier("UrgeAccidentMultiplier")
	return math.min(chance, BF.Urge.accidentChanceCap)
end

-- Whether an accident during a wave stops as a small leak instead of a full loss.
function BF.RollUrgeLeak(player, kind, fullness)
	local urgeStart, _, overflow = BF.GetUrgeThresholds(player, kind)
	-- Past overflow there's nothing left to hold back.
	if fullness >= overflow then return false end
	if hasControl(player, kind) then
		return ZombRand(100) < 75
	end
	-- The emptier it is, the likelier you clamp down in time. Up to 70% just past
	-- the urge threshold, down to none at overflow.
	local depth = progressBetween(fullness, urgeStart, overflow) or 0
	return ZombRand(100) < 70 * (1 - depth)
end

local function isRelieving(player)
	local queue = ISTimedActionQueue.getTimedActionQueue(player)
	if not queue or not queue.queue then return false end
	for _, action in ipairs(queue.queue) do
		if action and URGE_SAFE_ACTIONS[action.Type] then return true end
	end
	return false
end

local function isQueueEmpty(player)
	local queue = ISTimedActionQueue.getTimedActionQueue(player)
	return not queue or not queue.queue or #queue.queue == 0
end

-- Counts each organ's cooldown down one tick. Returns the cooldown table.
local function tickUrgeCooldowns(player)
	local modData = player:getModData()
	modData.bfUrgeCooldown = modData.bfUrgeCooldown or {}
	local cooldowns = modData.bfUrgeCooldown
	for _, kind in ipairs({ "pee", "poop" }) do
		local left = tonumber(cooldowns[kind]) or 0
		cooldowns[kind] = math.max(0, left - 1)
	end
	return cooldowns
end

-- Called every 10 minutes from BathroomFunctionTimers.
function BF.HandleUrgencyHiccup(player)
	player = player or getPlayer()
	if not player or player:isDead() then return end

	local cooldowns = tickUrgeCooldowns(player)

	if player:isAsleep() then return end
	if isRelieving(player) then return end

	-- Check both organs's waves, then only act on the stronger one.
	-- Doing both at the same time would suck, and it only really matters which ones bigger in a game sense.
	local wave = nil
	for _, kind in ipairs({ "pee", "poop" }) do
		local enabled = (kind == "pee" and BF.IsUrinationEnabled()) or (kind == "poop" and BF.IsDefecationEnabled())
		if enabled and (cooldowns[kind] or 0) <= 0 then
			local fullness = BF.GetUrgeFullness(player, kind)
			local chance, strength = BF.GetUrgeChance(player, kind, fullness)
			if strength and ZombRand(1000) < chance * 10 then
				if not wave or strength > wave.strength then
					wave = { kind = kind, fullness = fullness, strength = strength }
				end
			end
		end
	end
	if not wave then return end

	BF.DoUrgeWave(player, wave.kind, wave.fullness, wave.strength)
end

-- A single urge wave; holding and possible accident.
function BF.DoUrgeWave(player, kind, fullness, strength)
	player:getModData().bfUrgeCooldown[kind] = BF.Urge[kind].cooldownTicks

	local accident = false
	if BF.CanHaveAccident(player, kind) then
		accident = ZombRand(1000) < BF.GetUrgeAccidentChance(player, kind, fullness) * 10
	end

	local strong = accident or strength >= BF.Urge.strongUrge

	local modOptions = PZAPI.ModOptions:getOptions("BF")
	local playerSayStatus = modOptions and modOptions:getOption("6")
	if playerSayStatus and playerSayStatus:getValue(1) then
		player:Say(getText(strong and "IGUI_announce_UrgeHiccup" or "IGUI_announce_UrgeHiccupMild"))
	end

	-- Only stop to hold on if they weren't busy. Canceling what the player queued
	-- (often the walk to the toilet) would be frustrating and risky.
	local holdTime = BF.Urge.minHoldTime + (BF.Urge.maxHoldTime - BF.Urge.minHoldTime) * strength
	local hiccupType = kind == "pee" and "bladder" or "bowels"
	if not player:getVehicle() and isQueueEmpty(player) then
		BF.PlayUrgencyIdles(hiccupType, true, holdTime, player)
	elseif strong and not isClient() then
		UIManager.getSpeedControls():SetCurrentGameSpeed(1)
	end

	if not accident then return end

	local isLeak = BF.RollUrgeLeak(player, kind, fullness)
	if kind == "pee" then
		BF.TriggerSelfUrinate(player, isLeak)
	else
		BF.TriggerSelfDefecate(player, isLeak)
	end
end

-- Plays the urgency hold animation for the hiccup type ("bladder" or "bowels").
-- holdTime is the action length; stronger urges hold longer.
function BF.PlayUrgencyIdles(hiccupType, doTimedAction, holdTime, player)
	player = player or getPlayer()
	holdTime = holdTime or 40

	if hiccupType == "bladder" then
		player:playerVoiceSound("PainFromGlassCut") -- Replace this with specific pee sound if needed
		ISTimedActionQueue.add(Idle_PeeUrgency:new(player, holdTime, false, true))
	elseif hiccupType == "bowels" then
		player:playerVoiceSound("PainFromGlassCut") -- Replace this with specific poop sound if needed
		ISTimedActionQueue.add(Idle_PoopUrgency:new(player, holdTime, false, true))
	end
end

-- =====================================================
--
-- ACCIDENT FUNCTIONS
--
-- =====================================================

function BF.PainInBladder(player, pain)
	local part = player:getBodyDamage():getBodyPart(BodyPartType.Groin)
	part:setStiffness(pain)
end

function BF.PainInColon(player, pain)
	local part = player:getBodyDamage():getBodyPart(BodyPartType.Torso_Lower)
	part:setStiffness(pain)
end

-- =====================================================
--
-- EVENT REGISTRATION
--
-- =====================================================

local onFillItemTooltip = function(tooltip, layout, item)
	-- Check if the item has moddata with 'peed = true'
	if item:getModData().peed == true then
		local peedSeverity = item:getModData().peedSeverity
		-- Format the severity value to 1 decimal place
		--local peedText = "Soiled (Pee): " .. string.format("%.1f", peedSeverity) .. "%"

		--local peedTooltip = LayoutItem.new()
		--layout.items:add(peedTooltip)
		--peedTooltip:setLabel(peedText, 1.000, 0.867, 0.529, 1)

		-- Bar uses dark yellow
		local peeBarColor = table.newarray(1.000, 0.867, 0.529, 1)
		-- Label uses bright yellow
		local peeLabelColor = table.newarray(1.000, 1.000, 0.000, 1)

		InventoryUI.addTooltipBar(layout, "Urinated:", peedSeverity / 100, peeBarColor, peeLabelColor)
	end

	-- Check if the item has moddata with 'pooped == true'
	if item:getModData().pooped == true then
		local poopedSeverity = item:getModData().poopedSeverity
		-- Format the severity value to 1 decimal place
		--local poopedText = "Soiled (Poop): " .. string.format("%.1f", poopedSeverity) .. "%"

		--local poopedTooltip = LayoutItem.new()
		--layout.items:add(poopedTooltip)
		--poopedTooltip:setLabel(poopedText, 0.678, 0.412, 0.235, 1)

		-- Bar uses dark brown
		local poopBarColor = table.newarray(0.678, 0.412, 0.235, 1)
		-- Label uses bright brown
		local poopLabelColor = table.newarray(0.800, 0.522, 0.247, 1)

		InventoryUI.addTooltipBar(layout, "Defecated:", poopedSeverity / 100, poopBarColor, poopLabelColor)
	end
end

function BF.onGameBoot()
	local humanGroup = BodyLocations.getGroup("Human"); -- Get the BodyLocations group for humans

	-- Call getOrCreateLocation() with the registry objects
	local peedUndiesLocation   = humanGroup:getOrCreateLocation(BFBodyLocations.PeedOverlay_Underwear)
	local peedPantsLocation    = humanGroup:getOrCreateLocation(BFBodyLocations.PeedOverlay_Pants)
	local poopedUndiesLocation = humanGroup:getOrCreateLocation(BFBodyLocations.PoopedOverlay_Underwear)
	local poopedPantsLocation  = humanGroup:getOrCreateLocation(BFBodyLocations.PoopedOverlay_Pants)
end

--[[
Register the BathroomFunctionTimers function to run every 10 in-game minutes
This ensures bathroom values are periodically updated.
]]--
Events.EveryTenMinutes.Add(BF.BathroomFunctionTimers)

Events.OnGameBoot.Add(BF.onGameBoot)

InventoryUI.onFillItemTooltip:addListener(onFillItemTooltip)