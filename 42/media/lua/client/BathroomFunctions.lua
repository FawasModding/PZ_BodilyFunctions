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
        BathroomFunctions.UpdateBathroomValues() -- If the initial setup is done, update the player's bathroom values
        BathroomFunctions.HandleInstantAccidents() -- Check whether or not the player has urinated or defecated themselves.
        BathroomFunctions.HandleUrgencyHiccup() -- Do the hiccup system, aka player grabbing crotch and possibly pissing themselves or so on. Too tired to censor my shit lol
        BathroomFunctions.DirtyBottomsEffects()
    else
        BathroomFunctions.didFirstTimer = true -- If this is the first call, set the flag to true and skip updating values
    end
end

-- Function to update the player's bathroom-related values (urination and defecation)
function BathroomFunctions.UpdateBathroomValues()
    local player = getPlayer()
    local stats = player:getStats()

    -- Update Bladder Values
    local urinateValue = BathroomFunctions.GetUrinateValue()
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 500
    local thirst = stats:getThirst()

    --local urinateIncrease = 0.012 * bladderMaxValue * (1 - thirst) * SandboxVars.BathroomFunctions.BladderIncreaseMultiplier
    local urinateIncrease = 0.012 * bladderMaxValue * SandboxVars.BathroomFunctions.BladderIncreaseMultiplier
    urinateValue = urinateValue + urinateIncrease
    player:getModData().urinateValue = tonumber(urinateValue)

    -- Update Bowel Values
    local defecateValue = BathroomFunctions.GetDefecateValue()
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 800
    local hunger = stats:getHunger()

    --local defecateIncrease = 0.005 * bowelsMaxValue * (1 - hunger) * SandboxVars.BathroomFunctions.BowelsIncreaseMultiplier
    local defecateIncrease = 0.005 * bowelsMaxValue * SandboxVars.BathroomFunctions.BowelsIncreaseMultiplier
    defecateValue = defecateValue + defecateIncrease
    player:getModData().defecateValue = tonumber(defecateValue)

    -- Print Debug Info
    print("Updated Urinate Value: " .. tostring((urinateValue / bladderMaxValue) * 100) .. "%")
    print("Updated Defecate Value: " .. tostring((defecateValue / bowelsMaxValue) * 100) .. "%")
end

-- Make the player urinate / defecate in very "sudden" situations.
-- Like, getting injured (car crash, shot). Overflowing (bladder max capacity).
function BathroomFunctions.HandleInstantAccidents()
    local urinateValue = BathroomFunctions.GetUrinateValue() -- Current bladder level
    local defecateValue = BathroomFunctions.GetDefecateValue() -- Current bowel level
    local player = getPlayer()

    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Default to 100 if not set
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Default to 100 if not set

    -- Calculate overflow values
    local bladderThreshold = 0.95 * bladderMaxValue -- 95% of max bladder value
    local bowelsThreshold = 0.98 * bowelsMaxValue -- 98% of max bowel value

    -- Handle urination and defecation when the player is asleep or awake.
    -- If the player is asleep and their bladder/bowels are full, it happens automatically and wakes them up.
    -- If the player is awake and their bladder/bowels are full, the appropriate self-action (urinate/defecate) begins.
    if player:isAsleep() then

        -- Check if the player needs to urinate while asleep
        if urinateValue >= bladderThreshold then
            player:forceAwake()  -- Wake the player up if they need to urinate

            -- If the player has the "Bedwetter" trait, trigger the urination accident
            if player:HasTrait("Bedwetter") then
                BathroomFunctions.UrinateBottoms()  -- Simulate urinating in bed
                BathroomFunctions.SetUrinateValue(0)  -- Reset urinate value after accident
            end

        -- Check if the player needs to defecate while asleep
        elseif defecateValue >= bowelsThreshold then
            player:forceAwake()  -- Wake the player up if they need to defecate

            -- If the player has the "Bedsoiler" trait, trigger the defecation accident
            if player:HasTrait("Bedsoiler") then
                BathroomFunctions.DefecateBottoms()  -- Simulate defecating in bed
                BathroomFunctions.SetDefecateValue(0)  -- Reset defecate value after accident
            end

        end
    else
        -- If the player is awake, start the urination or defecation process based on their bladder/bowel status
        if urinateValue >= bladderThreshold then
            BathroomFunctions.TriggerSelfUrinate()  -- Trigger self urination action
        elseif defecateValue >= bowelsThreshold then
            BathroomFunctions.TriggerSelfDefecate()  -- Trigger self defecation action
        end
    end
end

