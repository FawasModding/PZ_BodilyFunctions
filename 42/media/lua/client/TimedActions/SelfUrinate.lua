SelfUrinate = ISBaseTimedAction:derive("SelfUrinate")

-- Emptying the bladder (or leaving 95% if it's a leak)
function SelfUrinate:finishUrination()
    if self.isLeak then
        self.character:getModData().urinateValue = self.initialUrinateValue * 0.95
    else
        self.character:getModData().urinateValue = 0.0
    end
end

function SelfUrinate:isValid()
    return true
end

function SelfUrinate:update()
    local delta = self:getJobDelta()  -- delta goes from 0.0 to 1.0
    local initialValue = self.initialUrinateValue or 0

    if self.isLeak then
        -- For a leak event, only 5% is released over time.
        local newValue = initialValue * (1 - 0.05 * delta)
        self.character:getModData().urinateValue = newValue
    else
        -- Normal urination: bladder reduces to zero over time.
        local newValue = initialValue * (1 - delta)
        self.character:getModData().urinateValue = math.max(newValue, 0)
    end
end

function SelfUrinate:start()
    -- Save the initial urinate value when the action begins.
    self.initialUrinateValue = self.character:getModData().urinateValue or 0

    -- Play pee self loop
    self.sound = self.character:getEmitter():playSound("BF_Pee_Self")
end

-- If the action is cancelled or stops early.
function SelfUrinate:stop()
    self:stopSound() -- Stop peeing sound
    self:finishUrination()
    ISBaseTimedAction.stop(self)
end

-- At the end of the action.
function SelfUrinate:perform()
    self:finishUrination()
    ISBaseTimedAction.perform(self)
end

-- Override cancel to ensure finish logic runs only once.
function SelfUrinate:cancel()
    self:finishUrination()
    return ISBaseTimedAction.cancel(self)
end

function SelfUrinate:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound);
	end
end

-- Now includes an extra parameter "isLeak".
function SelfUrinate:new(character, time, stopWalk, stopRun, peedSelf, usingToilet, toiletObject, isLeak)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.stopOnWalk = stopWalk      -- Allow movement (set false)
    o.stopOnRun  = stopRun       -- Allow movement (set false)
    o.maxTime = time
    o.peedSelf = peedSelf
    o.usingToilet = usingToilet
    o.toiletObject = toiletObject
    o.isLeak = isLeak or false
    return o
end
