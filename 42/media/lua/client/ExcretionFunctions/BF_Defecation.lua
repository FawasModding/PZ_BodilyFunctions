-- Function to update defecation-related values
function BathroomFunctions.UpdateDefecationValues()
    local player = getPlayer()

    -- Get player stats
    local thirst = player:getStats():getThirst()
    local hunger = player:getStats():getHunger()
    local stress = player:getStats():getStress()
    local endurance = player:getStats():getEndurance()

    -- Calculate bowel multiplier where:
    -- - At hunger 0 (fully sationed): multiplier = 1.0 (standard rate)
    -- - At hunger 1 (Starving): multiplier = 0.3 (30% of standard rate)
    local bowelMultiplier = 1.0 - (hunger * 0.7)

    -- Add stress effect: increased urgency when stressed
    local stressEffect = stress * 0.3  -- Up to 30% increase when fully stressed

    -- Simulate body needing nutrients to recover
    local urgencyFactor = (1.0 - endurance) * 0.1
    
    -- Add random variation for a more realistic feel
    local randomBowelFactor = 0.9 + (ZombRand(21) / 100)   -- Range: 0.9 to 1.1

    -- Calculate your base multiplier from player stats
    local finalBowelMultiplier = bowelMultiplier + stressEffect + urgencyFactor
    -- Then apply the random variation as a multiplier
    finalBowelMultiplier = finalBowelMultiplier * randomBowelFactor

    print("Hunger level: " .. tostring(hunger))
    print("Bowel multiplier: " .. tostring(bowelMultiplier))
    print("Final bowel multiplier: " .. tostring(finalBowelMultiplier))

    -- Retrieve the base maximum capacities (from SandboxVars or defaults).
    local baseBladderMax = SandboxVars.BathroomFunctions.BladderMaxValue or 600
    local baseBowelsMax  = SandboxVars.BathroomFunctions.BowelsMaxValue or 500

    -- Retrieve the current fill values.
    local defecateValue = BathroomFunctions.GetDefecateValue()

    -- Base Increase Rates:
    local defecateBaseRate = 3.5  -- Base bowel fill per 10-minute tick

    -- Apply the appropriate multipliers for the next tick.
    -- (These multipliers get applied for the whole 10-minute interval.)
    local defecateIncrease = defecateBaseRate * SandboxVars.BathroomFunctions.BowelsIncreaseMultiplier * finalBowelMultiplier

    -- Update the fill values.
    defecateValue = defecateValue + defecateIncrease

    player:getModData().defecateValue = tonumber(defecateValue)

    -- Calculate the current percentages for debugging/triggering events.
    local defecatePercent = (defecateValue / baseBowelsMax) * 100

    print("Updated Defecate Value: " .. tostring(defecatePercent) .. "% (Effective Max: " .. baseBowelsMax .. ")")
end