-- Function to handle the hiccup system. Every 10 minutes, this checks if the player should have a ""hiccup".
-- Hiccup in this context is the slang definition, like a pause. Not a "hic" hiccup lol
function BathroomFunctions.HandleUrgencyHiccup()
    local player = getPlayer()
    local urinateValue = BathroomFunctions.GetUrinateValue()
    local defecateValue = BathroomFunctions.GetDefecateValue()
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 500
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 800

    -- Base Hiccup Chance (until bladder/bowels are above 80% full)
    local hiccupChance = 0 -- Base 0% chance

    -- If the player is asleep, set hiccupChance to 0 regardless of bladder/bowel status
    if player:isAsleep() then
        hiccupChance = 0
    else
        -- Increase chance if bladder or bowels are 80% full or more
        if urinateValue >= 0.8 * bladderMaxValue or defecateValue >= 0.8 * bowelsMaxValue then
            hiccupChance = 10 -- 10% chance
        end

        -- Panic modifier: increase hiccup chance if the player is panicked
        if player:getMoodles():getMoodleLevel(MoodleType.Panic) > 0 then
            hiccupChance = hiccupChance + (player:getMoodles():getMoodleLevel(MoodleType.Panic) * 2)  -- Increase by Panic level
        end
    end

    -- Print the hiccup chance each time it activates
    print("Hiccup Chance: " .. hiccupChance .. "%")

    -- Hiccup will only trigger if bladder or bowels are 40% or more full
    if ZombRand(100) < hiccupChance then
        local hiccupType = nil
        
        if urinateValue >= 0.4 * bladderMaxValue then
            hiccupType = "bladder"
        elseif defecateValue >= 0.4 * bowelsMaxValue then
            hiccupType = "bowels"
        end

        -- ====================================================================
        -- THIS HERE, THIS IS THE SHIT. THIS IS WHERE IT ACTUALLY HAPPENS!!!!
        -- ====================================================================

        if hiccupType then
            -- Trigger Hiccup and inform the type
            print("Urgency Hiccup Occurred! Hiccup Type: " .. hiccupType)
            player:Say("Oh no, I can't hold it!")
            
            -- This is where other stuff happens when the hiccup is happening
            
            -- Pass the hiccup type to PlayUrgencyIdles for the correct animation
            BathroomFunctions.PlayUrgencyIdles(hiccupType, true)

            -- Accident Chance (trigger accident if player is too full)
            local accidentChance = 5 -- Base 5% chance
            if player:getStats():getDrunkenness() > 0 then
                accidentChance = accidentChance + 10 -- Drunk modifier
            end

            if ZombRand(100) < accidentChance then
                if urinateValue >= 0.4 * bladderMaxValue then
                    BathroomFunctions.TriggerSelfUrinate()
                elseif defecateValue >= 0.4 * bowelsMaxValue then
                    BathroomFunctions.TriggerSelfDefecate()
                end
            end
        end
    end
end

-- Function for playing urgency idle animations based on hiccup type.
-- TODO: Make the speed value change depending on urination / defecation value. So slight urge makes it go quickly, bad urge makes them hold longer
function BathroomFunctions.PlayUrgencyIdles(hiccupType, doTimedAction)
    local player = getPlayer()

    -- Based on the hiccupType (bladder or bowels), play the corresponding animation
    if hiccupType == "bladder" then
        print("Playing Urgent Pee Animation!")
        player:playerVoiceSound("PainFromGlassCut")  -- Replace this with specific pee sound if you want
        ISTimedActionQueue.add(Idle_PeeUrgency:new(player, 40, false, true))  -- Trigger bladder urgency animation
    elseif hiccupType == "bowels" then
        print("Playing Urgent Poop Animation!")
        player:playerVoiceSound("PainFromGlassCut")  -- Replace this with specific poop sound if needed
        ISTimedActionQueue.add(Idle_PoopUrgency:new(player, 40, false, true))  -- Trigger bowel urgency animation
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
            BathroomFunctions.UpdateSoiledSeverity(clothing)

            if SandboxVars.BathroomFunctions.ShowPeeStain == true then
                BathroomClothOverlays.OnClothingChanged(player)
            end
        end
    end

    if SandboxVars.BathroomFunctions.CreatePeeObject == true then
		local urineItem = instanceItem("BathroomFunctions.Urine_Hydrated_0")
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
            BathroomFunctions.UpdateSoiledSeverity(clothing)
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

        -- Ensure the item is not nil before calling UpdateSoiledSeverity
        if item ~= nil then
            -- Update values for pooped and peed states based on item mod data
            local itemUpdatedPooped, itemUpdatedPeed = BathroomFunctions.UpdateSoiledSeverity(item)

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

