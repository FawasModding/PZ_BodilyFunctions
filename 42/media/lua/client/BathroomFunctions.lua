BathroomFunctions = {}
BathroomFunctions.didFirstTimer = false
FlySquares = {}

-- =====================================================
--
-- BATHROOM FUNCTIONALITY AND TIMERS
--
-- =====================================================

--[[
Function to handle timed updates for bathroom needs
This function is called periodically (e.g., every 10 in-game minutes).
]]--
function BathroomFunctions.BathroomFunctionTimers()
    if BathroomFunctions.didFirstTimer then
        BathroomFunctions.NewBathroomValues() -- If the initial setup is done, update the player's bathroom values
        BathroomFunctions.CheckForAccident() -- Check whether or not the player has urinated or defecated themselves.
        BathroomFunctions.DirtyBottomsEffects()
    else
        BathroomFunctions.didFirstTimer = true -- If this is the first call, set the flag to true and skip updating values
    end
end

-- Function to update the player's bathroom-related values (urination and defecation)
function BathroomFunctions.NewBathroomValues()
    local player = getPlayer() -- Fetch the current player object

    -- === URINATION ===

    -- Update the urination value
    local urinateValue = BathroomFunctions.GetUrinateValue() -- Get the current urination value
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Get the max bladder value, default to 100 if not set
    local urinateIncrease = 0.005 * bladderMaxValue * SandboxVars.BathroomFunctions.BladderIncreaseMultiplier -- 0.5% of the max bladder value * multiplier

    urinateValue = urinateValue + urinateIncrease -- Increase the urination value by the calculated percentage
    player:getModData().urinateValue = tonumber(urinateValue) -- Save the updated value back to the player's modData

    -- Convert to a percentage of the bladderMaxValue
    local urinatePercentage = (urinateValue / bladderMaxValue) * 100
    print("Updated Urinate Value: " .. urinatePercentage .. "%") -- Debug print statement to display the updated urination value as a percentage

    -- === DEFECATION ===

    -- Update the defecation value
    local defecateValue = BathroomFunctions.GetDefecateValue() -- Get the current defecation value
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Get the max bowel value, default to 100 if not set
    local defecateIncrease = 0.005 * bowelsMaxValue * SandboxVars.BathroomFunctions.BowelsIncreaseMultiplier -- 0.5% of the max bowel value * multiplier

    defecateValue = defecateValue + defecateIncrease -- Increase the defecation value by the calculated percentage
    player:getModData().defecateValue = tonumber(defecateValue) -- Save the updated value back to the player's modData

    -- Convert to a percentage of the bowelsMaxValue
    local defecatePercentage = (defecateValue / bowelsMaxValue) * 100
    print("Updated Defecate Value: " .. defecatePercentage .. "%") -- Debug print statement to display the updated defecation value as a percentage

end

function BathroomFunctions.CheckForAccident()
    local urinateValue = BathroomFunctions.GetUrinateValue() -- Current bladder level
    local defecateValue = BathroomFunctions.GetDefecateValue() -- Current bowel level
    local player = getPlayer()

    -- Retrieve maximum values from SandboxVars
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Default to 100 if not set
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Default to 100 if not set

    -- Calculate thresholds
    local bladderThreshold = 0.95 * bladderMaxValue -- 95% of max bladder value
    local bowelsThreshold = 0.98 * bowelsMaxValue -- 98% of max bowel value

    -- Moodle modifiers (activated only if moodles are enabled)
    local panicModifier = 0
    local stressedModifier = 0
    local drunkModifier = 0
    local heavyLoadModifier = 0
    local wetModifier = 0
    local painModifier = 0
    local coldModifier = 0

    -- Check moodles for modifiers (if moodles are enabled)
    if player:getMoodles() then
        panicModifier = player:getMoodles():getMoodleLevel(MoodleType.Panic) * 5 -- Panic increases accident likelihood
        stressedModifier = player:getMoodles():getMoodleLevel(MoodleType.Stress) * 3 -- Stress increases chance
        drunkModifier = player:getMoodles():getMoodleLevel(MoodleType.Drunk) * 10 -- Drunk increases chance for urination
        heavyLoadModifier = player:getMoodles():getMoodleLevel(MoodleType.HeavyLoad) * 3 -- Heavy load increases chance
        wetModifier = player:getMoodles():getMoodleLevel(MoodleType.Wet) * 5 -- Wet triggers a stronger urge
        painModifier = player:getMoodles():getMoodleLevel(MoodleType.Pain) * 3 -- Pain increases likelihood
        coldModifier = player:getMoodles():getMoodleLevel(MoodleType.HasACold) * 2 -- Cold increases chance
    end

    -- Check if the player should urinate involuntarily
    if urinateValue >= bladderThreshold or 
       (urinateValue > 0.5 * bladderMaxValue and (panicModifier > 0 or stressedModifier > 0 or drunkModifier > 0 or heavyLoadModifier > 0 or wetModifier > 0 or painModifier > 0 or coldModifier > 0)) then
        BathroomFunctions.UrinateSelf()
    end

    -- Check if the player should defecate involuntarily
    if defecateValue >= bowelsThreshold or 
       (defecateValue > 0.5 * bowelsMaxValue and (panicModifier > 0 or stressedModifier > 0 or heavyLoadModifier > 0 or wetModifier > 0 or painModifier > 0 or coldModifier > 0)) then
        BathroomFunctions.DefecateSelf()
    end

