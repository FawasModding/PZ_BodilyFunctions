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
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100
    local leakMultiplier = leakTriggered and 0.05 or 1.0
    local peeValue = BathroomFunctions.GetUrinateValue()
    local urinatePercentage = (peeValue / bladderMaxValue) * 100 * leakMultiplier

    local showPeeObject = false
    local maxPeeSeverity = 0

    -- Get soilable clothing locations
    local underwearLocations = {"UnderwearBottom", "Underwear"}
    local outerwearLocations = BathroomFunctions.GetSoilableClothing() -- Use all soilable locations
    -- Remove underwear locations to avoid duplicate processing
    for i = #outerwearLocations, 1, -1 do
        if outerwearLocations[i] == "UnderwearBottom" or outerwearLocations[i] == "Underwear" then
            table.remove(outerwearLocations, i)
        end
    end

    -- Step 1: Process underwear first
    local underwear = nil
    for i = 1, #underwearLocations do
        local item = player:getWornItem(underwearLocations[i])
        if item and (table.contains(BathroomClothOverlays.peedModelsMaleBoxers, item:getType()) or
                     table.contains(BathroomClothOverlays.peedModelsFemalePanties, item:getType())) then
            underwear = item
            break
        end
    end

    -- Step 2: Process outer garments (pants, suits, etc.)
    local pants = nil
    for i = 1, #outerwearLocations do
        local item = player:getWornItem(outerwearLocations[i])
        if item then
            pants = item
            break
        end
    end

    -- Step 3: Distribute pee severity (underwear first, then pants)
    local remainingUrinatePercentage = urinatePercentage

    if underwear then
        local modData = underwear:getModData()
        modData.peed = true
        modData.peedSeverity = (modData.peedSeverity or 0) + remainingUrinatePercentage

        -- Cap severity at 100 and calculate spillover
        if modData.peedSeverity > 100 then
            remainingUrinatePercentage = modData.peedSeverity - 100
            modData.peedSeverity = 100
        else
            remainingUrinatePercentage = 0
        end

        -- Update tooltip
        modData.tooltip = "Soiled (Urine): " .. math.floor(modData.peedSeverity) .. "%"
        maxPeeSeverity = math.max(maxPeeSeverity, modData.peedSeverity)

        -- Apply overlay if severity meets threshold
        if SandboxVars.BathroomFunctions.VisiblePeeStain and (not leakTriggered or modData.peedSeverity >= 25) then
            BathroomClothOverlays.equipPeedOverlay(player, underwear, "PeedOverlay_Underwear")
            print("Equipped pee overlay for underwear: " .. underwear:getType())
        end

        -- Update clothing properties
        BathroomFunctions.SetClothing(underwear, leakTriggered)
        BathroomFunctions.UpdateSoiledSeverity(underwear)

        if modData.peedSeverity >= 90 then
            showPeeObject = true
        end
    end

    -- Step 4: Apply remaining severity to pants if applicable
    if pants and (remainingUrinatePercentage > 0 or urinatePercentage >= 50) then
        local modData = pants:getModData()
        modData.peed = true
        -- Apply spillover or partial severity for realism
        local pantsSeverity = remainingUrinatePercentage > 0 and remainingUrinatePercentage or urinatePercentage * 0.5
        modData.peedSeverity = (modData.peedSeverity or 0) + pantsSeverity

        -- Cap severity at 100
        if modData.peedSeverity > 100 then
            modData.peedSeverity = 100
        end

        -- Update tooltip
        modData.tooltip = "Soiled (Urine): " .. math.floor(modData.peedSeverity) .. "%"
        maxPeeSeverity = math.max(maxPeeSeverity, modData.peedSeverity)

        -- Apply overlay if severity meets threshold
        if SandboxVars.BathroomFunctions.VisiblePeeStain and (not leakTriggered or modData.peedSeverity >= 25) then
            BathroomClothOverlays.equipPeedOverlay(player, pants, "PeedOverlay_Pants")
            print("Equipped pee overlay for pants: " .. pants:getType())
        end

        -- Update clothing properties
        BathroomFunctions.SetClothing(pants, leakTriggered)
        BathroomFunctions.UpdateSoiledSeverity(pants)

        if modData.peedSeverity >= 90 then
            showPeeObject = true
        end
    end

    -- Step 5: Create pee object if conditions are met
    if SandboxVars.BathroomFunctions.CreatePeeObject and 
    (not leakTriggered or showPeeObject) and 
    not player:isAsleep() and 
    not player:isInBed() then

        local urineItem = instanceItem("BathroomFunctions.Urine_Hydrated_0")
        player:getCurrentSquare():AddWorldInventoryItem(urineItem, 0, 0, 0)
    end

    -- Step 6: Apply sound and dialogue
    player:playerVoiceSound("SighBored")
    if leakTriggered then
        player:Say(getText("IGUI_announce_SilentOops"))
    else
        getSoundManager():PlayWorldSound("BF_PeeSelf", player:getCurrentSquare(), 0, 10, 0.2, false)
        local playerSayStatus = modOptions:getOption("6")
        if playerSayStatus:getValue(1) then
            player:Say(getText("IGUI_announce_IPeedMyself"))
        end
    end
end