-- FOR CLOTHING SPECIFICALYY
function BathroomFunctions.UpdateSoiledSeverity(clothing)
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
        print("Error: Clothing or mod data is nil in UpdateSoiledSeverity.")
    end

    -- Debugging output
    --print("Updated PeedSelfValue: " .. BathroomFunctions.GetPeedSelfValue())
    --print("Updated PoopedSelfValue: " .. BathroomFunctions.GetPoopedSelfValue())

    return updatedPooped, updatedPeed
end

-- =====================================================
--
-- DIRTIED ITEMS FUNCTIONS
--
-- =====================================================

-- FOR ITEMS IN GENERAL
function BathroomFunctions.SetClothing(item)
    local cleanName = nil

    -- Check if the item name contains a parenthesis, for status modifier (like "(Peed)" or "(Pooped)")
    if (string.find(item:getName(), "%(")) then
        local startIndex = string.find(item:getName(), "%(")
        -- Get base name of the item (without the status modifier in parentheses)
        cleanName = string.sub(item:getName(), 0, startIndex - 2)
    else
        cleanName = item:getName()
    end

    -- Store the original clean name of the item in its mod data
    item:getModData().originalName = cleanName


    -- If the item is marked as "peed" (wet), modify the item's properties
    if item:getModData().peed == true then

        local peedSeverity = string.format("%.1f", item:getModData().peedSeverity)
        -- Update the name to include the "(Peed)" status
        item:setName(cleanName .. " (Peed " .. peedSeverity .. "%)")

        -- Only apply clothing modifiers if clothing
        if item:IsClothing() then
            -- Set the wetness to maximum (500) to indicate the item is soaked
            item:setWetness(500)
            -- Set the dirtyness to maximum (100)
            item:setDirtyness(100)
        end

    end

    -- If the item is marked as "pooped" (dirty), modify the item's properties
    if item:getModData().pooped == true then

        local poopedSeverity = string.format("%.1f", item:getModData().poopedSeverity)
        -- Update the name to include the "(Pooped)" status
        item:setName(cleanName .. " (Pooped " .. poopedSeverity .. "%)")

        -- Only apply clothing modifiers if clothing
        if item:IsClothing() then
            -- Set the dirtyness to maximum (100)
            item:setDirtyness(100)
            -- Reduce the player's run speed to simulate having poop in the clothing
            item:setRunSpeedModifier(item:getRunSpeedModifier() - 0.2) -- slower movement, but may not be very noticeable
        end
        
    end


    -- If both "peed" and "pooped" statuses are true, update the item name to reflect both conditions
    if item:getModData().peed and item:getModData().pooped then
        local peedSeverity = string.format("%.1f", item:getModData().peedSeverity)
        local poopedSeverity = string.format("%.1f", item:getModData().poopedSeverity)
        item:setName(cleanName .. " (Peed " .. peedSeverity .. "%" .. " & " .. "Pooped " .. poopedSeverity .. "%)")
    end
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

    local peeOnSelfRequirement = SandboxVars.BathroomFunctions.PeeOnSelfRequirement or 85 -- Default to 85 if not set
    local peeOnGroundRequirement = SandboxVars.BathroomFunctions.PeeOnGroundRequirement or 50 -- Default to 50 if not set
    local peeInToiletRequirement = SandboxVars.BathroomFunctions.PeeInToiletRequirement or 40 -- Default to 40 if not set
    local peeInContainerRequirement = SandboxVars.BathroomFunctions.PeeInContainerRequirement or 60 -- Default to 70 if not set

    local poopOnSelfRequirement = SandboxVars.BathroomFunctions.PoopOnSelfRequirement or 75 -- Default to 75 if not set
    local poopOnGroundRequirement = SandboxVars.BathroomFunctions.PoopOnGroundRequirement or 50 -- Default to 50 if not set
    local poopInToiletRequirement = SandboxVars.BathroomFunctions.PoopInToiletRequirement or 40 -- Default to 40 if not set

    local modOptions = PZAPI.ModOptions:getOptions("BathroomFunctions")

    -------------------------------------------------------------------------------------------------------------------

    -- Main menu option: "Urination"
    local peeOption = context:addOption(getText("ContextMenu_Urinate"), worldObjects, nil)
    local peeSubMenu = ISContextMenu:getNew(context)
    context:addSubMenu(peeOption, peeSubMenu)
    peeOption.iconTexture = getTexture("media/ui/Urination.png")

    -- Main menu option: "Defecation"
    local poopOption = context:addOption(getText("ContextMenu_Defecate"), worldObjects, nil)
    local poopSubMenu = ISContextMenu:getNew(context)
    context:addSubMenu(poopOption, poopSubMenu)
    poopOption.iconTexture = getTexture("media/ui/Defecation.png")

    -------------------------------------------------------------------------------------------------------------------

    -- Tooltips function
    local function addTooltip(option, description)
        if option then
            local tooltip = ISToolTip:new()
            tooltip:initialise()
            tooltip:setVisible(false)
            tooltip.description = description
            option.toolTip = tooltip
        end
    end

    -------------------------------------------------------------------------------------------------------------------

    -- Using Ground
    local groundPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseGround")), worldObjects, BathroomFunctions.TriggerGroundUrinate, player)
    addTooltip(groundPeeOption, "Urinate on the ground. (Requires " .. peeOnGroundRequirement .. "%)")
    groundPeeOption.iconTexture = getTexture("media/textures/ContextMenuGround.png");

    local groundPoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseGround")), worldObjects, BathroomFunctions.TriggerGroundDefecate, player)
    addTooltip(groundPoopOption, "Defecate on the ground. (Requires " .. poopOnGroundRequirement .. "%)")
    groundPoopOption.iconTexture = getTexture("media/textures/ContextMenuGround.png");

    if urinateValue < (peeOnGroundRequirement / 100) * bladderMaxValue then
        groundPeeOption.notAvailable = true
    end
    if defecateValue < (peeOnGroundRequirement / 100) * bowelsMaxValue then
        groundPoopOption.notAvailable = true
    end

    -- Wiping

    -- Ensure options are enabled/disabled based on available wipeables
    local wipeType, item = BathroomFunctions.CheckForWipeables(player)

    local wipeTooltipSource = "ContextMenu_WipeWith"

    -- Determine action based on the returned type
    if wipeType == "usingDrainable" then
        wipeTooltipSource = "ContextMenu_tooltip_WipeDrainable"

    elseif wipeType == "usingOneTime" then
        wipeTooltipSource = "ContextMenu_tooltip_WipeOther"

    elseif wipeType == "usingClothing" then
        wipeTooltipSource = "ContextMenu_tooltip_WipeClothing"
    end

    -- Create the "Wipe" submenu
    local wipeSubMenu = ISContextMenu:getNew(poopSubMenu)
    poopSubMenu:addSubMenu(groundPoopOption, wipeSubMenu)

    -- Create the "Don't Wipe" option and add it to the submenu
    local dontWipeOption = wipeSubMenu:addOption(getText("ContextMenu_DontWipe"), worldObjects, nil)
    addTooltip(dontWipeOption, "Choose not to wipe after defecating.")

    -- Add "Wipe With" option to the submenu
    local doWipeOption = wipeSubMenu:addOption(getText("ContextMenu_WipeWith") .. item:getName(), worldObjects, nil)
    addTooltip(doWipeOption, getText(wipeTooltipSource))


    -------------------------------------------------------------------------------------------------------------------

    -- Using Self

    local canPeeSelfOption = modOptions:getOption("2")
    if(canPeeSelfOption:getValue(1)) then

        local selfPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseSelf")), worldObjects, BathroomFunctions.TriggerSelfUrinate, player)
        addTooltip(selfPeeOption, "Urinate on yourself. Very few situations where this would be useful. (Requires " .. peeOnSelfRequirement .. "%)")
        selfPeeOption.iconTexture = getTexture("media/ui/PeedSelf.png");

        -- Disable "On Self" pee options if urinateValue too low
        if urinateValue < (peeOnSelfRequirement / 100) * bladderMaxValue then
            selfPeeOption.notAvailable = true
        end

    end

    local canPoopSelfOption = modOptions:getOption("3")
    if(canPoopSelfOption:getValue(1)) then
  
        local selfPoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseSelf")), worldObjects, BathroomFunctions.TriggerSelfDefecate, player)
        addTooltip(selfPoopOption, "Defecate on yourself. Very few situations where this would be useful. (Requires " .. poopOnSelfRequirement .. "%)")
        selfPoopOption.iconTexture = getTexture("media/ui/PoopedSelf.png");

        if defecateValue < (poopOnSelfRequirement / 100) * bowelsMaxValue then
            selfPoopOption.notAvailable = true
        end
    
    end

    -------------------------------------------------------------------------------------------------------------------

    -- Using Toilets

    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)

        -- Using toilet
        --if object:getTextureName() and luautils.stringStarts(object:getTextureName(), "fixtures_bathroom_01") and object:hasWater() and object:getSquare():DistToProper(player:getSquare()) < 1 then
        if object:getTextureName() and luautils.stringStarts(object:getTextureName(), "fixtures_bathroom_01") and object:getSquare():DistToProper(player:getSquare()) < 5 then
            local toiletPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseToilet")), object, BathroomFunctions.TriggerToiletUrinate, player)
            local toiletPoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseToilet")), object, BathroomFunctions.TriggerToiletDefecate, player)

            --if object:getWaterAmount() < 10.0 then
            --    toiletPoopOption.notAvailable = true
            --end

            --addTooltip(toiletPeeOption, "Urinate in the toilet. (Requires " .. peeInToiletRequirement .. "% and sufficient water)")
            --addTooltip(toiletPoopOption, "Defecate in the toilet. (Requires " .. poopInToiletRequirement .. "% and sufficient water)")
            addTooltip(toiletPeeOption, "Urinate in the toilet. (Requires " .. peeInToiletRequirement .. "%")
            addTooltip(toiletPoopOption, "Defecate in the toilet. (Requires " .. poopInToiletRequirement .. "%")
            toiletOptionAdded = true

            toiletPeeOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png");
            toiletPoopOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png");

            if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue then
                toiletPeeOption.notAvailable = true
            end
            if defecateValue < (poopInToiletRequirement / 100) * bowelsMaxValue then
                toiletPoopOption.notAvailable = true
            end
        end

        -- Using urinal
        if not player:isFemale() then
            for _, tile in ipairs(urinalTiles) do
                if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                    -- Pee option
                    local urinalPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseUrinal")), object, BathroomFunctions.TriggerToiletUrinate, player)
                    addTooltip(urinalPeeOption, "Urinate in the urinal. (Requires " .. peeInToiletRequirement .. "%)")
                    toiletOptionAdded = true

                    if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue then
                        urinalPeeOption.notAvailable = true
                    end

                    -- Poop option is always unavailable
                    local urinalPoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseUrinal")), object, nil, player)
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
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local outhousePeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseOuthouse")), object, BathroomFunctions.TriggerToiletUrinate, player)
                local outhousePoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseOuthouse")), object, BathroomFunctions.TriggerToiletDefecate, player)
                
                outhousePeeOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png");
                outhousePoopOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png");

                addTooltip(outhousePeeOption, "Urinate in the outhouse. (Requires " .. peeInToiletRequirement .. "%)")
                addTooltip(outhousePoopOption, "Defecate in the outhouse. (Requires " .. poopInToiletRequirement .. "%)")
                toiletOptionAdded = true

                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue then
                    outhousePeeOption.notAvailable = true
                end
                if defecateValue < (poopInToiletRequirement / 100) * bowelsMaxValue then
                    outhousePoopOption.notAvailable = true
                end

                break
            end
        end
    end

    -------------------------------------------------------------------------------------------------------------------

    -- Using Containers (Pee)

    local canPeeContainerOption = modOptions:getOption("1")
    if(canPeeContainerOption:getValue(1)) then

        local containerPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseContainer")), worldObjects, nil)
        addTooltip(containerPeeOption, "Urinate in a container. (Requires " .. peeInContainerRequirement .. "%)")

        local containerSubMenu = ISContextMenu:getNew(peeSubMenu) -- Create submenu
        peeSubMenu:addSubMenu(containerPeeOption, containerSubMenu) -- Attach submenu to `containerPeeOption`
        containerPeeOption.iconTexture = getTexture("media/textures/Item_BottleOfPee.png");

        local hasValidContainers = false

        for i = 0, player:getInventory():getItems():size() - 1 do
            local item = player:getInventory():getItems():get(i)
            if item:getFluidContainer() and item:getFluidContainer():isEmpty() then
                -- Add a valid pee option for each empty container
                containerSubMenu:addOption("Use " .. item:getName(), item, BathroomFunctions.PeeInContainer)
                hasValidContainers = true
            end
        end

        -- Make the "Use Container" option unavailable if no valid containers are found or pee in container requirement not met
        if urinateValue < (peeInContainerRequirement / 100) * bladderMaxValue then
            containerPeeOption.notAvailable = true
        end
    end
    -------------------------------------------------------------------------------------------------------------------