end




-- =====================================================
--
-- ACCIDENT FUNCTIONS
--
-- =====================================================

-- Function to apply effects when the player has urinated in their clothing
function BathroomFunctions.UrinateBottoms()
    local player = getPlayer()

    local clothing = nil
    local bodyLocations = BathroomFunctions.GetSoilableClothing()

    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Get the max bladder value, default to 100 if not set

    -- Check if the player is wearing any of the specified clothing
    for i = 1, #bodyLocations do
        clothing = player:getWornItem(bodyLocations[i])
        if clothing then
            local modData = clothing:getModData()

            -- Ensure 'peedSeverity' is initialized if it doesn't exist
            if modData.peedSeverity == nil then
                modData.peedSeverity = 0
            end

            -- Convert to a percentage of the bladderMaxValue
            local urinatePercentage = (BathroomFunctions.GetUrinateValue() / bladderMaxValue) * 100

            -- Mark the clothing as soiled by urine
            modData.peed = true
            modData.peedSeverity = modData.peedSeverity + urinatePercentage

            -- Cap the 'peedSeverity' at 100
            if modData.peedSeverity >= 100 then
                modData.peedSeverity = 100
            end

            -- Update the clothing item and condition
            BathroomFunctions.SetClothing(clothing)

            -- Update the clothing's condition after the accident
            BathroomFunctions.PeedPoopedSelfUpdate(clothing)

            if SandboxVars.BathroomFunctions.ShowPeeStain == true then
                BathroomClothOverlays.OnClothingChanged(player)
            end
        end
    end

    if SandboxVars.BathroomFunctions.CreatePeeObject == true then
		local urineItem = instanceItem("BathroomFunctions.HumanUrine_Small")
		player:getCurrentSquare():AddWorldInventoryItem(urineItem, 0, 0, 0)
	end

    player:playerVoiceSound("SighBored")
    getSoundManager():PlayWorldSound("PeeSelf", player:getCurrentSquare(), 0, 10, .2, false)

    -- Update player stats for the accident
    --player:getStats():setStress(player:getStats():getStress() + 0.6)
    player:getBodyDamage():setUnhappynessLevel(player:getBodyDamage():getUnhappynessLevel() + 5)

    -- The player says they have urinated themselves
    player:Say("I've pissed myself")
end

