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


-- Function to apply effects when the player has defecated in their clothing
function BathroomFunctions.DefecateBottoms(leakTriggered)
    local player = getPlayer()
    local modOptions = PZAPI.ModOptions:getOptions("BathroomFunctions")
    local bodyLocations = BathroomFunctions.GetSoilableClothing()
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Default max value for bowels

    -- For leak events, only 5% of the normal defecate value is applied.
    local leakMultiplier = leakTriggered and 0.05 or 1.0

    -- Track the maximum pooped severity across all clothing pieces.
    local maxPoopedSeverity = 0
    
    -- Flag to decide if a poop object should be created
    local showPoopObject = false

    -- Process each clothing item.
    for i = 1, #bodyLocations do
        local clothing = player:getWornItem(bodyLocations[i])
        if clothing then
            local modData = clothing:getModData()

            -- Ensure 'poopedSeverity' is initialized.
            if modData.poopedSeverity == nil then
                modData.poopedSeverity = 0
            end

            -- Get the defecate value as a percentage of the maximum, then apply the multiplier.
            local defecateValue = BathroomFunctions.GetDefecateValue()
            local defecatePercentage = (defecateValue / bowelsMaxValue) * 100
            defecatePercentage = defecatePercentage * leakMultiplier

            -- Mark the clothing as soiled by feces and update severity.
            modData.pooped = true
            modData.poopedSeverity = modData.poopedSeverity + defecatePercentage

            -- Cap the severity at 100.
            if modData.poopedSeverity >= 100 then
                modData.poopedSeverity = 100
            end

            -- Track the highest pooped severity.
            if modData.poopedSeverity > maxPoopedSeverity then
                maxPoopedSeverity = modData.poopedSeverity
            end
            
            -- Only equip the poop overlay if:
            -- • Not a leak event, OR
            -- • A leak event but this clothing's pooped severity reached at least 25.
            if SandboxVars.BathroomFunctions.VisiblePoopStain == true then
                if (not leakTriggered) or (leakTriggered and modData.poopedSeverity >= 25) then
                    BathroomClothOverlays.equipPoopedOverlay(player, clothing)
                    print("Should have equipped poop overlay")
                end
            end

            -- Update the clothing item's condition.
            BathroomFunctions.SetClothing(clothing, leakTriggered)
            BathroomFunctions.UpdateSoiledSeverity(clothing)
        end
    end


    -- Play the defecation sound and update player visuals.
    player:playerVoiceSound("JumpLow")
    
    -- Have the player speak a message based on the leak status.
    if leakTriggered then
        player:Say(getText("IGUI_announce_SilentOops"))
    else
        getSoundManager():PlayWorldSound("BF_PoopSelf1", player:getCurrentSquare(), 0, 10, 0.05, false)
        local playerSayStatus = modOptions:getOption("6")
        if playerSayStatus:getValue(1) then
            player:Say(getText("IGUI_announce_IPoopedMyself"))
        end
    end

    

    -- Apply dirt to the player's body, reduced based on leak conditions.
    local dirtMultiplier = leakTriggered and 0.05 or 1.0
    player:addDirt(BloodBodyPartType.Groin, ZombRand(4, 10) * dirtMultiplier, false)
    player:addDirt(BloodBodyPartType.UpperLeg_L, ZombRand(4, 10) * dirtMultiplier, false)
    player:addDirt(BloodBodyPartType.UpperLeg_R, ZombRand(4, 10) * dirtMultiplier, false)

    player:getVisual():setDirt(BloodBodyPartType.Groin, ZombRand(4, 10) * dirtMultiplier)
    player:getVisual():setDirt(BloodBodyPartType.UpperLeg_L, ZombRand(4, 10) * dirtMultiplier)
    player:getVisual():setDirt(BloodBodyPartType.UpperLeg_R, ZombRand(4, 10) * dirtMultiplier)

    
end