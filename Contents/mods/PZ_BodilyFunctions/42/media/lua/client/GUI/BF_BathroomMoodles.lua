require "MF_ISMoodle"
require "BodilyFunctions"
MF.createMoodle("Defecation");
MF.createMoodle("Urination");
MF.createMoodle("PoopedSelf");
MF.createMoodle("PeedSelf");
MF.createMoodle("BodilyFumes");

local function CheckBathroomMeters(player)
		local playerNum = player:getPlayerNum()
		local moodle = MF.getMoodle("Defecation",playerNum)
		local moodle2 = MF.getMoodle("Urination",playerNum)
		local moodle3 = MF.getMoodle("PoopedSelf",playerNum)
		local moodle4 = MF.getMoodle("PeedSelf",playerNum)
		local moodle5 = MF.getMoodle("BodilyFumes",playerNum)

		local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Get the max bowel value, default to 100 if not set
		local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Get the max bladder value, default to 100 if not set

		local modOptions = PZAPI.ModOptions:getOptions("BF")

		local showMoodles = modOptions:getOption("4")
		if(showMoodles:getValue(1)) then
			if moodle then
				local defecationValue = BF.GetDefecateValue()
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

				-- Track the previous moodle value
				local previousDefecationMoodleValue = moodle:getValue()

				-- Apply moodle value based on sorted thresholds
				local newDefecationMoodleValue = 0.5 -- Default value
				for i = 1, #sortedDefecationThresholds do
					local threshold = sortedDefecationThresholds[i]
					if defecationPercent > threshold then
						newDefecationMoodleValue = defecationThreshold[threshold]
					end
				end

				-- Only set the moodle value if it changes
				if newDefecationMoodleValue ~= previousDefecationMoodleValue then
					moodle:setValue(newDefecationMoodleValue)
				end
			end

			if moodle2 then
				local urinationValue = BF.GetUrinateValue()
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

				-- Track the previous moodle value
				local previousMoodleValue = moodle2:getValue()

				-- Apply moodle value based on sorted thresholds
				local newMoodleValue = 0.5 -- Default value
				for i = 1, #sortedUrinationThresholds do
					local threshold = sortedUrinationThresholds[i]
					if urinationPercent > threshold then
						newMoodleValue = urinationThreshold[threshold]
					end
				end

				-- Only set the moodle value if it changes
				if newMoodleValue ~= previousMoodleValue then
					moodle2:setValue(newMoodleValue)
				end

			end
		else
			if moodle and moodle2 then
				moodle:setValue(.5)
				moodle2:setValue(.5)
			end
		end

		local showSoiledMoodles = modOptions:getOption("5")
		if(showSoiledMoodles:getValue(1)) then
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
					moodle3:setValue(poopedSelfThreshold[1.0])
				elseif poopedSelfPercent >= 0.75 then
					moodle3:setValue(poopedSelfThreshold[0.75])
				elseif poopedSelfPercent >= 0.5 then
					moodle3:setValue(poopedSelfThreshold[0.5])
				elseif poopedSelfPercent >= 0.25 then
					moodle3:setValue(poopedSelfThreshold[0.25])
				else
					moodle3:setValue(0.5)
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
					moodle4:setValue(peedSelfThreshold[1.0])
				elseif peedSelfPercent >= 0.75 then
					moodle4:setValue(peedSelfThreshold[0.75])
				elseif peedSelfPercent >= 0.5 then
					moodle4:setValue(peedSelfThreshold[0.5])
				elseif peedSelfPercent >= 0.25 then
					moodle4:setValue(peedSelfThreshold[0.25])
				else
					moodle4:setValue(0.5)
				end
			end
		else
			if moodle3 and moodle4 then
				moodle3:setValue(.5)
				moodle4:setValue(.5)
			end
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
		moodle5:setValue(bodilyFumesThreshold[1.0])
	elseif bodilyFumesPercent >= 0.75 then
		moodle5:setValue(bodilyFumesThreshold[0.75])
	elseif bodilyFumesPercent >= 0.5 then
		moodle5:setValue(bodilyFumesThreshold[0.5])
	elseif bodilyFumesPercent >= 0.25 then
		moodle5:setValue(bodilyFumesThreshold[0.25])
	else
		moodle5:setValue(0.5)
	end

	end
end

Events.OnPlayerUpdate.Add(CheckBathroomMeters)
