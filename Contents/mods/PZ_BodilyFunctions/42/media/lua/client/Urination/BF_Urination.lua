require "BodilyFunctions"

-- Update urination values
function BF.UpdateUrinationValues()
    local player = getPlayer()
    
    -- Get player stats
    local thirst = player:getStats():get(CharacterStat.THIRST)
    local hunger = player:getStats():get(CharacterStat.HUNGER)
    local stress = player:getStats():get(CharacterStat.STRESS)
    local endurance = player:getStats():get(CharacterStat.ENDURANCE)

    -- Calculate bladder multiplier where:
    -- - At thirst 0 (fully hydrated): multiplier = 1.0 (standard rate)
    -- - At thirst 1 (dehydrated): multiplier = 0.3 (need to pee 30% less when dehydrated)
    local bladderMultiplier = 1.0 - (thirst * 0.7)

    -- Increased urgency when stressed
    local stressEffect = stress * 0.3  -- Up to 30% increase when fully stressed

    -- Simulate body needing nutrients to recover
    local urgencyFactor = (1.0 - endurance) * 0.1

    -- Add random variation for a more realistic feel
    local randomBladderFactor = 0.9 + (ZombRand(21) / 100) -- Range: 0.9 to 1.1

    -- Calculate base multiplier from player stats
    local finalBladderMultiplier = bladderMultiplier + stressEffect + urgencyFactor

    -- Multiply random variation with final multiplier
    finalBladderMultiplier = finalBladderMultiplier * randomBladderFactor

    print("Thirst level: " .. tostring(thirst))
    print("Bladder multiplier: " .. tostring(bladderMultiplier))
    print("Final bladder multiplier: " .. tostring(finalBladderMultiplier))

    -- Get base max capacities (from SandboxVars or defaults).
    local baseBladderMax = SandboxVars.BathroomFunctions.BladderMaxValue or 600

    -- Get the current fill values.
    local urinateValue = BF.GetUrinateValue()

    -- Base Increase Rate:
    local urinateBaseRate = 10 -- Base bladder fill per 10-minute tick

    -- New bladder value = old bladder value + (3.5 * sandbox multiplier * thirst/stress/endurance/random multiplier)
    local urinateIncrease = urinateBaseRate * SandboxVars.BF.BladderIncreaseMultiplier * finalBladderMultiplier

    -- Update the fill values!
    urinateValue = urinateValue + urinateIncrease

    player:getModData().urinateValue = tonumber(urinateValue)

    -- Calculate the current percentages for debugging/triggering events.
    local urinatePercent = (urinateValue / baseBladderMax) * 100

    -- Bladder specific:
    -- Muscle strain in pelvis based on bladder capacity thresholds
    local muscleStrainAmount = 0
    if urinateValue >= 0.95 * baseBladderMax then
        muscleStrainAmount = 90 -- Level 4
    elseif urinateValue >= 0.90 * baseBladderMax then
        muscleStrainAmount = 75 -- Level 3
    elseif urinateValue >= 0.75 * baseBladderMax then
        muscleStrainAmount = 60 -- Level 2
    elseif urinateValue >= 0.60 * baseBladderMax then
        muscleStrainAmount = 10  -- Level 1
    end
    if muscleStrainAmount > 0 then
        BF.PainInBladder(player, muscleStrainAmount)
        print("Bladder pain applied: " .. muscleStrainAmount .. " (Urinate Value: " .. urinateValue .. "/" .. baseBladderMax .. ")")
    end


    --print("Updated Urinate Value: " .. tostring(urinatePercent) .. "% (Effective Max: " .. baseBladderMax .. ")")
end

