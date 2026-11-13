require "BodilyFunctions"

-- How long a defecation action takes, after the sandbox multiplier. A timed action
-- needs at least one tick, so a multiplier of 0 means as fast as possible.
function BF.GetDefecateTime(baseTime)
    return math.max(1, baseTime * (SandboxVars.BF.DefecateSpeedMultiplier or 1))
end

-- Food sickness above this (on the stat's 0-100 scale) brings on diarrhea.
BF.DiarrheaSicknessThreshold = 25

-- Bowel fill multiplier from diarrhea: 1 when healthy, about x3 at Nauseous (50),
-- x5 at the worst.
function BF.GetDiarrheaMultiplier(player)
    if SandboxVars.BF.EnableDiarrhea == false then return 1 end
    local sickness = player:getStats():get(CharacterStat.FOOD_SICKNESS)
    if sickness <= BF.DiarrheaSicknessThreshold then return 1 end
    return 1 + sickness / BF.DiarrheaSicknessThreshold
end

-- Update defecation values
function BF.UpdateDefecationValues(player)
    player = player or getPlayer()

    -- Get player stats
    local thirst = player:getStats():get(CharacterStat.THIRST)
    local hunger = player:getStats():get(CharacterStat.HUNGER)
    local stress = player:getStats():get(CharacterStat.STRESS)
    local endurance = player:getStats():get(CharacterStat.ENDURANCE)

    -- Calculate bowel multiplier where:
    -- - At hunger 0 (fully satisfied): multiplier = 1.0
    -- - At hunger 1 (starving): multiplier = 0.3 (need to poop 30% less when hungry)
    local bowelMultiplier = 1.0 - (hunger * 0.7)

    -- Increased urgency when stressed
    local stressEffect = stress * 0.3  -- Up to 30% increase when fully stressed

    -- Simulate body needing nutrients to recover
    local urgencyFactor = (1.0 - endurance) * 0.1
    
    -- Add random variation for a more realistic feel
    local randomBowelFactor = 0.9 + (ZombRand(21) / 100)   -- Range: 0.9 to 1.1

    -- Calculate base multiplier from player stats
    local finalBowelMultiplier = bowelMultiplier + stressEffect + urgencyFactor

    -- Multiply random variation with final multiplier
    finalBowelMultiplier = finalBowelMultiplier * randomBowelFactor * BF.GetDiarrheaMultiplier(player)

    -- Get base max capacities (from SandboxVars or defaults).
    local baseBowelsMax  = BF.GetBowelCapacity(player) -- mL this character holds

    -- Get the current fill values.
    local defecateValue = BF.GetDefecateValue(player)
    
    -- Base Increase Rate:
    local defecateBaseIncreaseRate = 3.5  -- Base bowel fill per 10-minute tick

    -- New bowel value = old bowel value + (3.5 * sandbox multiplier * hunger/stress/endurance/random multiplier)
    local defecateIncrease = defecateBaseIncreaseRate * SandboxVars.BF.BowelsIncreaseMultiplier * finalBowelMultiplier

    -- Update the fill values! With defecation off the bowels stay empty. The cap
    -- matters when accidents are off, since nothing else stops it from climbing.
    if BF.IsDefecationEnabled() then
        defecateValue = math.min(defecateValue + defecateIncrease, baseBowelsMax)
    else
        defecateValue = 0
    end

    player:getModData().defecateValue = tonumber(defecateValue)

    -- Calculate the current percentages for debugging/triggering events.
    local defecatePercent = (defecateValue / baseBowelsMax) * 100

    --print("Updated Defecate Value: " .. tostring(defecatePercent) .. "% (Effective Max: " .. baseBowelsMax .. ")")
end

-- Effects when player's wearing pooped clothing
function BF.DefecateBottoms(player, leakTriggered)
    player = player or getPlayer()
    local modOptions = PZAPI.ModOptions:getOptions("BF")
    local bowelsMaxValue = BF.GetBowelCapacity(player)
    local leakMultiplier = leakTriggered and 0.05 or 1.0
    local defecateValue = BF.GetDefecateValue(player)
    local defecatePercentage = (defecateValue / bowelsMaxValue) * 100 * leakMultiplier
    
    local showPoopObject = false
    local maxPoopedSeverity = 0

    -- Get soilable clothing locations
    local underwearLocations = {
        ItemBodyLocation.UNDERWEAR_BOTTOM,
        ItemBodyLocation.UNDERWEAR
    }
    local outerwearLocations = BF.GetSoilableClothing()
    for i = #outerwearLocations, 1, -1 do
        if outerwearLocations[i] == ItemBodyLocation.UNDERWEAR_BOTTOM or outerwearLocations[i] == ItemBodyLocation.UNDERWEAR then
            table.remove(outerwearLocations, i)
        end
    end

    -- Step 1: Process underwear first
    local underwear = nil
    for _, loc in ipairs(underwearLocations) do
        local item = player:getWornItem(loc)
        if item and (BF_Utils.tableContains(BF_Overlays.clothingModels.MaleUnderwear.types, item:getType()) or
                     BF_Utils.tableContains(BF_Overlays.clothingModels.FemaleUnderwear.types, item:getType())) then
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
            BF_Overlays.ApplyOverlayToSlot(player, underwear, "pooped", BFBodyLocations.PoopedOverlay_Underwear)
        end

        -- Update clothing properties
        BF.ApplySoilingEffects(underwear, leakTriggered)
        BF.RefreshSoiledSeverityFromModData(underwear, player)

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
            BF_Overlays.ApplyOverlayToSlot(player, pants, "pooped", BFBodyLocations.PoopedOverlay_Pants)
        end

        -- Update clothing properties
        BF.ApplySoilingEffects(pants, leakTriggered)
        BF.RefreshSoiledSeverityFromModData(pants, player)

        if modData.poopedSeverity >= 90 then showPoopObject = true end
    end

    -- Step 6: Apply sound and dialogue
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
--
-- EVENT REGISTRATION
--
-- =====================================================

-- BF.WalkThenRelief, BF.CanSitOnObject and BF.StandUpAfterToilet are in BF_Urination.lua.

function BF.TriggerToiletDefecate(object, player, isWiping, wipeType, wipeItem, wipeEfficiency, pooledTypes)
    player = player or getPlayer()
    local defecateValue = BF.GetDefecateValue(player)
    local requirement = SandboxVars.BF.PoopInToiletRequirement or 40
    local bowelsMaxValue = BF.GetBowelCapacity(player)
    local hasShyBowels = BF.HasTrait(player, BFTraits.ShyBowels)
    local isBeingWatched = BF.IsBeingWatched(player)

    if defecateValue < (requirement / 100) * bowelsMaxValue or (hasShyBowels and isBeingWatched) then
        return
    end

    -- Walk to the toilet using the vanilla furniture-sitting pathfinder, then
    -- run the relief action once the character has arrived and is seated.
    BF.WalkThenRelief(player, object, BF.CanSitOnObject(object), function(goalObject, seated)
        ISTimedActionQueue.add(ToiletDefecate:new(player, BF.GetDefecateTime(defecateValue * 2), true, true, goalObject, seated))

        if isWiping then
            ISTimedActionQueue.add(WipeSelf:new(player, 20, wipeType, wipeItem, "poop", pooledTypes))
        else
            -- Apply 5% soiling penalty to worn clothing if not wiping
            local soilableClothing = BF.GetSoilableClothing()
            for _, bodyLocation in ipairs(soilableClothing) do
                local clothingItem = player:getWornItem(bodyLocation)
                if clothingItem then
                    local modData = clothingItem:getModData()
                    modData.pooped = true
                    modData.poopedSeverity = (modData.poopedSeverity or 0) + 5
                    modData.poopedSeverity = math.min(modData.poopedSeverity, 100)
                end
            end
            BF.ResetRemovedClothing(player)
        end
        if seated then
            BF.StandUpAfterToilet(player)
        end
    end, function()
        BF.RemoveBottomClothing(player)
    end)
end

-- Standing/crouching defecation at a non-sittable, non-oriented fixture
-- (bush, water, trash can, dumpster). Mirrors GroundDefecate's squat, but
-- spawns no waste object since it's going into the fixture, and applies no
-- facing logic since these objects have no orientation.
function BF.TriggerFixtureDefecate(object, player, isWiping, wipeType, wipeItem, wipeEfficiency, pooledTypes)
    player = player or getPlayer()
    local defecateValue = BF.GetDefecateValue(player)
    local requirement = SandboxVars.BF.PoopInToiletRequirement or 40
    local bowelsMaxValue = BF.GetBowelCapacity(player)
    local hasShyBowels = BF.HasTrait(player, BFTraits.ShyBowels)
    local isBeingWatched = BF.IsBeingWatched(player)

    if defecateValue < (requirement / 100) * bowelsMaxValue or (hasShyBowels and isBeingWatched) then
        return
    end

    BF.WalkThenRelief(player, object, false, function(goalObject, seated)
        ISTimedActionQueue.add(FixtureDefecate:new(player, BF.GetDefecateTime(defecateValue * 2), true, true, goalObject))

        if isWiping then
            ISTimedActionQueue.add(WipeSelf:new(player, 20, wipeType, wipeItem, "poop", pooledTypes))
        else
            local soilableClothing = BF.GetSoilableClothing()
            for _, bodyLocation in ipairs(soilableClothing) do
                local clothingItem = player:getWornItem(bodyLocation)
                if clothingItem then
                    local modData = clothingItem:getModData()
                    modData.pooped = true
                    modData.poopedSeverity = (modData.poopedSeverity or 0) + 5
                    modData.poopedSeverity = math.min(modData.poopedSeverity, 100)
                end
            end
            BF.ResetRemovedClothing(player)
        end
    end, function()
        BF.RemoveBottomClothing(player)
    end)
end

function BF.TriggerGroundDefecate(player, isWiping, wipeType, wipeItem, wipeEfficiency, pooledTypes)
    player = player or getPlayer()
    local defecateValue = BF.GetDefecateValue(player)
    local poopTime = defecateValue * 2

    BF.RemoveBottomClothing(player)
    ISTimedActionQueue.add(GroundDefecate:new(player, BF.GetDefecateTime(poopTime), true, true))

    if isWiping then
        ISTimedActionQueue.add(WipeSelf:new(player, 20, wipeType, wipeItem, "poop", pooledTypes))
    else
        -- Apply 5% soiling penalty to worn clothing if not wiping
        local soilableClothing = BF.GetSoilableClothing()
        for _, bodyLocation in ipairs(soilableClothing) do
            local clothingItem = player:getWornItem(bodyLocation)
            if clothingItem then
                local modData = clothingItem:getModData()
                modData.pooped = true
                modData.poopedSeverity = (modData.poopedSeverity or 0) + 5
                modData.poopedSeverity = math.min(modData.poopedSeverity, 100)
            end
        end

        BF.ResetRemovedClothing(player) -- GroundDefecate re-dresses when it finishes
    end
end

function BF.TriggerSelfDefecate(player, isLeak)
    local isLeak = isLeak or false
    player = player or getPlayer()
    local defecateValue = BF.GetDefecateValue(player)
    local poopTime = defecateValue / 4
    local bowelsMaxValue = BF.GetBowelCapacity(player)

    -- Check if the player has relevant clothing on and apply the "pooped bottoms" effects.
    if BF.HasClothingOn(player, unpack(BF.GetSoilableClothing())) then
        BF.DefecateBottoms(player, isLeak)
    else
        -- Optionally, could create a world object or simply do nothing when no clothing is worn.
    end

    -- Enqueue the self-defecation timed action.
    -- The last parameter 'isLeak' determines whether it applies leak behavior.
    ISTimedActionQueue.add(SelfDefecate:new(player, BF.GetDefecateTime(poopTime), false, false, true, false, nil, isLeak))

    --print("Updated Pooped Self Value: " .. BF.GetPoopedSelfValue())
    --if isLeak then
    --    print("Leak triggered: Updated Pooped Self Value: " .. BF.GetPoopedSelfValue())
    --else
    --    print("Updated Pooped Self Value: " .. BF.GetPoopedSelfValue())
    --end
end

function BF.PoopInContainer(item, player)
end