require "MF_ISMoodle"
MF.createMoodle("Defecation");
MF.createMoodle("Urination");
MF.createMoodle("PoopedSelf");
MF.createMoodle("PeedSelf");

local function CheckBathroomMeters(player)
	local playerNum = player:getPlayerNum()
	local moodle = MF.getMoodle("Defecation",playerNum)
	local moodle2 = MF.getMoodle("Urination",playerNum)
	local moodle3 = MF.getMoodle("PoopedSelf",playerNum)
	local moodle4 = MF.getMoodle("PeedSelf",playerNum)

	local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Get the max bowel value, default to 100 if not set
	local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Get the max bladder value, default to 100 if not set

	if moodle then
		local defecationValue = BathroomFunctions.GetDefecateValue()
		local defecationThreshold = {
			[0.25] = 0.4,
			[0.5] = 0.3,
			[0.75] = 0.2,
			[1.0] = 0.1
		}

		-- Calculate percentage of the max value
		local defecationPercent = defecationValue / bowelsMaxValue

		if defecationPercent > 1.0 then
			moodle:setValue(defecationThreshold[1.0])
		elseif defecationPercent > 0.75 then
			moodle:setValue(defecationThreshold[0.75])
		elseif defecationPercent > 0.5 then
			moodle:setValue(defecationThreshold[0.5])
		elseif defecationPercent > 0.25 then
			moodle:setValue(defecationThreshold[0.25])
		else
			moodle:setValue(0.5) -- Default value if defecation level is below 25%
		end
	end

	if moodle2 then
		local urinationValue = BathroomFunctions.GetUrinateValue()
		local urinationThreshold = {
			[0.25] = 0.4,
			[0.5] = 0.3,
			[0.75] = 0.2,
			[1.0] = 0.1
		}

		-- Calculate percentage of the max value
		local urinationPercent = urinationValue / bladderMaxValue

		if urinationPercent > 1.0 then
			moodle2:setValue(urinationThreshold[1.0])
		elseif urinationPercent > 0.75 then
			moodle2:setValue(urinationThreshold[0.75])
		elseif urinationPercent > 0.5 then
			moodle2:setValue(urinationThreshold[0.5])
		elseif urinationPercent > 0.25 then
			moodle2:setValue(urinationThreshold[0.25])
		else
			moodle2:setValue(0.5) -- Default value if urination level is below 25%
		end
	end

	if moodle3 then
		local poopedSelfValue = BathroomFunctions.GetPoopedSelfValue()
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
		local peedSelfValue = BathroomFunctions.GetPeedSelfValue()
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

end

Events.OnPlayerUpdate.Add(CheckBathroomMeters)