-- Function to apply effects when the player has defecated in their clothing
function BathroomFunctions.DefecateBottoms()
    local player = getPlayer()

    local clothing = nil
    local bodyLocations = BathroomFunctions.GetSoilableClothing()

    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Get the max bowels value, default to 100 if not set

    -- Check if the player is wearing any of the specified clothing
    for i = 1, #bodyLocations do
        clothing = player:getWornItem(bodyLocations[i])
        if clothing then
            local modData = clothing:getModData()

            -- Ensure 'poopedSeverity' is initialized if it doesn't exist
            if modData.poopedSeverity == nil then
                modData.poopedSeverity = 0
            end

            -- Convert to a percentage of the bladderMaxValue
            local defecatePercentage = (BathroomFunctions.GetDefecateValue() / bowelsMaxValue) * 100

            -- Mark the clothing as soiled by urine
            modData.pooped = true
            modData.poopedSeverity = modData.poopedSeverity + defecatePercentage

            -- Cap the 'poopedSeverity' at 100
            if modData.poopedSeverity >= 100 then
                modData.poopedSeverity = 100
            end

            -- Update the clothing item and condition
            BathroomFunctions.SetClothing(clothing)

            -- Update the player's condition after the accident
            BathroomFunctions.PeedPoopedSelfUpdate(clothing)
        end
    end

    player:playerVoiceSound("JumpLow")
    getSoundManager():PlayWorldSound("PoopSelf1", player:getCurrentSquare(), 0, 10, .05, false)

    -- Update player stats for the accident
    --player:getStats():setStress(player:getStats():getStress() + 0.8)
    player:getBodyDamage():setUnhappynessLevel(player:getBodyDamage():getUnhappynessLevel() + 10)
    player:getStats():setFatigue(player:getStats():getFatigue() + 0.025)

    -- Add dirt to simulate the mess
    player:addDirt(BloodBodyPartType.Groin, ZombRand(20, 50), false)
    player:addDirt(BloodBodyPartType.UpperLeg_L, ZombRand(20, 50), false)
    player:addDirt(BloodBodyPartType.UpperLeg_R, ZombRand(20, 50), false)

    player:getVisual():setDirt(BloodBodyPartType.Groin, ZombRand(20, 50))
    player:getVisual():setDirt(BloodBodyPartType.UpperLeg_L, ZombRand(20, 50))
    player:getVisual():setDirt(BloodBodyPartType.UpperLeg_R, ZombRand(20, 50))

    -- The player says they have defecated themselves
    player:Say("I've shit myself")
end


-- Helper function to check if the player is wearing any of the specified clothing
function BathroomFunctions.HasClothingOn(player, ...)
    local bodyLocations = {...} -- Receive the clothing items to check

    -- Iterate through the clothing items to check if the player is wearing any of them
    for i = 1, #bodyLocations do
        local clothing = player:getWornItem(bodyLocations[i])
        if clothing then
            return true -- If the player is wearing any of these clothing items, return true
        end
    end

    return false -- If none of the clothing items are found, return false
end

function BathroomFunctions.SetClothing(clothing)
    local cleanName = nil

    -- Check if the clothing name contains a parenthesis, which might indicate a status modifier (like "(Peed)" or "(Pooped)")
    if (string.find(clothing:getName(), "%(")) then
        local startIndex = string.find(clothing:getName(), "%(")
        -- Extract the base name of the clothing (without the status modifier in parentheses)
        cleanName = string.sub(clothing:getName(), 0, startIndex - 2)
    else
        cleanName = clothing:getName()
    end

    -- Store the original clean name of the clothing in its mod data
    clothing:getModData().originalName = cleanName

    -- If the clothing is marked as "peed" (wet), modify the clothing's properties
    if clothing:getModData().peed == true then
        -- Update the name to include the "(Peed)" status
        clothing:setName(cleanName .. " (Peed " .. clothing:getModData().peedSeverity .. "%)")
        -- Set the wetness to maximum (500) to indicate the clothing is soaked
        clothing:setWetness(500)
        -- Set the dirtyness to maximum (100) to reflect the soiled condition
        clothing:setDirtyness(100)
    end

    -- If the clothing is marked as "pooped" (dirty), modify the clothing's properties
    if clothing:getModData().pooped == true then
        -- Update the name to include the "(Pooped)" status
        clothing:setName(cleanName .. " (Pooped " .. clothing:getModData().poopedSeverity .. "%)")
        -- Set the dirtyness to maximum (100) to reflect the soiled condition
        clothing:setDirtyness(100)
        -- Reduce the player's run speed to simulate the hindrance caused by having poop in the clothing
        clothing:setRunSpeedModifier(clothing:getRunSpeedModifier() - 0.2) -- Expected effect: slower movement, but may not be very noticeable
    end

    -- If both "peed" and "pooped" statuses are true, update the clothing name to reflect both conditions
    if clothing:getModData().peed and clothing:getModData().pooped then
        clothing:setName(cleanName .. " (Peed " .. clothing:getModData().peedSeverity .. "%" .. " & " .. "Pooped " .. clothing:getModData().poopedSeverity .. "%)")
    end
end

