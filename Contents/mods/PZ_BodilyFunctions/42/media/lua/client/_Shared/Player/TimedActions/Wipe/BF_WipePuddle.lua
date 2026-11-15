-- =====================================================
--
-- BF_WipePuddle
--
-- Wipes up a urine puddle with a wipeable item and soap. The items are used
-- and the puddle is reduced on the server (Commands.wipePuddle); this only plays
-- the scrubbing animation and sends the request when it's done. Amounts are in
-- BF_PuddleWipe.
--
-- =====================================================

require "TimedActions/ISBaseTimedAction"
require "BF_PuddleWipe"

BF_WipePuddle = ISBaseTimedAction:derive("BF_WipePuddle")
local W = BF_Sewage

function BF_WipePuddle:isValid()
    local square = self.puddle and self.puddle:getSquare()
    return square ~= nil and self.puddle:getObjectIndex() >= 0 and BF_PuddleWipe.canWipe(self.puddle)
        and W.near(self.character, square)
end

function BF_WipePuddle:waitToStart()
    self.character:faceThisObject(self.puddle)
    return self.character:shouldBeTurning()
end

function BF_WipePuddle:start()
    self:setActionAnim("ScrubFloor")
    self.sound = self.character:playSound("CleanBloodScrub")
end

function BF_WipePuddle:update()
    self.character:faceThisObject(self.puddle)
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function BF_WipePuddle:stopSound()
    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
        self.sound = nil
    end
end

function BF_WipePuddle:stop()
    self:stopSound()
    ISBaseTimedAction.stop(self)
end

function BF_WipePuddle:perform()
    self:stopSound()
    local square = self.puddle:getSquare()
    BF.SendTrackedCommand(self.character, "wipePuddle", {
        x = square:getX(), y = square:getY(), z = square:getZ(),
        wipeType = self.wipeType, itemType = self.itemType,
    }, function() end)
    ISBaseTimedAction.perform(self)
end

function BF_WipePuddle:new(character, puddle, wipeType, itemType)
    local o = ISBaseTimedAction.new(self, character)
    o.puddle, o.wipeType, o.itemType = puddle, wipeType, itemType
    o.maxTime = character:isTimedActionInstant() and 1 or math.max(60, math.floor(120 * W.volume(puddle)))
    o.stopOnWalk, o.stopOnRun, o.stopOnAim = true, true, true
    return o
end

return BF_WipePuddle
