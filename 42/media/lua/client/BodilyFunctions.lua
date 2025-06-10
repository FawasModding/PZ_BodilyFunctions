BF = {}
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

-- =====================================================
--
-- RIGHT CLICK / INTERACTION FUNCTIONS
--
-- =====================================================

-- Wiping options helper function
function BF.AddWipingOptions(parentMenu, worldObjects, player, defecateValue, requirement, maxValue, wipeType, wipeItem, triggerFunction, targetObject)
    if defecateValue < (requirement / 100) * maxValue then
        return nil
    end

    local hasShyBowels = player:HasTrait("ShyBowels")
    local hasParcopresis = player:HasTrait("Parcopresis")
    local isBeingWatched = BF.IsBeingWatched(player)

    if (hasShyBowels or hasParcopresis) and isBeingWatched then
        return nil
    end

    local wipeSubMenu = ISContextMenu:getNew(parentMenu)
    local _, _, wipeEfficiency = BF.CheckForWipeables(player)

    -- "Don't Wipe" option
    local dontWipeOption
    if triggerFunction == BF.TriggerGroundDefecate then
        dontWipeOption = wipeSubMenu:addOption(getText("ContextMenu_DontWipe"), false, triggerFunction, wipeType, wipeItem, 0)
    else
        dontWipeOption = wipeSubMenu:addOption(getText("ContextMenu_DontWipe"), targetObject, triggerFunction, player, false, wipeType, wipeItem, 0)
    end
    BF.AddTooltip(dontWipeOption, "Choose not to wipe after defecating. (5% soiling penalty)")

    -- "Wipe With" option if wipeItem exists
    if wipeItem then
        local wipePercentage = wipeType == "usingClothing" and 0 or math.floor(wipeEfficiency * 100)
        local penaltyPercentage = wipeType == "usingClothing" and 5 or 5 * (1 - wipeEfficiency)
        local doWipeOption
        if triggerFunction == BF.TriggerGroundDefecate then
            doWipeOption = wipeSubMenu:addOption(
                getText("ContextMenu_WipeWith") .. " " .. wipeItem:getName() .. (wipeType == "usingClothing" and "" or " (" .. wipePercentage .. "%)"),
                true, triggerFunction, wipeType, wipeItem, wipeEfficiency
            )
        else
            doWipeOption = wipeSubMenu:addOption(
                getText("ContextMenu_WipeWith") .. " " .. wipeItem:getName() .. (wipeType == "usingClothing" and "" or " (" .. wipePercentage .. "%)"),
                targetObject, triggerFunction, player, true, wipeType, wipeItem, wipeEfficiency
            )
        end
        BF.AddTooltip(doWipeOption, "Wipe using this item. (" .. string.format("%.2f", penaltyPercentage) .. "% soiling penalty)")
    end

    return wipeSubMenu
end

function BF.IsBeingWatched(player)
    local isBeingWatched = false
    
    -- Only check if player has traits that might be affected
    if player:HasTrait("Paruresis") or player:HasTrait("Parcopresis") or 
       player:HasTrait("ShyBladder") or player:HasTrait("ShyBowels") then
        
        local checkRange = 10 -- 10 tiles radius
        local playerX = player:getX()
        local playerY = player:getY()
        local playerZ = player:getZ()
        local playerSquare = player:getSquare()
        
        -- Function to check if there's line of sight between two squares
        local function hasLineOfSight(fromSquare, toSquare)
            if not fromSquare or not toSquare then return false end
            
            -- Use the correct line of sight function
            return LosUtil.lineClear(getCell(), fromSquare:getX(), fromSquare:getY(), fromSquare:getZ(), 
                                     toSquare:getX(), toSquare:getY(), toSquare:getZ(), false)
        end
        
        -- Check for zombies nearby with line of sight
        local zombies = getCell():getZombieList()
        for i = 0, zombies:size() - 1 do
            local zombie = zombies:get(i)
            if zombie:getZ() == playerZ and 
               math.abs(zombie:getX() - playerX) <= checkRange and 
               math.abs(zombie:getY() - playerY) <= checkRange then
                
                -- Check if zombie has line of sight to player
                if hasLineOfSight(zombie:getSquare(), playerSquare) then
                    isBeingWatched = true
                    break
                end
            end
        end
        
        -- Check for other players nearby with line of sight (for multiplayer)
        if not isBeingWatched then
            local players = getOnlinePlayers()
            if players then
                for i = 0, players:size() - 1 do
                    local otherPlayer = players:get(i)
                    if otherPlayer ~= player and otherPlayer:getZ() == playerZ and 
                       math.abs(otherPlayer:getX() - playerX) <= checkRange and 
                       math.abs(otherPlayer:getY() - playerY) <= checkRange then
                        
                        -- Check if other player has line of sight to this player
                        if hasLineOfSight(otherPlayer:getSquare(), playerSquare) then
                            isBeingWatched = true
                            break
                        end
                    end
                end
            end
        end
    end
    
    return isBeingWatched