--[[
Use this to call function to to show the wearing urinated and defecated garments moodles. As well as affect the mood over time.
]]--
function BathroomFunctions.DirtyBottomsEffects()
    local player = getPlayer()
    local totalPoopedSeverity = 0
    local totalPeedSeverity = 0

    -- Iterate over all worn items
    for i = 0, player:getWornItems():size() - 1 do
        local item = player:getWornItems():getItemByIndex(i)

        -- Ensure the item is not nil before calling PeedPoopedSelfUpdate
        if item ~= nil then
            -- Update values for pooped and peed states based on item mod data
            local itemUpdatedPooped, itemUpdatedPeed = BathroomFunctions.PeedPoopedSelfUpdate(item)

            -- Accumulate the total pooped and peed severity
            if itemUpdatedPooped and item:getModData().poopedSeverity then
                totalPoopedSeverity = totalPoopedSeverity + item:getModData().poopedSeverity
            end
            if itemUpdatedPeed and item:getModData().peedSeverity then
                totalPeedSeverity = totalPeedSeverity + item:getModData().peedSeverity
            end
        else
            print("Error: Worn item is nil at index " .. i)
        end
    end

    -- Update global values for pooped and peed after all items are processed
    if totalPoopedSeverity > 0 then
        BathroomFunctions.SetPoopedSelfValue(totalPoopedSeverity)
    else
        BathroomFunctions.SetPoopedSelfValue(0)
    end
    if totalPeedSeverity > 0 then
        BathroomFunctions.SetPeedSelfValue(totalPeedSeverity)
    else
        BathroomFunctions.SetPeedSelfValue(0)
    end
end

function BathroomFunctions.PeedPoopedSelfUpdate(clothing)
    local updatedPooped = false
    local updatedPeed = false

    -- Ensure 'clothing' and its 'modData' are valid before proceeding
    if clothing ~= nil and clothing:getModData() ~= nil then
        local modData = clothing:getModData()

        if modData.pooped ~= nil then -- Check if the worn item is defecated
            BathroomFunctions.SetPoopedSelfValue(modData.poopedSeverity)
            updatedPooped = true
        else
            -- If no pooped state, set to 0 (can be skipped here if handled at the end of the loop)
            BathroomFunctions.SetPoopedSelfValue(0)
        end

        if modData.peed ~= nil then -- Check if the worn item is urinated
            BathroomFunctions.SetPeedSelfValue(modData.peedSeverity)
            updatedPeed = true
        else
            -- If no peed state, set to 0 (can be skipped here if handled at the end of the loop)
            BathroomFunctions.SetPeedSelfValue(0)
        end
    else
        print("Error: Clothing or mod data is nil in PeedPoopedSelfUpdate.")
    end

    -- Debugging output
    --print("Updated PeedSelfValue: " .. BathroomFunctions.GetPeedSelfValue())
    --print("Updated PoopedSelfValue: " .. BathroomFunctions.GetPoopedSelfValue())

    return updatedPooped, updatedPeed
end





-- =====================================================
--
-- RIGHT CLICK / INTERACTION FUNCTIONS
--
-- =====================================================

