---@class FixtureUrinate : ISBaseTimedAction
---@field character IsoPlayer
FixtureUrinate = ISBaseTimedAction:derive("FixtureUrinate")

function FixtureUrinate:isValid()
    return true
end

function FixtureUrinate:update()
    -- Reduce urination value proportionally to the elapsed time
    local delta = self:getJobDelta()
    local newValue = self.initialUrinateValue - (delta * self.initialUrinateValue)
    self.character:getModData().urinateValue = math.max(newValue, 0)
end

function FixtureUrinate:start()
    -- Save the initial urination value at the start of the action
    self.initialUrinateValue = self.character:getModData().urinateValue or 0

    -- No sitting, walking, or direction changes (yet). Player uses bathroom where they are.
    -- todo: this will be improved, but for now this is the best way to simulate it generically enough.
    self.sound = self.character:getEmitter():playSound("BF_Pee_Toilet_Light")
end

function FixtureUrinate:stop()
    ISBaseTimedAction.stop(self)

    -- If ending early, don't keep the items stored
    BF.ResetRemovedClothing(self.character)

    self:stopSound()
end

function FixtureUrinate:perform()
    self.character:getModData().urinateValue = 0.0 -- RESET URINE VALUE
    ISBaseTimedAction.perform(self)

    -- Put clothing back on now that we're done
    BF.ReequipBottomClothing(self.character)

    self:stopSound()
end

function FixtureUrinate:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function FixtureUrinate:new(character, time, stopWalk, stopRun)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.stopOnWalk = stopWalk
    o.stopOnRun = stopRun
    o.maxTime = time
    return o
end