end

function BF.BathroomRightClick(player, context, worldObjects)
    local firstObject
    for i = 1, #worldObjects do
        if not firstObject then
            firstObject = worldObjects[i]
        end
    end

    local player = getPlayer()
    local square = firstObject:getSquare()
    local worldObjects = square:getObjects()
    local toiletOptionAdded = false

    local toiletTiles = BF.GetToiletTiles()
    local urinalTiles = BF.GetUrinalTiles()
    local outhouseTiles = BF.GetOuthouseTiles()
    local showerTiles = BF.GetShowerTiles()

    local urinateValue = BF.GetUrinateValue()
    local defecateValue = BF.GetDefecateValue()

    -- Retrieve maximum values from SandboxVars
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Default to 100 if not set
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Default to 100 if not set

    local peeOnSelfRequirement = SandboxVars.BF.PeeOnSelfRequirement or 85 -- Default to 85 if not set
    local peeOnGroundRequirement = SandboxVars.BF.PeeOnGroundRequirement or 50 -- Default to 50 if not set
    local peeInToiletRequirement = SandboxVars.BF.PeeInToiletRequirement or 40 -- Default to 40 if not set
    local peeInContainerRequirement = SandboxVars.BF.PeeInContainerRequirement or 60 -- Default to 70 if not set

    local poopOnSelfRequirement = SandboxVars.BF.PoopOnSelfRequirement or 75 -- Default to 75 if not set
    local poopOnGroundRequirement = SandboxVars.BF.PoopOnGroundRequirement or 50 -- Default to 50 if not set
    local poopInToiletRequirement = SandboxVars.BF.PoopInToiletRequirement or 40 -- Default to 40 if not set

    local modOptions = PZAPI.ModOptions:getOptions("BF")

    --local wipeType, wipeItem = BF.CheckForWipeables(player) -- moved to induvidial function to reduce calls

    -------------------------------------------------------------------------------------------------------------------

    -- Check for Paruresis (shy bladder) and Parcopresis (shy bowel)
    local hasParuresis = player:HasTrait("Paruresis")
    local hasParcopresis = player:HasTrait("Parcopresis")

    -- Add checks for new traits
    local hasShyBladder = player:HasTrait("ShyBladder")
    local hasShyBowels = player:HasTrait("ShyBowels")

    -- Use our common function to check if being watched
    local isBeingWatched = BF.IsBeingWatched(player)

    -------------------------------------------------------------------------------------------------------------------

    -- Main menu option: "Urination"
    local peeOption = context:addOption(getText("ContextMenu_Urinate"), worldObjects, nil)
    local peeSubMenu = ISContextMenu:getNew(context)
    context:addSubMenu(peeOption, peeSubMenu)
    peeOption.iconTexture = getTexture("media/ui/Urination.png")
    
    -- Disable all urination options if player has Paruresis and is being watched
    if hasParuresis and isBeingWatched then
        peeOption.notAvailable = true
        BF.AddTooltip(peeOption, "You are too shy to urinate while being watched.")
    end

    -- Main menu option: "Defecation"
    local poopOption = context:addOption(getText("ContextMenu_Defecate"), worldObjects, nil)
    local poopSubMenu = ISContextMenu:getNew(context)
    context:addSubMenu(poopOption, poopSubMenu)
    poopOption.iconTexture = getTexture("media/ui/Defecation.png")
    
    -- Disable all defecation options if player has Parcopresis and is being watched
    if hasParcopresis and isBeingWatched then
        poopOption.notAvailable = true
        BF.AddTooltip(poopOption, "You are too shy to defecate while being watched.")
    end

    -------------------------------------------------------------------------------------------------------------------

    -- Using Ground
    local groundPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseGround")), worldObjects, BF.TriggerGroundUrinate, player)
    BF.AddTooltip(groundPeeOption, "Urinate on the ground. (Requires " .. peeOnGroundRequirement .. "%)")
    groundPeeOption.iconTexture = getTexture("media/textures/ContextMenuGround.png");

    local groundPoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseGround")), worldObjects, nil)
    BF.AddTooltip(groundPoopOption, "Defecate on the ground. (Requires " .. poopOnGroundRequirement .. "%)")
    groundPoopOption.iconTexture = getTexture("media/textures/ContextMenuGround.png");

    -- Disable ground peeing for ShyBladder trait
    if urinateValue < (peeOnGroundRequirement / 100) * bladderMaxValue or hasShyBladder then
        groundPeeOption.notAvailable = true
        if hasShyBladder then
            BF.AddTooltip(groundPeeOption, "You are too shy to urinate in public places.")
        end
    end

    if defecateValue < (poopOnGroundRequirement / 100) * bowelsMaxValue or hasShyBowels then
        groundPoopOption.notAvailable = true
        if hasShyBowels then
            BF.AddTooltip(groundPoopOption, "You are too shy to defecate in public places.")
        end
    end

    -- Only add wiping options if the player can actually poop on the ground
    if defecateValue >= (poopOnGroundRequirement / 100) * bowelsMaxValue and not (hasShyBowels and isBeingWatched) then
        -- Only check for wipeables if we actually need them
        local wipeType, wipeItem = BF.CheckForWipeables(player)
        local wipeSubMenuForGround = BF.AddWipingOptions(
            poopSubMenu,
            worldObjects,
            player,
            defecateValue,
            poopOnGroundRequirement,
            bowelsMaxValue,
            wipeType,
            wipeItem,
            BF.TriggerGroundDefecate,
            nil
        )
        
        -- Only add the submenu if it was actually created
        if wipeSubMenuForGround then
            poopSubMenu:addSubMenu(groundPoopOption, wipeSubMenuForGround)
        end
    end

    -------------------------------------------------------------------------------------------------------------------

    -- Using Self

    local canPeeSelfOption = modOptions:getOption("2")
    if(canPeeSelfOption:getValue(1)) then

        local selfPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseSelf")), worldObjects, BF.TriggerSelfUrinate, player)
        BF.AddTooltip(selfPeeOption, "Urinate on yourself. Very few situations where this would be useful. (Requires " .. peeOnSelfRequirement .. "%)")
        selfPeeOption.iconTexture = getTexture("media/ui/PeedSelf.png");

        -- Disable "On Self" pee options if urinateValue too low or ShyBladder trait
        if urinateValue < (peeOnSelfRequirement / 100) * bladderMaxValue or hasShyBladder then
            selfPeeOption.notAvailable = true
            if hasShyBladder then
                BF.AddTooltip(selfPeeOption, "You are too shy to urinate on yourself, even when alone.")
            end
        end

    end

    local canPoopSelfOption = modOptions:getOption("3")
    if(canPoopSelfOption:getValue(1)) then
  
        local selfPoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseSelf")), worldObjects, BF.TriggerSelfDefecate, player)
        BF.AddTooltip(selfPoopOption, "Defecate on yourself. Very few situations where this would be useful. (Requires " .. poopOnSelfRequirement .. "%)")
        selfPoopOption.iconTexture = getTexture("media/ui/PoopedSelf.png");

        if defecateValue < (poopOnSelfRequirement / 100) * bowelsMaxValue or hasShyBowels then
            selfPoopOption.notAvailable = true
            if hasShyBowels then
                BF.AddTooltip(selfPoopOption, "You are too shy to defecate on yourself, even when alone.")
            end
        end
    
    end

    -------------------------------------------------------------------------------------------------------------------

    -- Using Toilets

    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)

        -- Using toilet
        --if object:getTextureName() and luautils.stringStarts(object:getTextureName(), "fixtures_bathroom_01") and object:hasWater() and object:getSquare():DistToProper(player:getSquare()) < 1 then
        for j = 1, #toiletTiles do
            local tile = toiletTiles[j]
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local toiletPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseToilet")), object, BF.TriggerToiletUrinate, player)
                local toiletPoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseToilet")), object, BF.TriggerToiletDefecate, player)

                --if object:getWaterAmount() < 10.0 then
                --    toiletPoopOption.notAvailable = true
                --end

                --BF.AddTooltip(toiletPeeOption, "Urinate in the toilet. (Requires " .. peeInToiletRequirement .. "% and sufficient water)")
                --BF.AddTooltip(toiletPoopOption, "Defecate in the toilet. (Requires " .. poopInToiletRequirement .. "% and sufficient water)")
                BF.AddTooltip(toiletPeeOption, "Urinate in the toilet. (Requires " .. peeInToiletRequirement .. "%")
                BF.AddTooltip(toiletPoopOption, "Defecate in the toilet. (Requires " .. poopInToiletRequirement .. "%")
                toiletOptionAdded = true

                toiletPeeOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png");
                toiletPoopOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png");

                -- Check if urinateValue meets the requirement to use the toilet for peeing
                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue then
                    toiletPeeOption.notAvailable = true
                end

                -- Check if defecateValue meets the requirement to use the toilet for pooping
                if defecateValue < (poopInToiletRequirement / 100) * bowelsMaxValue then
                    toiletPoopOption.notAvailable = true
                end

                -- If either option was marked as not available, return early
                if toiletPoopOption.notAvailable then
                    return
                end

                -- Add wiping option for toilet defecation
                -- Only check for wipeables if we actually need them
                local wipeType, wipeItem = BF.CheckForWipeables(player)
                local wipeSubMenuForToilet = BF.AddWipingOptions(
                    poopSubMenu,
                    worldObjects,
                    player,
                    defecateValue,
                    poopInToiletRequirement,
                    bowelsMaxValue,
                    wipeType,
                    wipeItem,
                    BF.TriggerToiletDefecate,  -- Pass the toilet defecation function
                    object -- Pass the toilet object as the target
                )
                poopSubMenu:addSubMenu(toiletPoopOption, wipeSubMenuForToilet)

            end
        end

        -- Using urinal
        if not player:isFemale() then
            for i = 1, #urinalTiles do
                local tile = urinalTiles[i]
                if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                    -- Pee option
                    local urinalPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseUrinal")), object, BF.TriggerToiletUrinate, player)
                    BF.AddTooltip(urinalPeeOption, "Urinate in the urinal. (Requires " .. peeInToiletRequirement .. "%)")
                    toiletOptionAdded = true

                    if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue then
                        urinalPeeOption.notAvailable = true
                    end

                    -- Poop option is always unavailable
                    local urinalPoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseUrinal")), object, nil, player)
                    BF.AddTooltip(urinalPoopOption, "Don't you fucking dare'.")
                    urinalPoopOption.notAvailable = true

                    urinalPeeOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png")
                    urinalPoopOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png")

                    break
                end
            end
        end

        -- Using outhouses
        for i = 1, #outhouseTiles do
            local tile = outhouseTiles[i]
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local outhousePeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseOuthouse")), object, BF.TriggerToiletUrinate, player)
                local outhousePoopOption = poopSubMenu:addOption((getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseOuthouse")), object, BF.TriggerToiletDefecate, player)
        
                outhousePeeOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png")
                outhousePoopOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png")

                BF.AddTooltip(outhousePeeOption, "Urinate in the outhouse. (Requires " .. peeInToiletRequirement .. "%)")
                BF.AddTooltip(outhousePoopOption, "Defecate in the outhouse. (Requires " .. poopInToiletRequirement .. "%)")
                toiletOptionAdded = true

                -- Check if urinateValue meets the requirement to use the toilet for peeing
                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue then
                    outhousePeeOption.notAvailable = true
                end

                -- Check if defecateValue meets the requirement to use the toilet for pooping
                if defecateValue < (poopInToiletRequirement / 100) * bowelsMaxValue then
                    outhousePoopOption.notAvailable = true
                end

                -- If either option was marked as not available, return early
                if outhousePoopOption.notAvailable then
                    return
                end

                -- Only check for wipeables if we actually need them
                local wipeType, wipeItem = BF.CheckForWipeables(player)
                -- Add wiping option for toilet defecation
                local wipeSubMenuForToilet = BF.AddWipingOptions(
                    poopSubMenu,
                    worldObjects,
                    player,
                    defecateValue,
                    poopInToiletRequirement,
                    bowelsMaxValue,
                    wipeType,
                    wipeItem,
                    BF.TriggerToiletDefecate,  -- Pass the toilet defecation function
                    object -- Pass the toilet object as the target
                )
                poopSubMenu:addSubMenu(outhousePoopOption, wipeSubMenuForToilet)

                break
            end
        end

        -- Using sink
        if object:getTextureName() and luautils.stringStarts(object:getTextureName(), "fixtures_sinks_01") and object:getSquare():DistToProper(player:getSquare()) < 5 then
            local sinkPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseSink")), object, BF.TriggerToiletUrinate, player)

            BF.AddTooltip(sinkPeeOption, "Urinate in the sink. (Requires " .. peeInToiletRequirement .. "%")
            toiletOptionAdded = true

            sinkPeeOption.iconTexture = getTexture("media/textures/ContextMenuSink.png");

            -- Disable sink peeing for ShyBladder trait
            if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue or hasShyBladder then
                sinkPeeOption.notAvailable = true
                if hasShyBladder then
                    BF.AddTooltip(sinkPeeOption, "You are too shy to urinate in a sink.")
                end
            end
        end

        -- Using showers / baths
        for i = 1, #showerTiles do
            local tile = showerTiles[i]
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local showerPeeOption = peeSubMenu:addOption((getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseShower")), object, BF.TriggerToiletUrinate, player)
        
                showerPeeOption.iconTexture = getTexture("media/textures/ContextMenuShower.png")

                BF.AddTooltip(showerPeeOption, "Urinate in the shower / bathtub. (Requires " .. peeInToiletRequirement .. "%)")
                toiletOptionAdded = true

                -- Disable shower peeing for ShyBladder trait
                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue or hasShyBladder then
                    showerPeeOption.notAvailable = true
                    if hasShyBladder then
                        BF.AddTooltip(showerPeeOption, "You are too shy to urinate in a shower/bathtub.")
                    end
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
        BF.AddTooltip(containerPeeOption, "Urinate in a container. (Requires " .. peeInContainerRequirement .. "%)")

        local containerSubMenu = ISContextMenu:getNew(peeSubMenu) -- Create submenu
        peeSubMenu:addSubMenu(containerPeeOption, containerSubMenu) -- Attach submenu to `containerPeeOption`
        containerPeeOption.iconTexture = getTexture("media/textures/Item_BottleOfPee.png");

        local hasValidContainers = false

        for i = 0, player:getInventory():getItems():size() - 1 do
            local item = player:getInventory():getItems():get(i)
            if item:getFluidContainer() and item:getFluidContainer():isEmpty() then
                -- Add a valid pee option for each empty container
                containerSubMenu:addOption("Use " .. item:getName(), item, BF.PeeInContainer)
                hasValidContainers = true
            end
        end

        -- Make the "Use Container" option unavailable if no valid containers are found or pee in container requirement not met
        -- Also disable for ShyBladder trait
        if urinateValue < (peeInContainerRequirement / 100) * bladderMaxValue or hasShyBladder or not hasValidContainers then
            containerPeeOption.notAvailable = true
            if hasShyBladder then
                BF.AddTooltip(containerPeeOption, "You are too shy to urinate in a container.")
            end
        end
    end
    -------------------------------------------------------------------------------------------------------------------
end

function BF.WashingRightClick(player, context, worldObjects)
	local player = getPlayer()

	local hasSoiledClothing = false
	local soiledClothingEquipped = false
	local soiledClothing = nil
	local soapItem = nil

	-- Track soiled rags and GrassTufts, items that can be cleaned after wiping
    local soiledItems = {}

	for i = 0, player:getInventory():getItems():size() - 1 do
		local item = player:getInventory():getItems():get(i)

		if item:getType() == "Soap2" then
			soapItem = item
		end

		if item:getModData().peed == true or item:getModData().pooped == true then
			hasSoiledClothing = true
			if item:isEquipped() then
				soiledClothingEquipped = true
			end
			soiledClothing = item
		end

        -- Track soiled rags and grass tufts
		if item:getType() == "RippedSheetsPooped" or item:getType() == "GrassTuftPooped" then
			hasSoiledClothing = true
			table.insert(soiledItems, item)
		end

	end

	if hasSoiledClothing then
		local storeWater = nil
		local firstObject = nil

		for i = 1, #worldObjects do
			if not firstObject then
				firstObject = worldObjects[i]
			end
		end

		local square = firstObject:getSquare()
		local worldObjects = square:getObjects()
		for i = 0, worldObjects:size() - 1 do
			local object = worldObjects:get(i)
			if object:getTextureName() and object:hasWater() then --Anything that can usually be used to wash
				storeWater = object
			end
		end

		if storeWater == nil then return end
		if storeWater:getSquare():DistToProper(player:getSquare()) > 10 then return end

		local washOption = context:addOptionOnTop("Wash Soiled Items", nil, nil)
		washOption.iconTexture = getTexture("media/ui/PeedSelf.png")
		local subMenu = ISContextMenu:getNew(context)
		context:addSubMenu(washOption, subMenu)

		-- Original soiled clothing option
		if soiledClothing then
			if not soiledClothing:getModData().originalName then
				soiledClothing:getModData().originalName = soiledClothing:getName()
			end

			local option = subMenu:addOption(soiledClothing:getName(), player, BF.WashSoiled, square, soiledClothing, soapItem, storeWater, soiledClothingEquipped)

			local waterRemaining = storeWater:getFluidAmount()
			if waterRemaining < 15 then
				option.notAvailable = true
			end

			if soiledClothing:getModData().pooped then
				if soapItem == nil or soapItem:getCurrentUses() <= 0 then
					option.notAvailable = true
				end
			end
		end

        -- Options for soiled items
        for _, item in ipairs(soiledItems) do
            local option = subMenu:addOption(item:getName(), player, BF.WashSoiledItem, square, item, soapItem, storeWater)

            local waterRemaining = storeWater:getFluidAmount()
            if waterRemaining < 5 then -- Less water needed for items
                option.notAvailable = true
            end

            -- Require soap for pooped items
            if soapItem == nil or soapItem:getCurrentUses() <= 0 then
                option.notAvailable = true
            end
        end

		--local tooltip = ISWorldObjectContextMenu.BF.AddTooltip()
		--tooltip.description = getText("ContextMenu_WaterSource") .. ": " .. source
		--tooltip.description = tooltip.description .. " <LINE> Water: " .. tostring(math.min(waterRemaining, 15)) .. " / " .. tostring(15)
		--tooltip.description = tooltip.description .. " <LINE> Bleach: " .. bleachText .. " / 0.3"
		--tooltip.description = tooltip.description .. " <LINE> Dirty: " .. math.ceil(defecatedItem:getDirtyness()) .. " / 100"
		--option.toolTip = tooltip
	end
end


function BF.CleaningRightClick(player, context, worldObjects)
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

function BF.RemoveBottomClothing(player)
    local removedClothing = {}

    -- Get the list of excretion obstructive clothing body locations
    local excreteObstructive = BF.GetExcreteObstructiveClothing()

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
function BF.ReequipBottomClothing(player)
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

    -- This was moved to be directly inside of the trigger functions, so it happens after wiping.
     --BF.ResetRemovedClothing(player)
end
function BF.ResetRemovedClothing(player)
    -- Clear the removed clothing list
    player:getModData().removedClothing = nil
end

function BF.TriggerToiletUrinate(object, player)
    local player = getPlayer()
    local urinateValue = BF.GetUrinateValue()
    local requirement = SandboxVars.BF.PeeInToiletRequirement or 40
    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100
    local hasShyBladder = player:HasTrait("ShyBladder")
    local isBeingWatched = BF.IsBeingWatched(player)

    -- Only allow action if requirements are met
    if urinateValue < (requirement / 100) * bladderMaxValue then
        return
    end
    if hasShyBladder and isBeingWatched then
        return
    end

    -- Proceed with the action
    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, object))
    if player:isFemale() == true then
        BF.RemoveBottomClothing(player)
    end
    ISTimedActionQueue.add(ToiletUrinate:new(player, urinateValue, true, true, object))
end

function BF.TriggerToiletDefecate(object, player, isWiping, wipeType, wipeItem, wipeEfficiency)
    local player = getPlayer()
    local defecateValue = BF.GetDefecateValue()
    local requirement = SandboxVars.BF.PoopInToiletRequirement or 40
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100
    local hasShyBowels = player:HasTrait("ShyBowels")
    local isBeingWatched = BF.IsBeingWatched(player)

    if defecateValue < (requirement / 100) * bowelsMaxValue or (hasShyBowels and isBeingWatched) then
        return
    end

    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, object))
    BF.RemoveBottomClothing(player)
    ISTimedActionQueue.add(ToiletDefecate:new(player, defecateValue * 2, true, true, object))
    
    if isWiping then
        ISTimedActionQueue.add(WipeSelf:new(player, 20, wipeType, wipeItem, "poop"))
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

        BF.ResetRemovedClothing(player) -- reset removed clothing
    end