function BathroomFunctions.BathroomRightClick(player, context, worldObjects)
    local firstObject
    for _, o in ipairs(worldObjects) do
        if not firstObject then firstObject = o end
    end

    local player = getPlayer()
    local square = firstObject:getSquare()
    local worldObjects = square:getObjects()
    local toiletOptionAdded = false

    local urinalTiles = {"fixtures_bathroom_01_8", "fixtures_bathroom_01_9", "fixtures_bathroom_01_10", "fixtures_bathroom_01_11"}
    local outhouseTiles = {"fixtures_bathroom_02_24", "fixtures_bathroom_02_25", "fixtures_bathroom_02_26", "fixtures_bathroom_02_27", "fixtures_bathroom_02_4", "fixtures_bathroom_02_5", "fixtures_bathroom_02_14", "fixtures_bathroom_02_15"}

    local urinateValue = BathroomFunctions.GetUrinateValue()
    local defecateValue = BathroomFunctions.GetDefecateValue()

    -- Retrieve maximum values from SandboxVars
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Default to 100 if not set
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Default to 100 if not set

    -- Main menu option: "Bodily Functions"
    local bathroomOption = context:addOption(getText("ContextMenu_BodilyFunctions"), worldObjects, nil)
    bathroomOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png");

    -- Submenu for "Bodily Functions"
    local bathroomSubMenu = ISContextMenu:getNew(context)
    context:addSubMenu(bathroomOption, bathroomSubMenu)

    -- Submenu for "Urination"
    local peeOption = bathroomSubMenu:addOption(getText("ContextMenu_Urinate"), worldObjects, nil)
    local peeSubMenu = ISContextMenu:getNew(bathroomSubMenu)
    bathroomSubMenu:addSubMenu(peeOption, peeSubMenu)
    peeOption.iconTexture = getTexture("media/ui/Urination.png");

    -- Submenu for "Defecation"
    local poopOption = bathroomSubMenu:addOption(getText("ContextMenu_Defecate"), worldObjects, nil)
    local poopSubMenu = ISContextMenu:getNew(bathroomSubMenu)
    bathroomSubMenu:addSubMenu(poopOption, poopSubMenu)
    poopOption.iconTexture = getTexture("media/ui/Defecation.png");

    -- Tooltips for "Urination"
    local function addTooltip(option, description)
        if option then
            local tooltip = ISToolTip:new()
            tooltip:initialise()
            tooltip:setVisible(false)
            tooltip.description = description
            option.toolTip = tooltip
        end
    end

    -- Default options for urination and defecation
    local groundPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseGround")), worldObjects, BathroomFunctions.PeeOnGround, player)
    addTooltip(groundPeeOption, "Urinate on the ground. (Requires " .. SandboxVars.BathroomFunctions.PeeOnGroundRequirement / 100 .. "%)")
    groundPeeOption.iconTexture = getTexture("media/textures/ContextMenuGround.png");

    local groundPoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseGround")), worldObjects, BathroomFunctions.PoopOnGround, player)
    addTooltip(groundPoopOption, "Defecate on the ground. (Requires " .. SandboxVars.BathroomFunctions.PoopOnGroundRequirement / 100 .. "%)")
    groundPoopOption.iconTexture = getTexture("media/textures/ContextMenuGround.png");

    if(SandboxVars.BathroomFunctions.CanHavePeePurpose == true) then

        local selfPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseSelf")), worldObjects, BathroomFunctions.UrinateSelf, player)
        addTooltip(selfPeeOption, "Urinate on yourself. Very few situations where this would be useful. (Requires " .. SandboxVars.BathroomFunctions.PeeOnSelfRequirement / 100 .. "%)")
        selfPeeOption.iconTexture = getTexture("media/ui/PeedSelf.png");

        -- Disable "On Self" pee options if urinateValue too low
        if urinateValue < (SandboxVars.BathroomFunctions.PeeOnGroundRequirement / 100) * bladderMaxValue then
            groundPeeOption.notAvailable = true
        end
        if urinateValue < (SandboxVars.BathroomFunctions.PeeOnSelfRequirement / 100) * bladderMaxValue then
            selfPeeOption.notAvailable = true
        end

    end

    if(SandboxVars.BathroomFunctions.CanHavePoopPurpose == true) then
  
        local selfPoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseSelf")), worldObjects, BathroomFunctions.DefecateSelf, player)
        addTooltip(selfPoopOption, "Defecate on yourself. Very few situations where this would be useful. (Requires " .. SandboxVars.BathroomFunctions.PoopOnSelfRequirement / 100 .. "%)")
        selfPoopOption.iconTexture = getTexture("media/ui/PoopedSelf.png");

        if defecateValue < (SandboxVars.BathroomFunctions.PeeOnGroundRequirement / 100) * bowelsMaxValue then
            groundPoopOption.notAvailable = true
        end
        if defecateValue < (SandboxVars.BathroomFunctions.PoopOnSelfRequirement / 100) * bowelsMaxValue then
            selfPoopOption.notAvailable = true
        end
    
    end

    -- Loop through world objects and check for toilets, urinals, and outhouses
    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)

        -- Using toilet
        if object:getTextureName() and luautils.stringStarts(object:getTextureName(), "fixtures_bathroom_01") and object:hasWater() and object:getSquare():DistToProper(player:getSquare()) < 1 then
            local toiletPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseToilet")), worldObjects, BathroomFunctions.PeeInToilet, player)
            local toiletPoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseToilet")), worldObjects, BathroomFunctions.PoopInToilet, player)

            if object:getWaterAmount() < 10.0 then
                toiletPoopOption.notAvailable = true
            end

            addTooltip(toiletPeeOption, "Urinate in the toilet. (Requires " .. SandboxVars.BathroomFunctions.PeeInToiletRequirement / 100 .. "% and sufficient water)")
            addTooltip(toiletPoopOption, "Defecate in the toilet. (Requires " .. SandboxVars.BathroomFunctions.PoopInToiletRequirement / 100 .. "% and sufficient water)")
            toiletOptionAdded = true

            toiletPeeOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png");
            toiletPoopOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png");

            if urinateValue < (SandboxVars.BathroomFunctions.PeeInToiletRequirement / 100) * bladderMaxValue then
                toiletPeeOption.notAvailable = true
            end
            if defecateValue < (SandboxVars.BathroomFunctions.PoopOnSelfRequirement / 100) * bowelsMaxValue then
                toiletPoopOption.notAvailable = true
            end
        end

        -- Using urinal
        if not player:isFemale() then
            for _, tile in ipairs(urinalTiles) do
                if object:getTextureName() == tile then
                    -- Pee option
                    local urinalPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseUrinal")), worldObjects, BathroomFunctions.PeeInToilet, player)
                    addTooltip(urinalPeeOption, "Urinate in the urinal. (Requires " .. SandboxVars.BathroomFunctions.PeeInToiletRequirement / 100 .. "%)")
                    toiletOptionAdded = true

                    if urinateValue < (SandboxVars.BathroomFunctions.PeeInToiletRequirement / 100) * bladderMaxValue then
                        urinalPeeOption.notAvailable = true
                    end

                    -- Poop option is always unavailable
                    local urinalPoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseUrinal")), worldObjects, nil, player)
                    addTooltip(urinalPoopOption, "Don't you fucking dare'.")
                    urinalPoopOption.notAvailable = true

                    urinalPeeOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png");
                    urinalPoopOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png");

                    break
                end
            end
        end

        -- Using outhouses
        for _, tile in ipairs(outhouseTiles) do
            if object:getTextureName() == tile then
                local outhousePeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseOuthouse")), worldObjects, BathroomFunctions.PeeInToilet, player)
                local outhousePoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseOuthouse")), worldObjects, BathroomFunctions.PoopInToilet, player)
                
                outhousePeeOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png");
                outhousePoopOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png");

                addTooltip(outhousePeeOption, "Urinate in the outhouse. (Requires " .. SandboxVars.BathroomFunctions.PeeInToiletRequirement / 100 .. "%)")
                addTooltip(outhousePoopOption, "Defecate in the outhouse. (Requires " .. SandboxVars.BathroomFunctions.PoopInToiletRequirement / 100 .. "%)")
                toiletOptionAdded = true

                if urinateValue < (SandboxVars.BathroomFunctions.PeeInToiletRequirement / 100) * bladderMaxValue then
                    outhousePeeOption.notAvailable = true
                end
                if defecateValue < (SandboxVars.BathroomFunctions.PoopOnSelfRequirement / 100) * bowelsMaxValue then
                    outhousePoopOption.notAvailable = true
                end

                break
            end
        end
    end
