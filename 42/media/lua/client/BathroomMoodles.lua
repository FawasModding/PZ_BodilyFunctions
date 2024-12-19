require "MF_ISMoodle"
MF.createMoodle("Defecation");
MF.createMoodle("Urination");

-- =====================================================
--
-- BATHROOM VALUES FUNCTIONS
--
-- =====================================================

--[[
Function to retrieve the player's current urination value
If the value isn't set or isn't a valid number, it defaults to 0.0.
]]--
function BathroomFunctions.GetUrinateValue()
	local player = getPlayer() -- Fetch the current player object
	local urinateValue = player:getModData().urinateValue -- Retrieve the urination value from the player's modData

	if type(urinateValue) ~= "number" then -- Ensure the retrieved value is a valid number
		urinateValue = 0.0 -- Default to 0.0 if the value is invalid or undefined
	end

	return urinateValue -- Return the urination value
end

--[[
Function to retrieve the player's current defecation value
If the value isn't set or isn't a valid number, it defaults to 0.0.
]]--
function BathroomFunctions.GetDefecateValue()
	local player = getPlayer() -- Fetch the current player object
	local defecateValue = player:getModData().defecateValue -- Retrieve the defecation value from the player's modData

	if type(defecateValue) ~= "number" then -- Ensure the retrieved value is a valid number
		defecateValue = 0.0 -- Default to 0.0 if the value is invalid or undefined
	end

	return defecateValue -- Return the defecation value
end

local function CheckBathroomMeters(player)
	local playerNum = player:getPlayerNum()
	local moodle = MF.getMoodle("Defecation",playerNum)
	local moodle2 = MF.getMoodle("Urination",playerNum)

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
		local defecationPercent = defecationValue / bladderMaxValue

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

end

Events.OnPlayerUpdate.Add(CheckBathroomMeters)
