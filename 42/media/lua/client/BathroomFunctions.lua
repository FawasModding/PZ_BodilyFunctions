BathroomFunctions = {}
BathroomFunctions.didFirstTimer = false
FlySquares = {}

--BATHROOM VALUES

function BathroomFunctions.GetUrinateValue()
	local player = getPlayer()
	local urinateValue = player:getModData().urinateValue

	if type(urinateValue) ~= "number" then
		urinateValue = 0.0
	end

	return urinateValue
end
function BathroomFunctions.GetDefecateValue()
	local player = getPlayer()
	local defecateValue = player:getModData().defecateValue

	if type(defecateValue) ~= "number" then
		defecateValue = 0.0
	end

	return defecateValue
end

--BATHROOM CHECKS

function BathroomFunctions.BathroomFunctionTimers()
	if BathroomFunctions.didFirstTimer then
		BathroomFunctions.NewBathroomValues()
	else BathroomFunctions.didFirstTimer = true end
end

function BathroomFunctions.NewBathroomValues()
	local player = getPlayer()

	--Urination value
	local urinateValue = BathroomFunctions.GetUrinateValue()
	local urinateIncrease = 1

	urinateValue = urinateValue + urinateIncrease
	player:getModData().urinateValue = tonumber(urinateValue)
	print(urinateValue)

	--Defecation Value
	local defecateValue = BathroomFunctions.GetDefecateValue()
	local defecateIncrease = 0.5 * 1

	defecateValue = defecateValue + defecateIncrease
	player:getModData().defecateValue = tonumber(defecateValue)
	print(defecateValue)
end

Events.EveryTenMinutes.Add(BathroomFunctions.BathroomFunctionTimers)