end

function BF.TriggerGroundUrinate()
    local player = getPlayer()
    local urinateValue = BF.GetUrinateValue()
    local peeTime = urinateValue

    -- If female, must take off clothing. Males would just unzip their pants.
    if player:isFemale() == true then
        -- Remove bottom clothing first
        BF.RemoveBottomClothing(player)
    end

    -- Urinate on the ground
    ISTimedActionQueue.add(GroundUrinate:new(player, peeTime, true, true))
end

function BF.TriggerGroundDefecate(isWiping, wipeType, wipeItem, wipeEfficiency)
    local player = getPlayer()
    local defecateValue = BF.GetDefecateValue()
    local poopTime = defecateValue * 2

    BF.RemoveBottomClothing(player)
    ISTimedActionQueue.add(GroundDefecate:new(player, poopTime, true, true))

    if isWiping then
        ISTimedActionQueue.add(WipeSelf:new(player, 20, wipeType, wipeItem, "poop"))
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

        BF.ResetRemovedClothing(player) -- reset removed clothing
    end
end

function BF.TriggerSelfDefecate(isLeak)
    local isLeak = isLeak or false
    local player = getPlayer() -- Fetch the current player object
    local defecateValue = BF.GetDefecateValue() -- Current bowel level
    local poopTime = defecateValue / 4 -- Use a quarter of the defecate value so the player isn't locked for long
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100

    -- Check if the player has relevant clothing on and apply the "pooped bottoms" effects.
    if BF.HasClothingOn(player, unpack(BF.GetSoilableClothing())) then
        BF.DefecateBottoms(isLeak)
    else
        -- Optionally, you could create a world object or simply do nothing when no clothing is worn.
        -- For defecation there may be no object spawned.
    end

    -- Enqueue the self-defecation timed action.
    -- The last parameter 'isLeak' determines whether it applies leak behavior.
    ISTimedActionQueue.add(SelfDefecate:new(player, poopTime, false, false, true, false, nil, isLeak))

    print("Updated Pooped Self Value: " .. BF.GetPoopedSelfValue()) -- Debug print statement
    if isLeak then
        print("Leak triggered: Updated Pooped Self Value: " .. BF.GetPoopedSelfValue())
    else
        print("Updated Pooped Self Value: " .. BF.GetPoopedSelfValue())
    end

