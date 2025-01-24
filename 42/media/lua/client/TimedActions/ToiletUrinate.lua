ToiletUrinate = ISBaseTimedAction:derive("ToiletUrinate")
function ToiletUrinate:isValid()
	return true
end

function ToiletUrinate:update()
	-- Reduce urination value proportionally to the elapsed time
    local delta = self:getJobDelta() -- Get the progress of the action (0.0 to 1.0)
    local initialValue = self.character:getModData().urinateValue
    local newValue = self.initialUrinateValue - (delta * self.initialUrinateValue)
    self.character:getModData().urinateValue = math.max(newValue, 0) -- Ensure it doesn't go below 0

	local props = self.toiletObject:getProperties()

    local facing = props:Val("Facing")

    if facing == "N" then
        if self.character:isFemale() == true then
            self.character:setDir(IsoDirections.N)
        else
            self.character:setDir(IsoDirections.S)
        end
    elseif facing == "E" then
        if self.character:isFemale() == true then
            self.character:setDir(IsoDirections.E)
        else
            self.character:setDir(IsoDirections.W)
        end
    elseif facing == "S" then
        if self.character:isFemale() == true then
            self.character:setDir(IsoDirections.S)
        else
            self.character:setDir(IsoDirections.N)
        end
    elseif facing == "W" then
        if self.character:isFemale() == true then
            self.character:setDir(IsoDirections.W)
        else
            self.character:setDir(IsoDirections.E)
        end
    end

end

function ToiletUrinate:start()
	-- Save the initial urination value at the start of the action
    self.initialUrinateValue = self.character:getModData().urinateValue or 0

	--Character pees in toilet, has animation for male/female
	if self.character:isFemale() then --If female, sit
		self:setActionAnim("bathroomSitToilet")
	else --If male, stand
		self:setActionAnim("bathroomStandToilet")
	end

end

function ToiletUrinate:stop()
	ISBaseTimedAction.stop(self)

	-- If ending early, don't keep the items stored
	BathroomFunctions.ResetRemovedClothing(self.character)
end

function ToiletUrinate:perform()
	local urinateValue = BathroomFunctions.GetUrinateValue()

	self.character:getModData().urinateValue = 0.0 --RESET URINE VALUE
	ISBaseTimedAction.perform(self)

	-- Put back on bottom clothing afterwards
    if self.character:isFemale() == true then
        BathroomFunctions.ReequipBottomClothing(self.character)
    end
end

function ToiletUrinate:new(character, time, stopWalk, stopRun, toiletObject)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	o.toiletObject = toiletObject
	return o
end