-- Function to update defecation-related values
function BF.UpdateDefecationValues()
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
    local baseBowelsMax  = BF.GetMaxBowelValue()

    -- Retrieve the current fill values.
    local defecateValue = BF.GetDefecateValue()
    
    -- Base Increase Rates:
    local defecateBaseRate = 3.5  -- Base bowel fill per 10-minute tick

    -- Apply the appropriate multipliers for the next tick.
    -- (These multipliers get applied for the whole 10-minute interval.)
    local defecateIncrease = defecateBaseRate * SandboxVars.BF.BowelsIncreaseMultiplier * finalBowelMultiplier

    -- Update the fill values.
    defecateValue = defecateValue + defecateIncrease

    player:getModData().defecateValue = tonumber(defecateValue)

    -- Calculate the current percentages for debugging/triggering events.
    local defecatePercent = (defecateValue / baseBowelsMax) * 100

    print("Updated Defecate Value: " .. tostring(defecatePercent) .. "% (Effective Max: " .. baseBowelsMax .. ")")
end

-- Function to apply effects when the player has defecated in their clothing
function BF.DefecateBottoms(leakTriggered)
    local player = getPlayer()
    local modOptions = PZAPI.ModOptions:getOptions("BF")
    local bowelsMaxValue = BF.GetMaxBowelValue()
    local leakMultiplier = leakTriggered and 0.05 or 1.0
    local defecateValue = BF.GetDefecateValue()
    local defecatePercentage = (defecateValue / bowelsMaxValue) * 100 * leakMultiplier
    
    local showPoopObject = false
    local maxPoopedSeverity = 0

    -- Get soilable clothing locations
    local underwearLocations = {"UnderwearBottom", "Underwear"}
    local outerwearLocations = BF_ClothingConfig.soilableLocations
    for i = #outerwearLocations, 1, -1 do
        if outerwearLocations[i] == "UnderwearBottom" or outerwearLocations[i] == "Underwear" then
            table.remove(outerwearLocations, i)
        end
    end

    -- Step 1: Process underwear first
    local underwear = nil
    for _, loc in ipairs(underwearLocations) do
        local item = player:getWornItem(loc)
        if item and (BF_Utils.tableContains(BF_ClothingConfig.clothingModels.MaleUnderwear.types, item:getType()) or
                     BF_Utils.tableContains(BF_ClothingConfig.clothingModels.FemaleUnderwear.types, item:getType())) then
            underwear = item
            break
        end
    end

    -- Step 2: Process outer garments (pants, shorts, etc.)
    local pants = nil
    for _, loc in ipairs(outerwearLocations) do
        local item = player:getWornItem(loc)
        if item then -- Accept any item in outerwear locations
            pants = item
            break
        end
    end

    -- Step 3: Distribute poop severity (underwear first, then pants)
    local remainingDefecatePercentage = defecatePercentage
    
    if underwear then
        local modData = underwear:getModData()
        modData.pooped = true
        modData.poopedSeverity = (modData.poopedSeverity or 0) + remainingDefecatePercentage

        -- Cap severity at 100 and calculate spillover
        if modData.poopedSeverity > 100 then
            remainingDefecatePercentage = modData.poopedSeverity - 100
            modData.poopedSeverity = 100
        else
            remainingDefecatePercentage = 0
        end

        -- Update tooltip
        modData.tooltip = "Soiled (Feces): " .. math.floor(modData.poopedSeverity) .. "%"
        maxPoopedSeverity = math.max(maxPoopedSeverity, modData.poopedSeverity)

        -- Apply overlay if severity meets threshold
        if SandboxVars.BF.VisiblePoopStain and (not leakTriggered or modData.poopedSeverity >= 25) then
            BF_ClothingOverlays.equipOverlay(player, underwear, "pooped", "PoopedOverlay_Underwear")
        end

        -- Update clothing properties
        BF.SetClothing(underwear, leakTriggered)
        BF.UpdateSoiledSeverity(underwear)

        if modData.poopedSeverity >= 90 then showPoopObject = true end
    end

    -- Step 4: Apply remaining severity to pants if applicable
    if pants and (remainingDefecatePercentage > 0 or defecatePercentage >= 50) then
        local modData = pants:getModData()
        modData.pooped = true

        -- Apply reduced spillover (50% of remaining) for realism
        local pantsSeverity = remainingDefecatePercentage > 0 and (remainingDefecatePercentage * 0.5) or (defecatePercentage * 0.25)
        modData.poopedSeverity = (modData.poopedSeverity or 0) + pantsSeverity

        -- Cap severity at 100
        if modData.poopedSeverity > 100 then modData.poopedSeverity = 100 end

        -- Update tooltip
        modData.tooltip = "Soiled (Feces): " .. math.floor(modData.poopedSeverity) .. "%"
        maxPoopedSeverity = math.max(maxPoopedSeverity, modData.poopedSeverity)

        -- Apply overlay if severity meets threshold
        if SandboxVars.BF.VisiblePoopStain and (not leakTriggered or modData.poopedSeverity >= 25) then
            BF_ClothingOverlays.equipOverlay(player, pants, "pooped", "PoopedOverlay_Pants")
        end

        -- Update clothing properties
        BF.SetClothing(pants, leakTriggered)
        BF.UpdateSoiledSeverity(pants)

        if modData.poopedSeverity >= 90 then showPoopObject = true end
    end

    -- Step 6: Apply sound and dialogue
    player:playerVoiceSound("JumpLow")
    if leakTriggered then
        player:Say(getText("IGUI_announce_SilentOops"))
    else
        getSoundManager():PlayWorldSound("BF_PoopSelf1", player:getCurrentSquare(), 0, 10, 0.05, false)
        local playerSayStatus = modOptions:getOption("6")
        if playerSayStatus:getValue(1) then
            player:Say(getText("IGUI_announce_IPoopedMyself"))
        end
    end
end