-- Function to apply effects when the player has urinated in their clothing
function BF.UrinateBottoms(leakTriggered)
    local player = getPlayer()
    local modOptions = PZAPI.ModOptions:getOptions("BF")
    local bladderMaxValue = BF.GetMaxBladderValue()
    local leakMultiplier = leakTriggered and 0.05 or 1.0
    local peeValue = BF.GetUrinateValue()
    local urinatePercentage = (peeValue / bladderMaxValue) * 100 * leakMultiplier

    local showPeeObject = false
    local maxPeeSeverity = 0

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

    -- Step 2: Process outer garments (pants, suits, etc.)
    local pants = nil
    for _, loc in ipairs(outerwearLocations) do
        local item = player:getWornItem(loc)
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
        if SandboxVars.BF.VisiblePeeStain and (not leakTriggered or modData.peedSeverity >= 25) then
            BF_Overlays.ApplyOverlayToSlot(player, underwear, "peed", BFBodyLocations.PeedOverlay_Underwear)
        end

        -- Update clothing properties
        BF.ApplySoilingEffects(underwear, leakTriggered)
        BF.RefreshSoiledSeverityFromModData(underwear)

        if modData.peedSeverity >= 90 then showPeeObject = true end
    end

    -- Step 4: Apply severity to pants if applicable
    if pants and (remainingUrinatePercentage > 0 or urinatePercentage >= 50) then
        local modData = pants:getModData()
        modData.peed = true

        -- Apply spillover or partial severity for realism
        local pantsSeverity = remainingUrinatePercentage > 0 and remainingUrinatePercentage or urinatePercentage * 0.5
        modData.peedSeverity = (modData.peedSeverity or 0) + pantsSeverity

        -- Cap severity at 100
        if modData.peedSeverity > 100 then modData.peedSeverity = 100 end

        -- Update tooltip
        modData.tooltip = "Soiled (Urine): " .. math.floor(modData.peedSeverity) .. "%"
        maxPeeSeverity = math.max(maxPeeSeverity, modData.peedSeverity)

        -- Apply overlay if severity meets threshold
        if SandboxVars.BF.VisiblePeeStain and (not leakTriggered or modData.peedSeverity >= 25) then
            BF_Overlays.ApplyOverlayToSlot(player, pants, "peed", BFBodyLocations.PeedOverlay_Pants)
        end

        -- Update clothing properties
        BF.ApplySoilingEffects(pants, leakTriggered)
        BF.RefreshSoiledSeverityFromModData(pants)

        if modData.peedSeverity >= 90 then showPeeObject = true end
    end

    -- Step 5: Create pee object if conditions are met
    if SandboxVars.BF.CreatePeeObject and (not leakTriggered or showPeeObject) and not player:isAsleep() then
        local urineItem = instanceItem("BF.Urine_Hydrated_0")
        player:getCurrentSquare():AddWorldInventoryItem(urineItem, 0, 0, 0)
    end

    -- Step 6: Apply sound and dialogue
    player:playerVoiceSound("SighBored")
    if leakTriggered then
        player:Say(getText("IGUI_announce_SilentOops"))
    else
        getSoundManager():PlayWorldSound("BF_Pee_Self", player:getCurrentSquare(), 0, 10, 0.2, false)
        local playerSayStatus = modOptions:getOption("6")
        if playerSayStatus:getValue(1) then
            player:Say(getText("IGUI_announce_IPeedMyself"))
        end
    end
end

-- =====================================================
--
-- EVENT REGISTRATION
--
-- =====================================================

-- Walks the player to the toilet. When mustSit is true (females), seats them
-- EXACTLY like vanilla "Rest": pathToSitOnFurniture -> ISRestAction (which sits
-- the character and self-completes, leaving the sitting STATE). The relief
-- action then runs on top, like reading while seated. When mustSit is false
-- (males urinating), the character just walks adjacent and stands.
--
-- reliefActionFactory(goalObject, seated) queues the relief action(s).
-- True if the object has vanilla sitting data (a real toilet), false for sinks,
-- urinals, showers, etc. that share the same relief action but can't be sat on.
function BF.CanSitOnObject(object)
    if not object then return false end
    return SeatingManager.getInstance():getTilePositionCount(object) > 0
end

-- Queues the vanilla "get up from furniture" after toilet actions, so the
-- character stands once they've finished (and after any wiping).
function BF.StandUpAfterToilet(player)
    player:setVariable("forceGetUp", true)
    ISTimedActionQueue.add(ISWaitWhileGettingUp:new(player))
end