end


function BF.TriggerSelfUrinate(isLeak)
    local isLeak = isLeak or false
    local player = getPlayer() -- Fetch the current player object
    local urinateValue = BF.GetUrinateValue() -- Current bladder level
    local peeTime = urinateValue / 4 -- Determine the time based on the bladder level

    -- Optionally, you can adjust the bladderMaxValue based on mode.
    local bladderMaxValue = isLeak and (SandboxVars.BathroomFunctions.BladderMaxValue or 500)
                                     or (SandboxVars.BathroomFunctions.BladderMaxValue or 100)

    -- Check if player is wearing clothing that can be soiled.
    if BF.HasClothingOn(player, unpack(BF.GetSoilableClothing())) then
        BF.UrinateBottoms(isLeak)  -- Pass in the leak flag.
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

    if isLeak then
        print("Leak triggered: Updated Peed Self Value: " .. BF.GetPeedSelfValue())
    else
        print("Updated Peed Self Value: " .. BF.GetPeedSelfValue())
    end
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

function BF.WashSoiled(playerObj, square, soiledItem, bleachItem, storeWater, soiledItemEquipped)
	if not square or not luautils.walkAdj(playerObj, square, true) then
		return
	end

	if soiledItemEquipped then --Unequip soiled clothing before washing
		ISTimedActionQueue.add(ISUnequipAction:new(playerObj, soiledItem, 50))
	end
	
	ISTimedActionQueue.add(WashSoiled:new(playerObj, 400, square, soiledItem, bleachItem, storeWater))
