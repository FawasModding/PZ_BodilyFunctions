require "BodilyFunctions"

BF_Defecation = BF_Defecation or {}

function BF_Defecation.GlobalFunctionTimers()
    BF_Defecation.UpdateDefecationValues()
end

-- Function to update defecation-related values
function BF_Defecation.UpdateDefecationValues()
    local player = getPlayer()

    -- Get player stats
    local thirst = player:getStats():getThirst()
    local hunger = player:getStats():getHunger()
    local stress = player:getStats():getStress()
    local endurance = player:getStats():getEndurance()

    -- Calculate bowel multiplier where:
    -- - At hunger 0 (fully satiated): multiplier = 1.0
    -- - At hunger 1 (Starving): multiplier = 0.3
    local bowelMultiplier = 1.0 - (hunger * 0.7)

    local stressEffect = stress * 0.3
    local urgencyFactor = (1.0 - endurance) * 0.1
    local randomBowelFactor = 0.9 + (ZombRand(21) / 100)

    -- Final multiplier
    local finalBowelMultiplier = (bowelMultiplier + stressEffect + urgencyFactor) * randomBowelFactor

    local baseBowelsMax  = BF.GetMaxBowelValue()
    local defecateValue = BF.GetDefecateValue()

    -- Base Increase Rates:
    local defecateBaseRate = 3.5

    -- Apply multipliers
    local defecateIncrease = defecateBaseRate * SandboxVars.BF.BowelsIncreaseMultiplier * finalBowelMultiplier

    -- Update value
    defecateValue = defecateValue + defecateIncrease
    player:getModData().defecateValue = tonumber(defecateValue)
end

-- =====================================================
-- EVENT REGISTRATION
-- =====================================================

function BF_Defecation.TriggerToiletDefecate(object, player, isWiping, wipeType, wipeItem, wipeEfficiency)
    local player = getPlayer()
    local defecateValue = BF.GetDefecateValue()
    local requirement = SandboxVars.BF.PoopInToiletRequirement or 40
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100
    local hasShyBowels = player:HasTrait("ShyBowels")
    local isBeingWatched = BF.IsBeingWatched(player)

    if defecateValue < (requirement / 100) * bowelsMaxValue or (hasShyBowels and isBeingWatched) then
        return
    end

    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, object))
    ISTimedActionQueue.add(ToiletDefecate:new(player, defecateValue * 2, true, true, object))

    if isWiping then
        ISTimedActionQueue.add(WipeSelf:new(player, 20, wipeType, wipeItem, "poop"))
    end
end
function BF_Defecation.TriggerGroundDefecate(isWiping, wipeType, wipeItem, wipeEfficiency)
    local player = getPlayer()
    local defecateValue = BF.GetDefecateValue()
    local poopTime = defecateValue * 2

    ISTimedActionQueue.add(GroundDefecate:new(player, poopTime, true, true))

    if isWiping then
        ISTimedActionQueue.add(WipeSelf:new(player, 20, wipeType, wipeItem, "poop"))
    end
end
function BF_Defecation.PoopInContainer(item)
end