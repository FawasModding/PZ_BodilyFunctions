BF = BF or {}
BF.didFirstTimer = false

local InventoryUI = require("Starlit/client/ui/InventoryUI")

-- Set BowelsMaxValue and BladderMaxValue
-- Make sure the player is loaded.
-- Define your override function first.
function BF.OverrideSandboxMax()
    local player = getSpecificPlayer(0)  -- using getSpecificPlayer(0) for singleplayer
    if player then
        local baseBladderMax = BF.GetMaxBladderValue()
        local baseBowelsMax  = BF.GetMaxBowelValue()

        if player:HasTrait("SmallBladder") then
            SandboxVars.BathroomFunctions.BladderMaxValue = baseBladderMax * 0.75
        elseif player:HasTrait("BigBladder") then
            SandboxVars.BathroomFunctions.BladderMaxValue = baseBladderMax * 1.25
        end

        if player:HasTrait("SmallBowels") then
            SandboxVars.BathroomFunctions.BowelsMaxValue = baseBowelsMax * 0.75
        elseif player:HasTrait("BigBowels") then
            SandboxVars.BathroomFunctions.BowelsMaxValue = baseBowelsMax * 1.25
        end

        print("Adjusted Bladder Max Value: " .. SandboxVars.BathroomFunctions.BladderMaxValue)
        print("Adjusted Bowels Max Value: " .. SandboxVars.BathroomFunctions.BowelsMaxValue)
    else
        print("Player not loaded!")
    end
end

-- Then register the function to run once the game starts.
Events.OnGameStart.Add(BF.OverrideSandboxMax)

-- =====================================================
--
-- BATHROOM FUNCTIONALITY AND TIMERS
--
-- =====================================================

--[[
Function to handle timed updates for bathroom needs
This function is called periodically (e.g., every 10 in-game minutes).
]]--
function BF.BathroomFunctionTimers()
    if BF.didFirstTimer then
        BF.UpdateBathroomValues() -- If the initial setup is done, update the player's bathroom values
        BF.HandleInstantAccidents() -- Check whether or not the player has urinated or defecated themselves.
        BF.HandleUrgencyHiccup() -- Do the hiccup system, aka player grabbing crotch and possibly pissing themselves or so on. Too tired to censor my shit lol
        BF.DirtyBottomsEffects()
    else
        BF.didFirstTimer = true -- If this is the first call, set the flag to true and skip updating values
    end
end

--[[

Calories:       -2200   >     3700
Protein:        -500    >     1000
Lipids:         -500    >     1000
Carbohydrates:  -500    >     1000

Burn rate: 10 Calories per 10 min
]]

-- Function to update the player's bathroom-related values (urination and defecation)
function BF.UpdateBathroomValues()

    BF.UpdateUrinationValues()
    BF.UpdateDefecationValues()

    -- Decay bodily fumes (smell moodle) by 10% every 10 seconds
    --local currentFumes = BF.GetBodilyFumesValue()
    --local reducedFumes = currentFumes * 0.9
    --BF.SetBodilyFumesValue(reducedFumes)

    -- Instantly clear bodily fumes
    BF.SetBodilyFumesValue(0)

end

