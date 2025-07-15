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

    local toiletTiles = BF_ReliefPoints.GetToiletTiles()
    local urinalTiles = BF_ReliefPoints.GetUrinalTiles()
    local outhouseTiles = BF_ReliefPoints.GetOuthouseTiles()
    local showerTiles = BF_ReliefPoints.GetShowerTiles()
    local bathtubTiles = BF_ReliefPoints.GetBathtubTiles()
    local bushTiles = BF_ReliefPoints.GetBushTiles()
    local dumpsterTiles = BF_ReliefPoints.GetDumpsterTiles()
    local sinkTiles = BF_ReliefPoints.GetSinkTiles()
    local treeTiles = BF_ReliefPoints.GetTreeTiles()
    local trashCanTiles = BF_ReliefPoints.GetTrashCanTiles()
    local waterTiles = BF_ReliefPoints.GetWaterTiles()

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

Events.OnFillWorldObjectContextMenu.Add(BF.BathroomRightClick)