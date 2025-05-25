-- Function to update urination-related values
function BathroomFunctions.UpdateUrinationValues()

    local player = getPlayer()

    -- Get player stats
    local thirst = player:getStats():getThirst()
    local hunger = player:getStats():getHunger()
    local stress = player:getStats():getStress()
    local endurance = player:getStats():getEndurance()

    -- Calculate bladder multiplier where:
    -- - At thirst 0 (fully hydrated): multiplier = 1.0 (standard rate)
    -- - At thirst 1 (dehydrated): multiplier = 0.3 (30% of standard rate)
    local bladderMultiplier = 1.0 - (thirst * 0.7)

    -- Add stress effect: increased urgency when stressed
    local stressEffect = stress * 0.3  -- Up to 30% increase when fully stressed

    -- Simulate body needing nutrients to recover
    local urgencyFactor = (1.0 - endurance) * 0.1
    
    -- Add random variation for a more realistic feel
    local randomBladderFactor = 0.9 + (ZombRand(21) / 100) -- Range: 0.9 to 1.1

    -- Calculate your base multiplier from player stats
    local finalBladderMultiplier = bladderMultiplier + stressEffect + urgencyFactor
    -- Then apply the random variation as a multiplier
    finalBladderMultiplier = finalBladderMultiplier * randomBladderFactor

    print("Thirst level: " .. tostring(thirst))
    print("Bladder multiplier: " .. tostring(bladderMultiplier))
    print("Final bladder multiplier: " .. tostring(finalBladderMultiplier))

    -- Retrieve the base maximum capacities (from SandboxVars or defaults).
    local baseBladderMax = SandboxVars.BathroomFunctions.BladderMaxValue or 600

    -- Retrieve the current fill values.
    local urinateValue = BathroomFunctions.GetUrinateValue()
   
    -- Base Increase Rates:
    local urinateBaseRate = 10    -- Base bladder fill per 10-minute tick

    -- Apply the appropriate multipliers for the next tick.
    -- (These multipliers get applied for the whole 10-minute interval.)
    local urinateIncrease = urinateBaseRate * SandboxVars.BathroomFunctions.BladderIncreaseMultiplier * finalBladderMultiplier

    -- Update the fill values.
    urinateValue = urinateValue + urinateIncrease

    player:getModData().urinateValue = tonumber(urinateValue)

    -- Calculate the current percentages for debugging/triggering events.
    local urinatePercent = (urinateValue / baseBladderMax) * 100

    print("Updated Urinate Value: " .. tostring(urinatePercent) .. "% (Effective Max: " .. baseBladderMax .. ")")
end