end





-- =====================================================
--
-- EVENT REGISTRATION
--
-- =====================================================

function BathroomFunctions.PeeInToilet(worldObjects, object, player)
	local player = getPlayer()
	local urinateValue = BathroomFunctions.GetUrinateValue()
	local peeTime = urinateValue

	ISTimedActionQueue.add(ToiletUrinate:new(player, peeTime, true, true, object))
end
function BathroomFunctions.PoopInToilet(worldObjects, object, player)
	local player = getPlayer()
	local defecateValue = BathroomFunctions.GetDefecateValue()
	local poopTime = defecateValue * 2

	ISTimedActionQueue.add(ToiletDefecate:new(player, poopTime, true, true, object))
end
function BathroomFunctions.PeeOnGround()
	--check if pants are down or unzipped, if so, go on ground, otherwise, go on self
	local player = getPlayer()
	local urinateValue = BathroomFunctions.GetUrinateValue()
	local peeTime = urinateValue

	ISTimedActionQueue.add(GroundUrinate:new(player, peeTime, true, true))
end
function BathroomFunctions.PoopOnGround()
	--check if pants are down or unzipped, if so, go on ground, otherwise, go on self
	local player = getPlayer()
	local defecateValue = BathroomFunctions.GetDefecateValue()
	local poopTime = defecateValue * 2

	ISTimedActionQueue.add(GroundDefecate:new(player, poopTime, true, true))
