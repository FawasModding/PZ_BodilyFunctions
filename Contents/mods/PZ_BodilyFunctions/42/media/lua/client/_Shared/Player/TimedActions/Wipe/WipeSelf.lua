-- WipeSelf: consumes wiping material and applies a soiling penalty to worn
-- clothing when the wipe was insufficient.
--
-- Wipe types:
--   usingDrainable  - toilet paper, tissues (charges, pooled across items)
--   usingOneTime    - paper items (count-based, possibly pooled across tiers)
--   usingBook       - books/notebooks; tears pages, returns clean paper + scraps
--   usingClothTool  - dishcloth/towel/rag: defecation -> mod junk, urination -> wet/dirty vanilla
--
-- bodilyFunction is "poop" or "pee". Pee wiping is female-only (gated by caller)
-- and applies a smaller penalty when insufficient.
--
-- The items are spent on the server (Commands.wipe in BF_ServerCommands.lua),
-- which reports how good the wipe was. Soiling is simulated on the client, so the
-- penalty is applied here on that reply.

---@class WipeSelf : ISBaseTimedAction
---@field character IsoPlayer
---@field wipeType string
---@field wipingWith InventoryItem
---@field bodilyFunction string
WipeSelf = ISBaseTimedAction:derive("WipeSelf")

function WipeSelf:isValid()
    return true
end

function WipeSelf:update()
end

function WipeSelf:start()
end

function WipeSelf:stop()
    ISBaseTimedAction.stop(self)
end

-- Applies the residual soiling penalty to unequipped bottom clothing (stored in
-- removedClothing), preferring underwear. Works for both pee and poop.
function WipeSelf:applyResidualPenalty(soilPenalty, removedClothing)
    local func = self.bodilyFunction
    local severityKey = (func == "pee") and "peedSeverity" or "poopedSeverity"
    local flagKey = (func == "pee") and "peed" or "pooped"

    local underwearLocations = {
        ItemBodyLocation.UNDERWEAR_BOTTOM,
        ItemBodyLocation.UNDERWEAR
    }

    -- Prefer unequipped underwear.
    for _, bodyLocation in ipairs(underwearLocations) do
        for _, entry in ipairs(removedClothing) do
            if entry:getBodyLocation() == bodyLocation then
                local modData = entry:getModData()
                modData[flagKey] = true
                modData[severityKey] = math.min((modData[severityKey] or 0) + soilPenalty, 100)
                return true
            end
        end
    end

    -- Otherwise, any unequipped non-underwear soilable garment.
    local soilableClothing = BF.GetSoilableClothing()
    for _, loc in ipairs(soilableClothing) do
        if loc ~= ItemBodyLocation.UNDERWEAR and loc ~= ItemBodyLocation.UNDERWEAR_BOTTOM then
            for _, entry in ipairs(removedClothing) do
                if entry:getBodyLocation() == loc then
                    local modData = entry:getModData()
                    modData[flagKey] = true
                    modData[severityKey] = math.min((modData[severityKey] or 0) + soilPenalty, 100)
                    return true
                end
            end
        end
    end

    return false
end

function WipeSelf:perform()
    -- Captured now: the list is cleared below, before the reply arrives.
    local removedClothing = self.character:getModData().removedClothing or {}

    if self.wipingWith then
        BF.SendTrackedCommand(self.character, "wipe", {
            wipeType = self.wipeType,
            itemType = self.wipingWith:getType(),
            bodilyFunction = self.bodilyFunction,
        }, function(result)
            if not result.ok or result.efficiency >= 1.0 then return end
            -- Pee residue is lighter than poop residue.
            local basePenalty = (self.bodilyFunction == "pee") and 3 or 5
            self:applyResidualPenalty(basePenalty * (1 - result.efficiency), removedClothing)
        end)
    end

    -- The list is only needed for the penalty; the garments are re-equipped from
    -- modData.bfRedress.
    BF.ResetRemovedClothing(self.character)

    ISBaseTimedAction.perform(self)
end

function WipeSelf:new(character, time, wipeType, wipingWith, bodilyFunction, pooledTypes)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = time
    o.wipeType = wipeType
    o.wipingWith = wipingWith
    o.bodilyFunction = bodilyFunction
    o.pooledTypes = pooledTypes
    return o
end
