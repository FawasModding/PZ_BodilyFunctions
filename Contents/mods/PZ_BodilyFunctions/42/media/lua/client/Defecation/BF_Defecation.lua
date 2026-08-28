require "BodilyFunctions"

-- Update defecation values
function BF.UpdateDefecationValues()
    local player = getPlayer()

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
    finalBowelMultiplier = finalBowelMultiplier * randomBowelFactor

    print("Hunger level: " .. tostring(hunger))
    print("Bowel multiplier: " .. tostring(bowelMultiplier))
    print("Final bowel multiplier: " .. tostring(finalBowelMultiplier))

    -- Get base max capacities (from SandboxVars or defaults).
    local baseBowelsMax  = BF.GetMaxBowelValue()

    -- Get the current fill values.
    local defecateValue = BF.GetDefecateValue()
    
    -- Base Increase Rate:
    local defecateBaseIncreaseRate = 3.5  -- Base bowel fill per 10-minute tick

    -- New bowel value = old bowel value + (3.5 * sandbox multiplier * hunger/stress/endurance/random multiplier)
    local defecateIncrease = defecateBaseIncreaseRate * SandboxVars.BF.BowelsIncreaseMultiplier * finalBowelMultiplier

    -- Update the fill values!
    defecateValue = defecateValue + defecateIncrease

    player:getModData().defecateValue = tonumber(defecateValue)

    -- Calculate the current percentages for debugging/triggering events.
    local defecatePercent = (defecateValue / baseBowelsMax) * 100

    --print("Updated Defecate Value: " .. tostring(defecatePercent) .. "% (Effective Max: " .. baseBowelsMax .. ")")
end

-- Effects when player's wearing pooped clothing
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
        BF.RefreshSoiledSeverityFromModData(underwear)

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
        BF.RefreshSoiledSeverityFromModData(pants)

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

function BF.TriggerToiletDefecate(object, player, isWiping, wipeType, wipeItem, wipeEfficiency, pooledTypes)
    local player = getPlayer()
    local defecateValue = BF.GetDefecateValue()
    local requirement = SandboxVars.BF.PoopInToiletRequirement or 40
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100
    local hasShyBowels = player:hasTrait(BFTraits.ShyBowels)
    local isBeingWatched = BF.IsBeingWatched(player)

    if defecateValue < (requirement / 100) * bowelsMaxValue or (hasShyBowels and isBeingWatched) then
        return
    end

    -- Remove clothing before walking to / sitting on the toilet.
    BF.RemoveBottomClothing(player)

    -- Walk to the toilet using the vanilla furniture-sitting pathfinder, then
    -- run the relief action once the character has arrived and is seated.
    BF.WalkThenRelief(player, object, BF.CanSitOnObject(object), function(goalObject, seated)
        ISTimedActionQueue.add(ToiletDefecate:new(player, defecateValue * 2, true, true, goalObject, seated))

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
            BF.ReequipBottomClothing(player)
            BF.ResetRemovedClothing(player)
        end
        if seated then
            BF.StandUpAfterToilet(player)
        end
    end)
end

-- Standing/crouching defecation at a non-sittable, non-oriented fixture
-- (bush, water, trash can, dumpster). Mirrors GroundDefecate's squat, but
-- spawns no waste object since it's going into the fixture, and applies no
-- facing logic since these objects have no orientation.
function BF.TriggerFixtureDefecate(object, player, isWiping, wipeType, wipeItem, wipeEfficiency, pooledTypes)
    local player = getPlayer()
    local defecateValue = BF.GetDefecateValue()
    local requirement = SandboxVars.BF.PoopInToiletRequirement or 40
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100
    local hasShyBowels = player:hasTrait(BFTraits.ShyBowels)
    local isBeingWatched = BF.IsBeingWatched(player)

    if defecateValue < (requirement / 100) * bowelsMaxValue or (hasShyBowels and isBeingWatched) then
        return
    end

    BF.RemoveBottomClothing(player)

    BF.WalkThenRelief(player, object, false, function(goalObject, seated)
        ISTimedActionQueue.add(FixtureDefecate:new(player, defecateValue * 2, true, true))

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
            BF.ReequipBottomClothing(player)
            BF.ResetRemovedClothing(player)
        end
    end)
end

function BF.TriggerGroundDefecate(isWiping, wipeType, wipeItem, wipeEfficiency, pooledTypes)
    local player = getPlayer()
    local defecateValue = BF.GetDefecateValue()
    local poopTime = defecateValue * 2

    BF.RemoveBottomClothing(player)
    ISTimedActionQueue.add(GroundDefecate:new(player, poopTime, true, true))

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

        BF.ReequipBottomClothing(player) -- put back on bottom clothing
        BF.ResetRemovedClothing(player) -- reset removed clothing
    end
end

function BF.TriggerSelfDefecate(isLeak)
    local isLeak = isLeak or false
    local player = getPlayer()
    local defecateValue = BF.GetDefecateValue()
    local poopTime = defecateValue / 4
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100

    -- Check if the player has relevant clothing on and apply the "pooped bottoms" effects.
    if BF.HasClothingOn(player, unpack(BF.GetSoilableClothing())) then
        BF.DefecateBottoms(isLeak)
    else
        -- Optionally, could create a world object or simply do nothing when no clothing is worn.
    end

    -- Enqueue the self-defecation timed action.
    -- The last parameter 'isLeak' determines whether it applies leak behavior.
    ISTimedActionQueue.add(SelfDefecate:new(player, poopTime, false, false, true, false, nil, isLeak))

    --print("Updated Pooped Self Value: " .. BF.GetPoopedSelfValue())
    --if isLeak then
    --    print("Leak triggered: Updated Pooped Self Value: " .. BF.GetPoopedSelfValue())
    --else
    --    print("Updated Pooped Self Value: " .. BF.GetPoopedSelfValue())
    --end
end

function BF.PoopInContainer(item)
end