end
function BathroomFunctions.DefecateSelf()
    local player = getPlayer() -- Fetch the current player object
    local defecateValue = BathroomFunctions.GetDefecateValue() -- Current bowel level
    local poopTime = defecateValue / 4 -- Make this a quarter of the defecate value so the player isn't locked for long
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Get the max bowel value, default to 100 if not set

    -- Check if player has relevant clothing on and apply the "pooped bottoms" effects
    if BathroomFunctions.HasClothingOn(player, unpack(BathroomFunctions.GetSoilableClothing())) then
        BathroomFunctions.DefecateBottoms()
    else -- if the player doesn't wear clothing while pooping
        
    end

    ISTimedActionQueue.add(SelfDefecate:new(player, poopTime, false, false, true, false, nil))

    -- Set the defecate value to 0 as the player has defecated
    --BathroomFunctions.SetDefecateValue(0)

    print("Updated Pooped Self Value: " .. BathroomFunctions.GetPoopedSelfValue()) -- Debug print statement to display the updated defecation value
end
function BathroomFunctions.UrinateSelf()
    local player = getPlayer() -- Fetch the current player object
    local urinateValue = BathroomFunctions.GetUrinateValue() -- Current bladder level
	local peeTime = urinateValue / 4 -- Make this a quarter of the urinate value so the player isn't locked for long
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Get the max bladder value, default to 100 if not set

    -- Check if player has relevant clothing on and apply the "peed bottoms" effects
    if BathroomFunctions.HasClothingOn(player, unpack(BathroomFunctions.GetSoilableClothing())) then
        BathroomFunctions.UrinateBottoms()
    else -- if the player doesn't wear clothing while pooping
        if SandboxVars.BathroomFunctions.CreatePeeObject == true then
		    local urineItem = instanceItem("BathroomFunctions.HumanUrine_Large")
		    player:getCurrentSquare():AddWorldInventoryItem(urineItem, 0, 0, 0)
	    end
    end

    ISTimedActionQueue.add(SelfUrinate:new(player, peeTime, false, false, true, false, nil))

    -- Set the urinate value to 0 as the player has urinated
    --BathroomFunctions.SetUrinateValue(0)

    print("Updated Peed Self Value: " .. BathroomFunctions.GetPeedSelfValue()) -- Debug print statement to display the updated urination value
end





-- =====================================================
--
-- EVENT REGISTRATION
--
-- =====================================================

function BathroomFunctions.onGameBoot()
    local humanGroup = BodyLocations.getGroup("Human"); -- Get the BodyLocations group for humans
    local peedUndiesLocation = humanGroup:getOrCreateLocation("PeedOverlay"); -- Create or fetch the PeedOverlay location
    local peedPantsLocation = humanGroup:getOrCreateLocation("PeedOverlay2"); -- Create or fetch the PeedOverlay location

    -- Remove PeedOverlay if it already exists to avoid duplication
    local list = getClassFieldVal(humanGroup, getClassField(humanGroup, 1));
    list:remove(peedUndiesLocation);

    -- Remove PeedOverlay2 if it already exists to avoid duplication
    local list = getClassFieldVal(humanGroup, getClassField(humanGroup, 1));
    list:remove(peedPantsLocation);

    -- Find the index of Pants to ensure PeedOverlay renders above it
    local pantsIndex = humanGroup:indexOf("Pants");

    -- Add PeedOverlay just after Pants
    list:add(pantsIndex + 1, peedUndiesLocation);

    -- Add PeedOverlay2 just after PeedOverlay
    list:add(pantsIndex + 2, peedPantsLocation);
end


--[[
Register the BathroomFunctionTimers function to run every 10 in-game minutes
This ensures bathroom values are periodically updated.
]]--
Events.EveryTenMinutes.Add(BathroomFunctions.BathroomFunctionTimers)

Events.OnGameBoot.Add(BathroomFunctions.onGameBoot)

Events.OnFillWorldObjectContextMenu.Add(BathroomFunctions.BathroomRightClick)