-- Make the player urinate / defecate in very "sudden" situations.
-- Like, getting injured (car crash, shot). Overflowing (bladder max capacity).
function BF.HandleInstantAccidents()
    local urinateValue = BF.GetUrinateValue() -- Current bladder level
    local defecateValue = BF.GetDefecateValue() -- Current bowel level
    local player = getPlayer()

    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Default to 100 if not set
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Default to 100 if not set

    -- Calculate overflow values
    local bladderThreshold = 0.95 * bladderMaxValue -- 95% of max bladder value
    local bowelsThreshold = 0.98 * bowelsMaxValue -- 98% of max bowel value

    -- Leaking feature for Incontinent traits --------------------------------------------------------------------------

    -- Base leak chance
    local leakChance = 2

    -- Leak Chance drunkiness
    if player:getStats():getDrunkenness() > 0 then
        leakChance = leakChance + 5 -- Drunk modifier
    end

    -- Panic modifier: increase leak chance if the player is panicked
    if player:getMoodles():getMoodleLevel(MoodleType.Panic) > 0 then
        leakChance = leakChance + (player:getMoodles():getMoodleLevel(MoodleType.Panic)*2)  -- Increase by Panic level
    end


    -- Leaking feature for urination
    if player:HasTrait("UrinaryIncontinence") and (urinateValue >= 0.2 * bladderMaxValue) then
        if ZombRand(100) < leakChance then
            BF.TriggerSelfUrinate(true)  -- Trigger self urination leak action
            print("Leaked Pee" .. tostring(leakChance))
        end
    end

    -- Leaking feature for defecation
    if player:HasTrait("FecalIncontinence") and (defecateValue >= 0.2 * bowelsMaxValue) then
        if ZombRand(100) < leakChance then
            BF.TriggerSelfDefecate(true)  -- Trigger self defecation leak action
            print("Leaked Poo" .. tostring(leakChance))
        end
    end


    -- Handle urination and defecation when the player is asleep or awake.
    -- If the player is asleep and their bladder/bowels are full, it happens automatically and wakes them up.
    -- If the player is awake and their bladder/bowels are full, the appropriate self-action (urinate/defecate) begins.
    if player:isAsleep() then

        -- Check if the player needs to urinate while asleep
        if urinateValue >= bladderThreshold then
            player:forceAwake()  -- Wake the player up if they need to urinate

            -- If the player has the "Bedwetter" trait, trigger the urination accident
            if player:HasTrait("Bedwetter") then
                BF.UrinateBottoms()  -- Simulate urinating in bed
                BF.SetUrinateValue(0)  -- Reset urinate value after accident
            end

        -- Check if the player needs to defecate while asleep
        elseif defecateValue >= bowelsThreshold then
            player:forceAwake()  -- Wake the player up if they need to defecate

            -- If the player has the "Bedsoiler" trait, trigger the defecation accident
            if player:HasTrait("Bedsoiler") then
                BF.DefecateBottoms()  -- Simulate defecating in bed
                BF.SetDefecateValue(0)  -- Reset defecate value after accident
            end

        end
    else
        -- If the player is awake, start the urination or defecation process based on their bladder/bowel status
        if urinateValue >= bladderThreshold then
            BF.TriggerSelfUrinate()  -- Trigger self urination action
        elseif defecateValue >= bowelsThreshold then
            BF.TriggerSelfDefecate()  -- Trigger self defecation action
        end
    end
end

-- Function to handle the hiccup system. Every 10 minutes, this checks if the player should have a ""hiccup".
-- Hiccup in this context is the slang definition, like a pause. Not a "hic" hiccup lol
function BF.HandleUrgencyHiccup()
    local player = getPlayer()
    local urinateValue = BF.GetUrinateValue()
    local defecateValue = BF.GetDefecateValue()
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 500
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 800

    local modOptions = PZAPI.ModOptions:getOptions("BF")

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

        local panicLevel = player:getMoodles():getMoodleLevel(MoodleType.Panic)
        print("Panic Level:", panicLevel, "Calculated Value:", panicLevel * 2)

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

            local playerSayStatus = modOptions:getOption("6")
	        if(playerSayStatus:getValue(1)) then
                player:Say(getText("IGUI_announce_UrgeHiccup"))
            end

            -- This is where other stuff happens when the hiccup is happening

            -- Pass the hiccup type to PlayUrgencyIdles for the correct animation
            BF.PlayUrgencyIdles(hiccupType, true)

            -- Accident Chance (trigger accident if player is too full)
            local accidentChance = 5 -- Base 5% chance
            if player:getStats():getDrunkenness() > 0 then
                accidentChance = accidentChance + 10 -- Drunk modifier
            end

            -- Urination logic
            if player:HasTrait("UrinaryIncontinence") then
                -- Incontinent players always leak fully
                BF.TriggerSelfUrinate()
            elseif ZombRand(100) < accidentChance then
                if urinateValue >= 0.4 * bladderMaxValue then
                    if player:HasTrait("BladderControl") then
                        -- With BladderControl, 75% chance for a small leak vs 25% full leak
                        if ZombRand(100) < 75 then
                                BF.TriggerSelfUrinate(true)  -- small leak version
                        else
                                BF.TriggerSelfUrinate()        -- full leak
                        end
                    else
                        BF.TriggerSelfUrinate()            -- no control trait → full leak
                        print("Triggered full leak (no trait)")
                    end
                end
            end

            -- Defecation logic
            if player:HasTrait("FecalIncontinence") then
                -- Incontinent players always defecate fully
                BF.TriggerSelfDefecate()
            elseif ZombRand(100) < accidentChance then
                if defecateValue >= 0.4 * bowelsMaxValue then
                    if player:HasTrait("BowelControl") then
                        if ZombRand(100) < 75 then
                                BF.TriggerSelfDefecate(true)
                        else
                                BF.TriggerSelfDefecate()
                        end
                    else
                        BF.TriggerSelfDefecate()
                    end
                end
            end

        end
    end
end