end

function BathroomFunctions.WashingRightClick(player, context, worldObjects)
	local player = getPlayer()

	local hasSoiledItem = false
	local soiledItemEquipped = false
	local soiledItem = nil
	local soapItem = nil

	for i = 0, player:getInventory():getItems():size() - 1 do
		local item = player:getInventory():getItems():get(i)
		
		if item:getType() == "Soap2" then
			soapItem = item
		end

		if item:getModData().peed == true or item:getModData().pooped == true then --If peed/pooped item
			hasSoiledItem = true
			if (item:isEquipped()) then
				soiledItemEquipped = true
			end
			soiledItem = item
		end
	end

	if hasSoiledItem then
		local storeWater = nil
		local firstObject = nil
		for _, o in ipairs(worldObjects) do
			if not firstObject then firstObject = o end
		end

		local square = firstObject:getSquare()
		local worldObjects = square:getObjects()
		for i = 0, worldObjects:size() - 1 do
			local object = worldObjects:get(i)
			if (object:getTextureName() and object:hasWater()) then --Anything that can usually be used to wash
				storeWater = object
			end
		end

		if storeWater == nil then
			return
		end
		
		if storeWater:getSquare():DistToProper(player:getSquare()) > 10 then
			return
		end

		local washOption = context:addOptionOnTop("Wash Soiled Clothing", nil, nil)
        washOption.iconTexture = getTexture("media/ui/PeedSelf.png");
		local subMenu = ISContextMenu:getNew(context)
		context:addSubMenu(washOption, subMenu)
		local option = subMenu:addOption(soiledItem:getName(), player, BathroomFunctions.WashSoiled, square, soiledItem, soapItem, storeWater, soiledItemEquipped)


		local waterRemaining = storeWater:getWaterAmount()
		
		if (waterRemaining < 15) then
			option.notAvailable = true --Not enough water
		end

        if soiledItem:getModData().pooped then -- Only require soap if soiled clothing is pooped
            if soapItem == nil or soapItem:getCurrentUses() <= 0 then
                option.notAvailable = true -- Not enough soap / no soap
            else
                local soapText = "0"
            end
        end

		--local tooltip = ISWorldObjectContextMenu.addToolTip()
		--tooltip.description = getText("ContextMenu_WaterSource") .. ": " .. source
		--tooltip.description = tooltip.description .. " <LINE> Water: " .. tostring(math.min(waterRemaining, 15)) .. " / " .. tostring(15)
		--tooltip.description = tooltip.description .. " <LINE> Bleach: " .. bleachText .. " / 0.3"
		--tooltip.description = tooltip.description .. " <LINE> Dirty: " .. math.ceil(defecatedItem:getDirtyness()) .. " / 100"
		--option.toolTip = tooltip
	end
