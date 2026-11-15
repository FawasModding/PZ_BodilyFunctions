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

    -- Crouch like a ground pee (females squat, males stand). No facing logic:
    -- fixtures like water/bushes/trash cans/dumpsters have no orientation to
    -- face toward, unlike a placed toilet.
    -- todo: sinks are a byproduct, unable to orient. possibly make orientation an extra option here
    if self.character:isFemale() then
        self:setActionAnim("bathroomSquat")
    else
        self:setActionAnim("bathroomStandPee")
    end

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
    self:spawnPuddle()
    ISBaseTimedAction.perform(self)

    -- Put clothing back on now that we're done
    if self.character:isFemale() then
        BF.ReequipBottomClothing(self.character)
    end

    self:stopSound()
end

function FixtureUrinate:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

-- Peeing out of an open window puts the puddle on the ground on the far side;
-- into a bush, on the bush's square. Sinks, showers, tubs, water and trash cans
-- don't make a puddle.
function FixtureUrinate:spawnPuddle()
    local fixture = self.fixture
    if not fixture or not SandboxVars.BF.CreatePeeObject then return end
    local square
    if BF_Waste.isOpenWindow(fixture) then
        square = BF_Waste.outside(fixture, self.character)
    elseif BF_ReliefTiles.GetBushTiles()[fixture:getTextureName()] == true then
        square = fixture:getSquare()
    end
    if square then
        BF.SpawnWaste(self.character, "pee", self.initialUrinateValue, square)
    end
end

-- fixture is the sink/shower/bush/water/trash can/dumpster/window object being used.
function FixtureUrinate:new(character, time, stopWalk, stopRun, fixture)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.fixture = fixture
    o.stopOnWalk = stopWalk
    o.stopOnRun = stopRun
    o.maxTime = time
    return o
end