-- Function for playing urgency idle animations based on hiccup type.
-- TODO: Make the speed value change depending on urination / defecation value. So slight urge makes it go quickly, bad urge makes them hold longer
function BF.PlayUrgencyIdles(hiccupType, doTimedAction)
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

function BF.PainInBladder(player, pain)
	local part = player:getBodyDamage():getBodyPart(BodyPartType.Groin)
	part:setStiffness(pain)
end

function BF.PainInColon(player, pain)
	local part = player:getBodyDamage():getBodyPart(BodyPartType.Torso_Lower)
	part:setStiffness(pain)
end

-- =====================================================
--
-- EVENT REGISTRATION
--
-- =====================================================

local onFillItemTooltip = function(tooltip, layout, item)
    -- Check if the item has moddata with 'peed = true'
    if item:getModData().peed == true then
        local peedSeverity = item:getModData().peedSeverity
        -- Format the severity value to 1 decimal place
        --local peedText = "Soiled (Pee): " .. string.format("%.1f", peedSeverity) .. "%"

        --local peedTooltip = LayoutItem.new()
        --layout.items:add(peedTooltip)
        --peedTooltip:setLabel(peedText, 1.000, 0.867, 0.529, 1)

        -- Bar uses dark yellow
        local peeBarColor = table.newarray(1.000, 0.867, 0.529, 1)
        -- Label uses bright yellow
        local peeLabelColor = table.newarray(1.000, 1.000, 0.000, 1)

        InventoryUI.addTooltipBar(layout, "Urinated:", peedSeverity / 100, peeBarColor, peeLabelColor)
    end

    -- Check if the item has moddata with 'pooped == true'
    if item:getModData().pooped == true then
        local poopedSeverity = item:getModData().poopedSeverity
        -- Format the severity value to 1 decimal place
        --local poopedText = "Soiled (Poop): " .. string.format("%.1f", poopedSeverity) .. "%"

        --local poopedTooltip = LayoutItem.new()
        --layout.items:add(poopedTooltip)
        --poopedTooltip:setLabel(poopedText, 0.678, 0.412, 0.235, 1)

        -- Bar uses dark brown
        local poopBarColor = table.newarray(0.678, 0.412, 0.235, 1)
        -- Label uses bright brown
        local poopLabelColor = table.newarray(0.800, 0.522, 0.247, 1)

        InventoryUI.addTooltipBar(layout, "Defecated:", poopedSeverity / 100, poopBarColor, poopLabelColor)
    end
end

function BF.onGameBoot()
    local humanGroup = BodyLocations.getGroup("Human"); -- Get the BodyLocations group for humans
    local peedUndiesLocation = humanGroup:getOrCreateLocation("PeedOverlay_Underwear"); -- Create or fetch the PeedOverlay location
    local peedPantsLocation = humanGroup:getOrCreateLocation("PeedOverlay_Pants"); -- Create or fetch the PeedOverlay2 location
    local poopedUndiesLocation = humanGroup:getOrCreateLocation("PoopedOverlay_Underwear"); -- Create or fetch the PoopedOverlay location
    local poopedPantsLocation = humanGroup:getOrCreateLocation("PoopedOverlay_Pants"); -- Create or fetch the PoopedOverlay2 location if needed

    -- Remove PeedOverlay if it already exists to avoid duplication
    local list = getClassFieldVal(humanGroup, getClassField(humanGroup, 1));
    list:remove(peedUndiesLocation);

    -- Remove PeedOverlay2 if it already exists to avoid duplication
    list:remove(peedPantsLocation);

    -- Remove PoopedOverlay if it already exists to avoid duplication
    list:remove(poopedUndiesLocation);

    -- Remove PoopedOverlay2 if it already exists to avoid duplication
    list:remove(poopedPantsLocation);

    -- Find the index of Pants to ensure overlays render above it
    local pantsIndex = humanGroup:indexOf("Pants");

    -- Add PeedOverlay just after Pants
    list:add(pantsIndex + 1, peedUndiesLocation);

    -- Add PeedOverlay2 just after PeedOverlay
    list:add(pantsIndex + 2, peedPantsLocation);

    -- Add PoopedOverlay just after PeedOverlay2
    list:add(pantsIndex + 3, poopedUndiesLocation);

    -- Add PoopedOverlay2 just after PoopedOverlay if needed
    list:add(pantsIndex + 4, poopedPantsLocation);
end


--[[
Register the BathroomFunctionTimers function to run every 10 in-game minutes
This ensures bathroom values are periodically updated.
]]--
Events.EveryTenMinutes.Add(BF.BathroomFunctionTimers)

Events.OnGameBoot.Add(BF.onGameBoot)

InventoryUI.onFillItemTooltip:addListener(onFillItemTooltip)