end

function BathroomFunctions.CleaningRightClick(player, context, worldObjects)
    local playerObj = getSpecificPlayer(player)
    local inventory = playerObj:getInventory()

    local potentialCleaningItems = {"Mop", "ToiletBrush", "DishCloth", "BathTowel"}
    local urinePuddle = false
    local puddleToRemove = nil  -- Store puddle item to remove later
    local puddleSquare = nil    -- Store square where the puddle is located
    local detectionRadius = 2

    -- Search for urine puddles nearby
    local playerSquare = playerObj:getSquare()
    if playerSquare then
        for dx = -detectionRadius, detectionRadius do
            for dy = -detectionRadius, detectionRadius do
                local nearbySquare = getCell():getGridSquare(playerSquare:getX() + dx, playerSquare:getY() + dy, playerSquare:getZ())
                if nearbySquare then
                    for i = 0, nearbySquare:getObjects():size() - 1 do
                        local item = nearbySquare:getObjects():get(i)
                        if item and item:getObjectName() == "WorldInventoryItem" then
                            local worldItem = item:getItem()
                            if worldItem and worldItem:getType() == "Urine_Hydrated_0" then
                                urinePuddle = true
                                puddleToRemove = item
                                puddleSquare = nearbySquare
                                break
                            end
                        end
                    end
                end
                if urinePuddle then break end
            end
            if urinePuddle then break end
        end
    end

    -- If a urine puddle was found, add cleaning options
    if urinePuddle and puddleSquare and puddleToRemove then
        for _, itemName in ipairs(potentialCleaningItems) do
            -- Check if the player has any cleaning item in the inventory
            if inventory:contains(itemName) then
                local cleaningItem = inventory:getFirstType(itemName)  -- Get the first item of this type

                -- Add context menu option for cleaning
                local cleanOption = context:addOption("Clean Urine With " .. itemName, worldObjects, function()

                    -- Timed action to walk to the puddle's square'
                    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, puddleSquare))

                    -- Trigger the cleaning Timed Action with the correct cleaning item
                    ISTimedActionQueue.add(CleanWasteProduct:new(playerObj, 150, puddleSquare, puddleToRemove, cleaningItem)) -- 150 = duration

                end)
                cleanOption.iconTexture = getTexture("media/textures/Mop.png");

                return
            end
        end
    end
