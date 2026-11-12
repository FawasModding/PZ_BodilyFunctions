---@diagnostic disable: undefined-global
require "MF_ISMoodle"
require "BodilyFunctions"
MF.createMoodle("Defecation");
MF.createMoodle("Urination");
MF.createMoodle("PoopedSelf");
MF.createMoodle("PeedSelf");
MF.createMoodle("BodilyFumes");

-- PZAPI.ModOptions:getOptions()/getOption() were being looked up three times a
-- frame per player. The handles never change once the options are built, so
-- resolve them once.
local cachedOptions = nil
local function getBFOption(id)
	if not cachedOptions then
		cachedOptions = PZAPI.ModOptions:getOptions("BF")
		if not cachedOptions then return nil end
	end
	return cachedOptions:getOption(id)
end

-- MF.ISMoodle:setValue() recomputes the level, recomputes good/bad/neutral and
-- adds or removes the moodle from the UI manager. Only the two urge moodles
-- were guarded against re-setting the same value; the other three fired that
-- whole path every frame. All five are guarded now.
local function setMoodleValue(moodle, value)
	if moodle and moodle:getValue() ~= value then
		moodle:setValue(value)
	end
end

local function CheckBathroomMeters(player)
		local playerNum = player:getPlayerNum()
		local moodle = MF.getMoodle("Defecation",playerNum)
		local moodle2 = MF.getMoodle("Urination",playerNum)
		local moodle3 = MF.getMoodle("PoopedSelf",playerNum)
		local moodle4 = MF.getMoodle("PeedSelf",playerNum)
		local moodle5 = MF.getMoodle("BodilyFumes",playerNum)

		local bowelsMaxValue = BF.GetBowelCapacity(player)
		local bladderMaxValue = BF.GetBladderCapacity(player)

		local showMoodles = getBFOption("4")
		if showMoodles and showMoodles:getValue(1) then
			if moodle then
				local defecationValue = BF.GetBowelAmount(player)
				local defecationThreshold = {
					[0.4] = 0.4, -- Mild urge starts at 40%
					[0.6] = 0.3, -- Moderate urge at 60%
					[0.8] = 0.2, -- High urge at 80%
					[0.9] = 0.1  -- Critical need at 90% or above
				}

				-- Defecation Logic
				local defecationPercent = defecationValue / bowelsMaxValue

				-- Sort the defecationThreshold keys in ascending order
				local sortedDefecationThresholds = {}
				for threshold in pairs(defecationThreshold) do
					table.insert(sortedDefecationThresholds, threshold)
				end
				table.sort(sortedDefecationThresholds)

				-- Apply moodle value based on sorted thresholds
				local newDefecationMoodleValue = 0.5 -- Default value
				for i = 1, #sortedDefecationThresholds do
					local threshold = sortedDefecationThresholds[i]
					if defecationPercent > threshold then
						newDefecationMoodleValue = defecationThreshold[threshold]
					end
				end

				setMoodleValue(moodle, newDefecationMoodleValue)
			end

			if moodle2 then
				local urinationValue = BF.GetBladderAmount(player)
				local urinationThreshold = {
					[0.4] = 0.4, -- Mild urge starts at 40%
					[0.6] = 0.3, -- Moderate urge at 60%
					[0.8] = 0.2, -- High urge at 80%
					[0.9] = 0.1  -- Critical need at 90% or above
				}

				-- Urination Logic
				local urinationPercent = urinationValue / bladderMaxValue

				-- Sort the urinationThreshold keys in ascending order
				local sortedUrinationThresholds = {}
				for threshold in pairs(urinationThreshold) do
					table.insert(sortedUrinationThresholds, threshold)
				end
				table.sort(sortedUrinationThresholds)

				-- Apply moodle value based on sorted thresholds
				local newMoodleValue = 0.5 -- Default value
				for i = 1, #sortedUrinationThresholds do
					local threshold = sortedUrinationThresholds[i]
					if urinationPercent > threshold then
						newMoodleValue = urinationThreshold[threshold]
					end
				end

				setMoodleValue(moodle2, newMoodleValue)

			end
		else
			setMoodleValue(moodle, .5)
			setMoodleValue(moodle2, .5)
		end

		local showSoiledMoodles = getBFOption("5")
		if showSoiledMoodles and showSoiledMoodles:getValue(1) then
			if moodle3 then
				local poopedSelfValue = BF.GetPoopedSelfValue()
				local poopedSelfPercent = poopedSelfValue / 100 -- Assuming a max value of 100 for severity

				local poopedSelfThreshold = {
					[0.25] = 0.4,
					[0.5] = 0.3,
					[0.75] = 0.2,
					[1.0] = 0.1
				}

				-- Adjusted conditional logic to ensure correct thresholds
				if poopedSelfPercent >= 1.0 then
					setMoodleValue(moodle3, poopedSelfThreshold[1.0])
				elseif poopedSelfPercent >= 0.75 then
					setMoodleValue(moodle3, poopedSelfThreshold[0.75])
				elseif poopedSelfPercent >= 0.5 then
					setMoodleValue(moodle3, poopedSelfThreshold[0.5])
				elseif poopedSelfPercent >= 0.25 then
					setMoodleValue(moodle3, poopedSelfThreshold[0.25])
				else
					setMoodleValue(moodle3, 0.5)
				end
			end

			if moodle4 then
				local peedSelfValue = BF.GetPeedSelfValue()
				local peedSelfPercent = peedSelfValue / 100 -- Assuming a max value of 100 for severity

				local peedSelfThreshold = {
					[0.25] = 0.4,
					[0.5] = 0.3,
					[0.75] = 0.2,
					[1.0] = 0.1
				}

				-- Adjusted conditional logic to ensure correct thresholds
				if peedSelfPercent >= 1.0 then
					setMoodleValue(moodle4, peedSelfThreshold[1.0])
				elseif peedSelfPercent >= 0.75 then
					setMoodleValue(moodle4, peedSelfThreshold[0.75])
				elseif peedSelfPercent >= 0.5 then
					setMoodleValue(moodle4, peedSelfThreshold[0.5])
				elseif peedSelfPercent >= 0.25 then
					setMoodleValue(moodle4, peedSelfThreshold[0.25])
				else
					setMoodleValue(moodle4, 0.5)
				end
			end
		else
			setMoodleValue(moodle3, .5)
			setMoodleValue(moodle4, .5)
		end

		-- TODO: Create "showBodilyFumesMoodle"
		if moodle5 then
		local bodilyFumesValue = BF.GetBodilyFumesValue()
		local bodilyFumesPercent = bodilyFumesValue / 100 -- Assuming 0–100 scale

		local bodilyFumesThreshold = {
			[0.25] = 0.4,
			[0.5]  = 0.3,
			[0.75] = 0.2,
			[1.0]  = 0.1
		}

	if bodilyFumesPercent >= 1.0 then
		setMoodleValue(moodle5, bodilyFumesThreshold[1.0])
	elseif bodilyFumesPercent >= 0.75 then
		setMoodleValue(moodle5, bodilyFumesThreshold[0.75])
	elseif bodilyFumesPercent >= 0.5 then
		setMoodleValue(moodle5, bodilyFumesThreshold[0.5])
	elseif bodilyFumesPercent >= 0.25 then
		setMoodleValue(moodle5, bodilyFumesThreshold[0.25])
	else
		setMoodleValue(moodle5, 0.5)
	end

	end
end

Events.OnPlayerUpdate.Add(CheckBathroomMeters)
