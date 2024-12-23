GroundDefecate = ISBaseTimedAction:derive("GroundDefecate")
function GroundDefecate:isValid()
	return true
end

function GroundDefecate:update()
	-- Reduce defecation value proportionally to the elapsed time
    local delta = self:getJobDelta() -- Get the progress of the action (0.0 to 1.0)
    local initialValue = self.character:getModData().defecateValue
    local newValue = self.initialDefecateValue - (delta * self.initialDefecateValue)
    self.character:getModData().defecateValue = math.max(newValue, 0) -- Ensure it doesn't go below 0
end

function GroundDefecate:start()
	-- Save the initial defecation value at the start of the action
    self.initialDefecateValue = self.character:getModData().defecateValue or 0

	-- Remove clothing items before starting the defecation
    self.removedClothing = {}

	self:setActionAnim("bathroomSquat")
end

function GroundDefecate:stop()
	ISBaseTimedAction.stop(self)
end

function GroundDefecate:perform()
	local defecateValue = BathroomFunctions.GetDefecateValue()

	-- Add fatigue since the player had to squat to poop
	self.character:getStats():setFatigue(self.character:getStats():getFatigue() + 0.025)

	getSoundManager():PlayWorldSound("PoopSelf1", self.character:getCurrentSquare(), 0, 10, 0, false)

	--Manage poop objects, poops should be different dependant on defecate value, diarrhea, and corn
	if SandboxVars.BathroomFunctions.CreatePoopObject == true then
		local fecesItem = instanceItem("BathroomFunctions.HumanFeces")
		self.character:getCurrentSquare():AddWorldInventoryItem(fecesItem, ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
	end

	self.character:getModData().defecateValue = 0.0 --RESET DEFECATE VALUE
	ISBaseTimedAction.perform(self)
end

function GroundDefecate:new(character, time, stopWalk, stopRun)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	return o
end