end

function BathroomFunctions.CheckForWipeables(player)
    local showWipeOption = false

    -- Ensure constants or types are defined
    local usingDrainable = "usingDrainable"
    local usingOneTime = "usingOneTime"
    local usingClothing = "usingClothing"

    -- Check for drainable items (e.g., Toilet Paper)
    local drainableItems = BathroomFunctions.GetDrainableWipeables()
    for _, itemType in ipairs(drainableItems) do
        local items = player:getInventory():getItems()  -- Get player's inventory items
        for i = 0, items:size() - 1 do
            local item = items:get(i)

            if item:getType() == itemType and item:getCurrentUsesFloat() >= 1 then
                showWipeOption = true
                return usingDrainable, item  -- Return early with wipeType and item
            end
        end
    end

    -- Check for non-drainable wipeables (e.g., Tissue, Paper Napkins, etc.)
    local nonDrainableItems = BathroomFunctions.GetOneTimeWipeables()
    for _, itemType in ipairs(nonDrainableItems) do
        local items = player:getInventory():getItems()  -- Get player's inventory items
        for i = 0, items:size() - 1 do
            local item = items:get(i)

            if item:getType() == itemType then
                showWipeOption = true
                return usingOneTime, item  -- Return early with wipeType and item
            end
        end
    end

    -- Check for clothing wipeables (e.g., Bra, Underwear.)
    local clothingWipeables = BathroomFunctions.GetClothingWipeables()
    for _, bodyLocation in ipairs(clothingWipeables) do
        local items = player:getInventory():getItems()  -- Get player's inventory items
        for i = 0, items:size() - 1 do
            local item = items:get(i)

            if item:IsClothing() and item:getBodyLocation() == bodyLocation then
                showWipeOption = true
                return usingClothing, item  -- Return early with wipeType and item
            end
        end
    end

    return nil, nil  -- Explicitly return nil for both wipeType and item if no wipeable item is found