function BF.WalkThenRelief(player, object, mustSit, reliefActionFactory)
    if not object or not object:getSquare() then return false end

    if not mustSit then
        -- Standing use (male / sinks / urinals): stand on a cardinally-adjacent
        -- tile touching the object (N/S/E/W, never diagonal or a tile away), so
        -- the character is right next to it without standing on top of it.
        local objSq = object:getSquare()
        local cell = getCell()
        local ox, oy, oz = objSq:getX(), objSq:getY(), objSq:getZ()
        local best = nil
        local bestDist = 9999
        local charSq = player:getCurrentSquare()
        for _, d in ipairs({ {1,0}, {-1,0}, {0,1}, {0,-1} }) do
            local sq = cell and cell:getGridSquare(ox + d[1], oy + d[2], oz)
            if sq and sq:isFree(false) then
                local dist = charSq and IsoUtils.DistanceToSquared(charSq:getX(), charSq:getY(), sq:getX(), sq:getY()) or 0
                if dist < bestDist then
                    bestDist = dist
                    best = sq
                end
            end
        end
        best = best or AdjacentFreeTileFinder.Find(objSq, player, nil)
        if best and best ~= charSq then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(player, best))
        end
        reliefActionFactory(object, false)
        return true
    end

    local action = ISPathFindAction:pathToSitOnFurniture(player, object, true)

    action:setOnComplete(function()
        local goal = action.goalFurnitureObject or object
        local restAction = ISRestAction:new(player, goal, true)
        if action:addAfter(restAction) == nil then
            ISTimedActionQueue.add(restAction)
        end
        reliefActionFactory(goal, true)
    end)

    action:setOnFail(function()
        local adjacent = AdjacentFreeTileFinder.Find(object:getSquare(), player, nil)
        if adjacent then
            action:setRunActionsAfterFailing(true)
            if adjacent ~= player:getCurrentSquare() then
                action:addAfter(ISWalkToTimedAction:new(player, adjacent))
            end
            reliefActionFactory(object, false)
        end
    end)

    ISTimedActionQueue.add(action)
    return true
end

function BF.TriggerToiletUrinate(object, player, isWiping, wipeType, wipeItem, wipeEfficiency, pooledTypes)
    local player = getPlayer()
    local urinateValue = BF.GetUrinateValue()
    local requirement = SandboxVars.BF.PeeInToiletRequirement or 40
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100
    local hasShyBladder = player:hasTrait(BFTraits.ShyBladder)
    local isBeingWatched = BF.IsBeingWatched(player)

    -- Only allow action if requirements are met
    if urinateValue < (requirement / 100) * bladderMaxValue then
        return
    end
    if hasShyBladder and isBeingWatched then
        return
    end

    local isFemale = player:isFemale() == true
    -- Sit only for females on a real toilet (objects with sitting data). Sinks,
    -- urinals, showers etc. use this same trigger but must be used standing.
    local mustSit = isFemale and BF.CanSitOnObject(object)

    -- Remove clothing before walking to / sitting on the toilet.
    if isFemale then
        BF.RemoveBottomClothing(player)
    end

    BF.WalkThenRelief(player, object, mustSit, function(goalObject, seated)
        ISTimedActionQueue.add(ToiletUrinate:new(player, urinateValue, true, true, goalObject, seated))
        if isFemale then
            BF.HandlePeeWiping(player, isWiping, wipeType, wipeItem, pooledTypes)
        end
        if seated then
            BF.StandUpAfterToilet(player)
        end
    end)
end

-- Standing/crouching urination at a non-sittable, non-oriented fixture (sink,
-- shower, bush, water, trash can, dumpster). Always walks adjacent and never
-- sits — these objects have no seating data and no meaningful facing.
function BF.TriggerFixtureUrinate(object, player, isWiping, wipeType, wipeItem, wipeEfficiency, pooledTypes)
    local player = getPlayer()
    local urinateValue = BF.GetUrinateValue()
    local requirement = SandboxVars.BF.PeeInToiletRequirement or 40
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100
    local hasShyBladder = player:hasTrait(BFTraits.ShyBladder)
    local isBeingWatched = BF.IsBeingWatched(player)

    if urinateValue < (requirement / 100) * bladderMaxValue then
        return
    end
    if hasShyBladder and isBeingWatched then
        return
    end

    local isFemale = player:isFemale() == true

    BF.WalkThenRelief(player, object, false, function(goalObject, seated)
        if isFemale then
            BF.RemoveBottomClothing(player)
        end
        ISTimedActionQueue.add(FixtureUrinate:new(player, urinateValue, true, true))
        if isFemale then
            BF.HandlePeeWiping(player, isWiping, wipeType, wipeItem, pooledTypes)
        end
    end)
