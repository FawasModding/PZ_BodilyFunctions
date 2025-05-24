SelfDefecate = ISBaseTimedAction:derive("SelfDefecate")

-- Common clean-up: emptying the bowels (or leaving 95% if it's a leak)
function SelfDefecate:finishDefecation()
    if self.isLeak then
        self.character:getModData().defecateValue = self.initialDefecateValue * 0.95
    else
        self.character:getModData().defecateValue = 0.0
    end
end

function SelfDefecate:isValid()
    return true
end

function SelfDefecate:update()
    local delta = self:getJobDelta()  -- delta goes from 0.0 to 1.0 over the action time
    local initialValue = self.initialDefecateValue or 0

    if self.isLeak then
        -- For a leak event, only 5% is released over time.
        local newValue = initialValue * (1 - 0.05 * delta)
        self.character:getModData().defecateValue = newValue
    else
        -- Normal defecation: bowels reduce to zero over time.
        local newValue = initialValue * (1 - delta)
        self.character:getModData().defecateValue = math.max(newValue, 0)
    end
end

function SelfDefecate:start()
    -- Save the initial defecate value when the action begins.
    self.initialDefecateValue = self.character:getModData().defecateValue or 0
end

-- If the action is cancelled or stops early.
function SelfDefecate:stop()
    self:finishDefecation()
    ISBaseTimedAction.stop(self)
end

-- At the end of the action.
function SelfDefecate:perform()
    self:finishDefecation()
    ISBaseTimedAction.perform(self)
end

-- Override cancel to ensure the finish logic runs only once.
function SelfDefecate:cancel()
    self:finishDefecation()
    return ISBaseTimedAction.cancel(self)
end

-- Modified constructor: now includes an extra parameter "isLeak".
function SelfDefecate:new(character, time, stopWalk, stopRun, defecatedSelf, usingToilet, toiletObject, isLeak)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.stopOnWalk = stopWalk      -- Allow movement (set to false as needed)
    o.stopOnRun  = stopRun       -- Allow movement (set to false as needed)
    o.maxTime = time
    o.defecatedSelf = defecatedSelf
    o.usingToilet = usingToilet
    o.toiletObject = toiletObject
    o.isLeak = isLeak or false
    return o
end