end

-- =====================================================
--
-- EVENT REGISTRATION
--
-- =====================================================

function BathroomFunctions.RemoveBottomClothing(player)
    local removedClothing = {}

    -- Get the list of excretion obstructive clothing body locations
    local excreteObstructive = BathroomFunctions.GetExcreteObstructiveClothing()

    for _, location in ipairs(excreteObstructive) do
        local clothingItem = player:getWornItem(location)
        if clothingItem then
            -- Store the removed item in the array
            table.insert(removedClothing, clothingItem)

            -- Remove the clothing with a timed action
            ISTimedActionQueue.add(ISUnequipAction:new(player, clothingItem, 50))
        end
    end

    -- Store the removed items in the player's mod data for later re-equipping
    player:getModData().removedClothing = removedClothing
end
function BathroomFunctions.ReequipBottomClothing(player)
    local removedClothing = player:getModData().removedClothing

    if removedClothing then
        -- Re-equip each clothing item taken off before
        for _, clothingItem in ipairs(removedClothing) do
            if clothingItem then
                -- Add the item back to the player with a timed action
                ISTimedActionQueue.add(ISWearClothing:new(player, clothingItem))
            end
        end
    end

     BathroomFunctions.ResetRemovedClothing(player)
end
function BathroomFunctions.ResetRemovedClothing(player)
    -- Clear the removed clothing list
    player:getModData().removedClothing = nil
end


function BathroomFunctions.TriggerToiletUrinate(object, player)
    local player = getPlayer()
    local urinateValue = BathroomFunctions.GetUrinateValue()
    local peeTime = urinateValue

    -- Walk to toilet
    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, object))

    -- If female, must take off clothing. Males would just unzip their pants.
    if player:isFemale() == true then
        -- Remove bottom clothing first
        BathroomFunctions.RemoveBottomClothing(player)
    end

    -- Urinate at the toilet
    ISTimedActionQueue.add(ToiletUrinate:new(player, peeTime, true, true, object))
end

function BathroomFunctions.TriggerToiletDefecate(object, player)
    local player = getPlayer()
    local defecateValue = BathroomFunctions.GetDefecateValue()
    local poopTime = defecateValue * 2

    -- Walk to toilet
    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, object))

    -- Remove bottom clothing first
    BathroomFunctions.RemoveBottomClothing(player)

    -- Defecate at the toilet
    ISTimedActionQueue.add(ToiletDefecate:new(player, poopTime, true, true, object))
end