end

function BF.TriggerGroundUrinate(isWiping, wipeType, wipeItem, wipeEfficiency, pooledTypes)
    local player = getPlayer()
    local urinateValue = BF.GetUrinateValue()
    local peeTime = urinateValue

    local isFemale = player:isFemale() == true

    -- If female, must take off clothing. Males would just unzip their pants.
    if isFemale then
        BF.RemoveBottomClothing(player)
    end

    -- Urinate on the ground
    ISTimedActionQueue.add(GroundUrinate:new(player, peeTime, true, true))

    -- Wiping is female-only.
    if isFemale then
        BF.HandlePeeWiping(player, isWiping, wipeType, wipeItem, pooledTypes)
    end
end

-- Shared post-urination wiping flow for female characters.
-- Mirrors the defecation wiping logic but with a lighter default penalty.
function BF.HandlePeeWiping(player, isWiping, wipeType, wipeItem, pooledTypes)
    if isWiping then
        ISTimedActionQueue.add(WipeSelf:new(player, 15, wipeType, wipeItem, "pee", pooledTypes))
    else
        -- Small residual-urine penalty on unequipped bottom clothing (pee only).
        local soilableClothing = BF.GetSoilableClothing()
        for _, bodyLocation in ipairs(soilableClothing) do
            local clothingItem = player:getWornItem(bodyLocation)
            if clothingItem then
                local modData = clothingItem:getModData()
                modData.peed = true
                modData.peedSeverity = math.min((modData.peedSeverity or 0) + 3, 100)
            end
        end
        BF.ReequipBottomClothing(player)
        BF.ResetRemovedClothing(player)
    end
end

function BF.TriggerSelfUrinate(isLeak)
    local isLeak = isLeak or false
    local player = getPlayer()
    local urinateValue = BF.GetUrinateValue()
    local peeTime = urinateValue / 4 -- Determine the time based on the bladder level

    local bladderMaxValue = isLeak and (SandboxVars.BathroomFunctions.BladderMaxValue or 500) or (SandboxVars.BathroomFunctions.BladderMaxValue or 100)

    -- Check if player is wearing clothing that can be soiled.
    if BF.HasClothingOn(player, unpack(BF.GetSoilableClothing())) then
        BF.UrinateBottoms(isLeak)
    else
        -- If the player isn't wearing clothing, create the pee object if that option is enabled.
        if SandboxVars.BF.CreatePeeObject == true then
            local urineItem = instanceItem("BF.Urine_Hydrated_0")
            player:getCurrentSquare():AddWorldInventoryItem(urineItem, 0, 0, 0)
        end
    end

    -- Enqueue the self-urinate action.
    -- The last parameter, `isLeak`, tells the timed action to use the leak behavior.
    ISTimedActionQueue.add(SelfUrinate:new(player, peeTime, false, false, true, false, nil, isLeak))

    --if isLeak then
    --    print("Leak triggered: Updated Peed Self Value: " .. BF.GetPeedSelfValue())
    --else
    --    print("Updated Peed Self Value: " .. BF.GetPeedSelfValue())
    --end
end

function BF.PeeInContainer(item)
    local fluidContainer = item:getFluidContainer() -- Access the container
    local containerCapacity = fluidContainer:getCapacity() * 1000 -- Convert from L to mL (if it's in L)
    local bladderUrine = BF.GetUrinateValue() -- Get bladder urine amount

    -- Calculate the amount to transfer
    local amountToFill = math.min(containerCapacity, bladderUrine)

    -- Fill the bottle with the calculated amount
    fluidContainer:addFluid("Urine", amountToFill)

    -- Update the bladder to reflect the remaining urine
    local remainingBladderUrine = bladderUrine - amountToFill
    BF.SetUrinateValue(remainingBladderUrine)
end