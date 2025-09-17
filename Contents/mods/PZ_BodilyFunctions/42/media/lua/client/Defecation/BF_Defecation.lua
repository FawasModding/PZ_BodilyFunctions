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

-- Function to apply effects when the player has defecated (no clothing logic)
function BF_Defecation.DefecateBottoms(leakTriggered)
    local player = getPlayer()
    local modOptions = PZAPI.ModOptions:getOptions("BF")

    -- Sound and dialogue
    player:playerVoiceSound("JumpLow")
    if leakTriggered then
        player:Say(getText("IGUI_announce_SilentOops"))
    else
        getSoundManager():PlayWorldSound("BF_Poop_Self_Light", player:getCurrentSquare(), 0, 10, 0.05, false)
        local playerSayStatus = modOptions:getOption("6")
        if playerSayStatus:getValue(1) then
            player:Say(getText("IGUI_announce_IPoopedMyself"))
        end
    end
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
function BF_Defecation.TriggerSelfDefecate(isLeak)
    local isLeak = isLeak or false
    local player = getPlayer()
    local defecateValue = BF.GetDefecateValue()
    local poopTime = defecateValue / 4

    -- Just trigger bottoms effect (no clothing checks)
    BF_Defecation.DefecateBottoms(isLeak)

    -- Timed action
    ISTimedActionQueue.add(SelfDefecate:new(player, poopTime, false, false, true, false, nil, isLeak))

    print("Updated Pooped Self Value: " .. BF.GetPoopedSelfValue())
    if isLeak then
        print("Leak triggered: Updated Pooped Self Value: " .. BF.GetPoopedSelfValue())
    end
end
function BF_Defecation.PoopInContainer(item)
end