function BathroomFunctions.TriggerGroundUrinate()
    local player = getPlayer()
    local urinateValue = BathroomFunctions.GetUrinateValue()
    local peeTime = urinateValue

    -- If female, must take off clothing. Males would just unzip their pants.
    if player:isFemale() == true then
        -- Remove bottom clothing first
        BathroomFunctions.RemoveBottomClothing(player)
    end

    -- Urinate on the ground
    ISTimedActionQueue.add(GroundUrinate:new(player, peeTime, true, true))
end

function BathroomFunctions.TriggerGroundDefecate()
    local player = getPlayer()
    local defecateValue = BathroomFunctions.GetDefecateValue()
    local poopTime = defecateValue * 2

    -- Remove bottom clothing first
    BathroomFunctions.RemoveBottomClothing(player)

    -- Defecate on the ground
    ISTimedActionQueue.add(GroundDefecate:new(player, poopTime, true, true))
end
function BathroomFunctions.TriggerSelfDefecate()
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
function BathroomFunctions.TriggerSelfUrinate()
    local player = getPlayer() -- Fetch the current player object
    local urinateValue = BathroomFunctions.GetUrinateValue() -- Current bladder level
	local peeTime = urinateValue / 4 -- Make this a quarter of the urinate value so the player isn't locked for long
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Get the max bladder value, default to 100 if not set

    -- Check if player has relevant clothing on and apply the "peed bottoms" effects
    if BathroomFunctions.HasClothingOn(player, unpack(BathroomFunctions.GetSoilableClothing())) then
        BathroomFunctions.UrinateBottoms()
    else -- if the player doesn't wear clothing while pooping
        if SandboxVars.BathroomFunctions.CreatePeeObject == true then
		    local urineItem = instanceItem("BathroomFunctions.Urine_Hydrated_0")
		    player:getCurrentSquare():AddWorldInventoryItem(urineItem, 0, 0, 0)
	    end
    end

    ISTimedActionQueue.add(SelfUrinate:new(player, peeTime, false, false, true, false, nil))

    -- Set the urinate value to 0 as the player has urinated
    --BathroomFunctions.SetUrinateValue(0)

    print("Updated Peed Self Value: " .. BathroomFunctions.GetPeedSelfValue()) -- Debug print statement to display the updated urination value
end
function BathroomFunctions.PeeInContainer(item)
    local fluidContainer = item:getFluidContainer() -- Access the container
    local containerCapacity = fluidContainer:getCapacity() * 1000 -- Convert from L to mL (if it's in L)
    local bladderUrine = BathroomFunctions.GetUrinateValue() -- Get bladder urine amount

    -- Calculate the amount to transfer
    local amountToFill = math.min(containerCapacity, bladderUrine)

    -- Fill the bottle with the calculated amount
    fluidContainer:addFluid("Urine", amountToFill)

    -- Update the bladder to reflect the remaining urine
    local remainingBladderUrine = bladderUrine - amountToFill
    BathroomFunctions.SetUrinateValue(remainingBladderUrine)

    -- Debugging statements to verify the process
    --print("Peeing in container: " .. item:getName())
    --print("Amount filled: " .. amountToFill .. " mL")
    --print("Remaining bladder urine: " .. remainingBladderUrine .. " mL")
end

function BathroomFunctions.WashSoiled(playerObj, square, soiledItem, bleachItem, storeWater, soiledItemEquipped)
	if not square or not luautils.walkAdj(playerObj, square, true) then
		return
	end

	if soiledItemEquipped then --Unequip soiled clothing before washing
		ISTimedActionQueue.add(ISUnequipAction:new(playerObj, soiledItem, 50))
	end
	
	ISTimedActionQueue.add(WashSoiled:new(playerObj, 400, square, soiledItem, bleachItem, storeWater))
end
function BathroomFunctions.CleanUrine()

end

-- Overwriting the base grab function so that you cannot pick up human urine
-- TODO: Remove display name for urine so it doesn't show in the inventory, and implement custom cleaning mechanic with mop
ISGrabItemAction.o_transferItem = ISGrabItemAction.transferItem

function ISGrabItemAction:transferItem(item)
    local itemObject = item:getItem()
    if itemObject:getType() == "Urine_Hydrated_0" then
        self.character:Say("I'll need to clean this up.")
        print("Blocked picking up Urine_Hydrated_0!")
    else
        self:o_transferItem(item)
    end
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
Events.OnFillWorldObjectContextMenu.Add(BathroomFunctions.WashingRightClick)
Events.OnFillWorldObjectContextMenu.Add(BathroomFunctions.CleaningRightClick)