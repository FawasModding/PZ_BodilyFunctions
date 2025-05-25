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



-- Function to apply effects when the player has urinated in their clothing
-- Modified UrinateBottoms takes an optional parameter "leakTriggered"
function BathroomFunctions.UrinateBottoms(leakTriggered)
    local player = getPlayer()
    local modOptions = PZAPI.ModOptions:getOptions("BathroomFunctions")
    local bodyLocations = BathroomFunctions.GetSoilableClothing()

    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100
    -- For leak events, only 5% of the normal urine value is applied.
    local leakMultiplier = leakTriggered and 0.05 or 1.0

    -- Flags to decide later if a pee object should be created and to determine unhappiness change.
    local showPeeObject = false
    local maxPeeSeverity = 0

    -- Process each clothing item.
    for i = 1, #bodyLocations do
        local clothing = player:getWornItem(bodyLocations[i])
        if clothing then
            local modData = clothing:getModData()

            if modData.peedSeverity == nil then
                modData.peedSeverity = 0
            end

            local peeValue = BathroomFunctions.GetUrinateValue()
            local urinatePercentage = (peeValue / bladderMaxValue) * 100
            urinatePercentage = urinatePercentage * leakMultiplier

            -- Mark this clothing item as soiled by urine.
            modData.peed = true
            modData.peedSeverity = modData.peedSeverity + urinatePercentage

            if modData.peedSeverity >= 100 then
                modData.peedSeverity = 100
            end

            -- Keep track of the highest peed severity among clothing pieces.
            if modData.peedSeverity > maxPeeSeverity then
                maxPeeSeverity = modData.peedSeverity
            end

            -- Only equip the pee overlay if:
            --   • Not a leak event, OR
            --   • A leak event but this clothing's peed severity reached at least 25.
            if SandboxVars.BathroomFunctions.VisiblePeeStain == true then
                if (not leakTriggered) or (leakTriggered and modData.peedSeverity >= 25) then
                    BathroomClothOverlays.equipPeedOverlay(player, clothing)
                    print("Should have equipped pee overlay")
                end
            end

            -- Mark that the pee object should be created if this clothing meets the threshold.
            if modData.peedSeverity >= 90 then
                showPeeObject = true
            end

            BathroomFunctions.SetClothing(clothing, leakTriggered)
            BathroomFunctions.UpdateSoiledSeverity(clothing)
        end
    end

    -- Only create the pee object if:
    --   • Not a leak event, OR
    --   • A leak event and at least one clothing item has a peed severity >= 25.
    if SandboxVars.BathroomFunctions.CreatePeeObject == true then
        if (not leakTriggered) or (leakTriggered and showPeeObject) then
            local urineItem = instanceItem("BathroomFunctions.Urine_Hydrated_0")
            player:getCurrentSquare():AddWorldInventoryItem(urineItem, 0, 0, 0)
        end
    end

    player:playerVoiceSound("SighBored")

    if leakTriggered then
        player:Say(getText("IGUI_announce_SilentOops"))
    else
        -- Keep sound for full accidents (non-leak events)
        getSoundManager():PlayWorldSound("BF_PeeSelf", player:getCurrentSquare(), 0, 10, 0.2, false)
        local playerSayStatus = modOptions:getOption("6")
        if playerSayStatus:getValue(1) then
            player:Say(getText("IGUI_announce_IPeedMyself"))
        end
        
    end

end