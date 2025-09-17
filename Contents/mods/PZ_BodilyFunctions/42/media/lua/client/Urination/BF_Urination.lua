require "BodilyFunctions"

BF_Urination = BF_Urination or {}

function BF_Urination.GlobalFunctionTimers()
    BF_Urination.UpdateUrinationValues()
end

-- Function to update urination-related values
function BF_Urination.UpdateUrinationValues()
    local player = getPlayer()

    -- Get player stats
    local thirst = player:getStats():getThirst()
    local hunger = player:getStats():getHunger()
    local stress = player:getStats():getStress()
    local endurance = player:getStats():getEndurance()

    -- Calculate bladder multiplier
    local bladderMultiplier = 1.0 - (thirst * 0.7)
    local stressEffect = stress * 0.3
    local urgencyFactor = (1.0 - endurance) * 0.1
    local randomBladderFactor = 0.9 + (ZombRand(21) / 100)

    local finalBladderMultiplier = (bladderMultiplier + stressEffect + urgencyFactor) * randomBladderFactor

    -- Base maximum capacity
    local baseBladderMax = SandboxVars.BathroomFunctions.BladderMaxValue or 600

    -- Current value
    local urinateValue = BF.GetUrinateValue()

    -- Base increase per tick
    local urinateBaseRate = 10
    local urinateIncrease = urinateBaseRate * SandboxVars.BF.BladderIncreaseMultiplier * finalBladderMultiplier

    urinateValue = urinateValue + urinateIncrease
    player:getModData().urinateValue = tonumber(urinateValue)

    -- Muscle strain thresholds
    local muscleStrainAmount = 0
    if urinateValue >= 0.95 * baseBladderMax then
        muscleStrainAmount = 90
    elseif urinateValue >= 0.90 * baseBladderMax then
        muscleStrainAmount = 75
    elseif urinateValue >= 0.75 * baseBladderMax then
        muscleStrainAmount = 60
    elseif urinateValue >= 0.60 * baseBladderMax then
        muscleStrainAmount = 10
    end

    if muscleStrainAmount > 0 then
        BF.PainInBladder(player, muscleStrainAmount)
        print("Bladder pain applied: " .. muscleStrainAmount .. " (Urinate Value: " .. urinateValue .. "/" .. baseBladderMax .. ")")
    end

    local urinatePercent = (urinateValue / baseBladderMax) * 100
    print("Updated Urinate Value: " .. tostring(urinatePercent) .. "% (Effective Max: " .. baseBladderMax .. ")")
end

-- Function to apply effects when the player has urinated (no clothing logic)
function BF_Urination.UrinateBottoms(leakTriggered)
    local player = getPlayer()

    -- Optionally create a pee object
    if SandboxVars.BF.CreatePeeObject and not player:isAsleep() then
        local urineItem = instanceItem("BF.Urine_Hydrated_0")
        player:getCurrentSquare():AddWorldInventoryItem(urineItem, 0, 0, 0)
    end

    -- Sound and dialogue
    player:playerVoiceSound("SighBored")
    if leakTriggered then
        player:Say(getText("IGUI_announce_SilentOops"))
    else
        getSoundManager():PlayWorldSound("BF_Pee_Self", player:getCurrentSquare(), 0, 10, 0.2, false)
        local modOptions = PZAPI.ModOptions:getOptions("BF")
        local playerSayStatus = modOptions:getOption("6")
        if playerSayStatus:getValue(1) then
            player:Say(getText("IGUI_announce_IPeedMyself"))
        end
    end
end

-- =====================================================
-- EVENT REGISTRATION
-- =====================================================

function BF_Urination.TriggerToiletUrinate(object, player)
    local player = getPlayer()
    local urinateValue = BF.GetUrinateValue()
    local requirement = SandboxVars.BF.PeeInToiletRequirement or 40
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100
    local hasShyBladder = player:HasTrait("ShyBladder")
    local isBeingWatched = BF.IsBeingWatched(player)

    if urinateValue < (requirement / 100) * bladderMaxValue then return end
    if hasShyBladder and isBeingWatched then return end

    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, object))
    ISTimedActionQueue.add(ToiletUrinate:new(player, urinateValue, true, true, object))
end
function BF_Urination.TriggerGroundUrinate()
    local player = getPlayer()
    local urinateValue = BF.GetUrinateValue()
    local peeTime = urinateValue

    -- Urinate on the ground
    ISTimedActionQueue.add(GroundUrinate:new(player, peeTime, true, true))
end
function BF_Urination.TriggerSelfUrinate(isLeak)
    local isLeak = isLeak or false
    local player = getPlayer()
    local urinateValue = BF.GetUrinateValue()
    local peeTime = urinateValue / 4

    -- Just apply bottoms effect (no clothing checks)
    BF_Urination.UrinateBottoms(isLeak)

    -- Timed action
    ISTimedActionQueue.add(SelfUrinate:new(player, peeTime, false, false, true, false, nil, isLeak))

    if isLeak then
        print("Leak triggered: Updated Peed Self Value: " .. BF.GetPeedSelfValue())
    else
        print("Updated Peed Self Value: " .. BF.GetPeedSelfValue())
    end
end
function BF_Urination.PeeInContainer(item)
    local fluidContainer = item:getFluidContainer()
    local containerCapacity = fluidContainer:getCapacity() * 1000
    local bladderUrine = BF.GetUrinateValue()

    local amountToFill = math.min(containerCapacity, bladderUrine)

    fluidContainer:addFluid("Urine", amountToFill)
    BF.SetUrinateValue(bladderUrine - amountToFill)
end