end
function BF.WashSoiledItem(playerObj, square, soiledItem, bleachItem, storeWater)
	if not square or not luautils.walkAdj(playerObj, square, true) then
		return
	end
	
	ISTimedActionQueue.add(WashSoiledItem:new(playerObj, 400, square, soiledItem, bleachItem, storeWater))
end
function BF.CleanUrine()

end

-- Overwriting the base grab function so that you cannot pick up human urine
-- TODO: Remove display name for urine so it doesn't show in the inventory, and implement custom cleaning mechanic with mop
ISGrabItemAction.o_transferItem = ISGrabItemAction.transferItem

function ISGrabItemAction:transferItem(item)
    local itemObject = item:getItem()
    if itemObject:getType() == "Urine_Hydrated_0" then
        local modOptions = PZAPI.ModOptions:getOptions("BF")

        local playerSayStatus = modOptions:getOption("6")
	    if(playerSayStatus:getValue(1)) then
            self.character:Say(getText("IGUI_announce_CantPickUpPee"))
        end
        --print("Blocked picking up Urine_Hydrated_0!")
    else
        self:o_transferItem(item)
    end
end

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


-- =====================================================
--
-- EVENT REGISTRATION
--
-- =====================================================

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

Events.OnFillWorldObjectContextMenu.Add(BF.BathroomRightClick)
Events.OnFillWorldObjectContextMenu.Add(BF.WashingRightClick)
Events.OnFillWorldObjectContextMenu.Add(BF.CleaningRightClick)

InventoryUI.onFillItemTooltip:addListener(onFillItemTooltip)