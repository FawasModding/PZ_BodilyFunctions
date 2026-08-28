---@class FixtureDefecate : ISBaseTimedAction
---@field character IsoPlayer
FixtureDefecate = ISBaseTimedAction:derive("FixtureDefecate")

function FixtureDefecate:isValid()
    return true
end

function FixtureDefecate:update()
    local delta = self:getJobDelta()
    local newValue = self.initialDefecateValue - (delta * self.initialDefecateValue)
    self.character:getModData().defecateValue = math.max(newValue, 0)
end

function FixtureDefecate:start()
    self.initialDefecateValue = self.character:getModData().defecateValue or 0

    -- Crouch like a ground poop. No facing logic, these objects have no
    -- meaningful orientation to face toward.
    self:setActionAnim("bathroomSquat")

    self.sound = self.character:getEmitter():playSound("BF_Poop_Self_Light")
end

function FixtureDefecate:stop()
    ISBaseTimedAction.stop(self)
    BF.ResetRemovedClothing(self.character)
    self:stopSound()
end

function FixtureDefecate:perform()
    -- Fatigue from squatting, same as GroundDefecate.
    local fatigueToGive = self.character:getStats():get(CharacterStat.FATIGUE) + 0.025
    self.character:getStats():set(CharacterStat.FATIGUE, fatigueToGive)

    -- Unlike GroundDefecate, no BF.HumanFeces world item is spawned. The
    -- waste goes into the fixture (water/bush/trash/dumpster), not the ground.
    -- todo: waste should go into dumpster/trash can inventory eventually
    self.character:getModData().defecateValue = 0.0
    ISBaseTimedAction.perform(self)

    BF.ReequipBottomClothing(self.character)

    self:stopSound()
end

function FixtureDefecate:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function FixtureDefecate:new(character, time, stopWalk, stopRun)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.stopOnWalk = stopWalk
    o.stopOnRun = stopRun
    o.maxTime = time
    return o
end