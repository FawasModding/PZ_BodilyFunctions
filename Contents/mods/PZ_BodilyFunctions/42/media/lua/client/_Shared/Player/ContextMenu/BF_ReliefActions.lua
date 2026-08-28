
local function BF_NormalizeMenuName(s)
    return string.lower(tostring(s or ""))
end

-- Generic recursive submenu finder. matchFn receives the normalized option
-- name and returns true if this is the submenu being searched for.
function BF.FindSubMenu(menu, matchFn, depth)
    if not menu or (depth or 0) > 5 then return nil end
    depth = depth or 0

    for i = 1, #menu.options do
        local option = menu.options[i]
        if option and option.subOption then
            local name = BF_NormalizeMenuName(option.name)
            local sub = menu:getSubMenu(option.subOption)

            if sub and matchFn(name) then
                return sub
            end

            local found = BF.FindSubMenu(sub, matchFn, depth + 1)
            if found then return found end
        end
    end

    return nil
end

-- Finds the vanilla "Toilet" submenu
function BF.FindToiletSubMenu(menu, depth)
    local localizedToilet = BF_NormalizeMenuName(getText("ContextMenu_UseToilet"))
    return BF.FindSubMenu(menu, function(name)
        return string.find(name, "toilet", 1, true) ~= nil
            or (localizedToilet ~= "" and localizedToilet ~= "contextmenu_usetoilet" and name == localizedToilet)
    end, depth)
end

-- Finds the vanilla "Sink" submenu
function BF.FindSinkSubMenu(menu, depth)
    local localizedSink = BF_NormalizeMenuName(getText("ContextMenu_Sink"))
    return BF.FindSubMenu(menu, function(name)
        return string.find(name, "sink", 1, true) ~= nil
            or (localizedSink ~= "" and localizedSink ~= "contextmenu_sink" and name == localizedSink)
    end, depth)
end

-- Identifies whether a world object is a sink fixture
function BF.IsSinkObject(object)
    return object ~= nil
        and object:getTextureName() ~= nil
        and luautils.stringStarts(object:getTextureName(), "fixtures_sinks_01")
end

function BF.ReliefRightClick(player, context, worldObjects)
    player = getSpecificPlayer(player)
    local firstObject = worldObjects[1]
    local square = firstObject:getSquare()
    local worldObjects = square:getObjects()
    local toiletOptionAdded = false

    -- Retrieve tile sets
    local toiletTiles = BF_ReliefTiles.GetToiletTiles()
    local urinalTiles = BF_ReliefTiles.GetUrinalTiles()
    local outhouseTiles = BF_ReliefTiles.GetOuthouseTiles()
    local showerTiles = BF_ReliefTiles.GetShowerTiles()
    local bathtubTiles = BF_ReliefTiles.GetBathtubTiles()
    local bushTiles = BF_ReliefTiles.GetBushTiles()
    local dumpsterTiles = BF_ReliefTiles.GetDumpsterTiles()
    local sinkTiles = BF_ReliefTiles.GetSinkTiles()
    local treeTiles = BF_ReliefTiles.GetTreeTiles()
    local trashCanTiles = BF_ReliefTiles.GetTrashCanTiles()
    local waterTiles = BF_ReliefTiles.GetWaterTiles()

    -- Retrieve values
    local urinateValue = BF.GetUrinateValue()
    local defecateValue = BF.GetDefecateValue()

    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100

    local peeOnSelfRequirement = SandboxVars.BF.PeeOnSelfRequirement or 85
    local peeOnGroundRequirement = SandboxVars.BF.PeeOnGroundRequirement or 50
    local peeInToiletRequirement = SandboxVars.BF.PeeInToiletRequirement or 40
    local peeInContainerRequirement = SandboxVars.BF.PeeInContainerRequirement or 60

    local poopOnSelfRequirement = SandboxVars.BF.PoopOnSelfRequirement or 75
    local poopOnGroundRequirement = SandboxVars.BF.PoopOnGroundRequirement or 50
    local poopInToiletRequirement = SandboxVars.BF.PoopInToiletRequirement or 40
    
    local modOptions = PZAPI.ModOptions:getOptions("BF")

    -- Check traits and conditions
    local hasParuresis = player:hasTrait(BFTraits.Paruresis)
    local hasParcopresis = player:hasTrait(BFTraits.Parcopresis)
    local hasShyBladder = player:hasTrait(BFTraits.ShyBladder)
    local hasShyBowels = player:hasTrait(BFTraits.ShyBowels)

    -- Use common function to check if being watched
    local isBeingWatched = BF.IsBeingWatched(player)

    -- Main menu options
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

    local vanillaToiletSubMenu = BF.FindToiletSubMenu(context)
    local vanillaSinkSubMenu   = BF.FindSinkSubMenu(context)

    -- Add options for each type
    BF.AddGroundOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeOnGroundRequirement, poopOnGroundRequirement, hasShyBladder, hasShyBowels, isBeingWatched)
    BF.AddSelfOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeOnSelfRequirement, poopOnSelfRequirement, hasShyBladder, hasShyBowels, modOptions)
    BF.AddToiletOptions(vanillaToiletSubMenu, worldObjects, player, urinateValue, defecateValue,
    bladderMaxValue, bowelsMaxValue, peeInToiletRequirement, poopInToiletRequirement, toiletTiles)
    BF.AddUrinalOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, bladderMaxValue, peeInToiletRequirement, urinalTiles, hasShyBladder)
    BF.AddOuthouseOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeInToiletRequirement, poopInToiletRequirement, outhouseTiles, toiletOptionAdded)
    BF.AddSinkOptions(vanillaSinkSubMenu, worldObjects, player, urinateValue,
    bladderMaxValue, peeInToiletRequirement, sinkTiles, hasShyBladder)
    BF.AddShowerOptions(peeSubMenu, worldObjects, player, urinateValue, bladderMaxValue, peeInToiletRequirement, showerTiles, hasShyBladder)
    BF.AddBushOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeInToiletRequirement, poopInToiletRequirement, bushTiles, hasShyBladder, hasShyBowels)
    BF.AddWaterOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeInToiletRequirement, poopInToiletRequirement, waterTiles, hasShyBladder, hasShyBowels)
    BF.AddTrashCanOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeInToiletRequirement, poopInToiletRequirement, trashCanTiles, hasShyBladder, hasShyBowels)
    BF.AddDumpsterOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeInToiletRequirement, poopInToiletRequirement, dumpsterTiles, hasShyBladder, hasShyBowels)
    BF.AddContainerOptions(peeSubMenu, worldObjects, player, urinateValue, bladderMaxValue, peeInContainerRequirement, hasShyBladder, modOptions)
end

-- =====================================================
--
-- RELIEF METHODS
--
-- =====================================================

function BF.AddGroundOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeOnGroundRequirement, poopOnGroundRequirement, hasShyBladder, hasShyBowels, isBeingWatched)
    local groundPeeOption = peeSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseGround"), worldObjects, BF.TriggerGroundUrinate, player)
    BF.AddTooltip(groundPeeOption, getText("ContextMenu_tooltip_PeeGround", tostring(peeOnGroundRequirement)))
    groundPeeOption.iconTexture = getTexture("media/textures/ContextMenuGround.png")

    local groundPoopOption = poopSubMenu:addOption(getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseGround"), worldObjects, nil)
    BF.AddTooltip(groundPoopOption, getText("ContextMenu_tooltip_PoopGround", tostring(poopOnGroundRequirement)))
    groundPoopOption.iconTexture = getTexture("media/textures/ContextMenuGround.png")

    if urinateValue < (peeOnGroundRequirement / 100) * bladderMaxValue or hasShyBladder then
        groundPeeOption.notAvailable = true
        if hasShyBladder and BF.AddTooltip then
            BF.AddTooltip(groundPeeOption, getText("ContextMenu_tooltip_ShyPee"))
        end
    elseif player:isFemale() then
        -- Female characters can wipe after urinating on the ground.
        local wipeSubMenuForGroundPee = BF.AddWipingOptions(
            peeSubMenu, worldObjects, player, urinateValue, peeOnGroundRequirement, bladderMaxValue, BF.TriggerGroundUrinate, nil, "pee"
        )
        if wipeSubMenuForGroundPee then
            peeSubMenu:addSubMenu(groundPeeOption, wipeSubMenuForGroundPee)
        end
    end

    if defecateValue < (poopOnGroundRequirement / 100) * bowelsMaxValue or hasShyBowels then
        groundPoopOption.notAvailable = true
        if hasShyBowels and BF.AddTooltip then
            BF.AddTooltip(groundPoopOption, getText("ContextMenu_tooltip_ShyPoop"))
        end
    end

    if defecateValue >= (poopOnGroundRequirement / 100) * bowelsMaxValue and not (hasShyBowels and isBeingWatched) then
        local wipeSubMenuForGround = BF.AddWipingOptions(
            poopSubMenu, worldObjects, player, defecateValue, poopOnGroundRequirement, bowelsMaxValue, BF.TriggerGroundDefecate, nil, "poop"
        )
        if wipeSubMenuForGround then
            poopSubMenu:addSubMenu(groundPoopOption, wipeSubMenuForGround)
        end
    end
end
function BF.AddSelfOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeOnSelfRequirement, poopOnSelfRequirement, hasShyBladder, hasShyBowels, modOptions)
    local canPeeSelfOption = modOptions:getOption("2")
    if canPeeSelfOption:getValue(1) then
        local selfPeeOption = peeSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseSelf"), worldObjects, BF.TriggerSelfUrinate, player)
        BF.AddTooltip(selfPeeOption, getText("ContextMenu_tooltip_PeeSelf", tostring(peeOnSelfRequirement)))
        selfPeeOption.iconTexture = getTexture("media/ui/PeedSelf.png")
        if urinateValue < (peeOnSelfRequirement / 100) * bladderMaxValue or hasShyBladder then
            selfPeeOption.notAvailable = true
            if hasShyBladder then
                BF.AddTooltip(selfPeeOption, getText("ContextMenu_tooltip_ShyPeeSelf"))
            end
        end
    end

    local canPoopSelfOption = modOptions:getOption("3")
    if canPoopSelfOption:getValue(1) then
        local selfPoopOption = poopSubMenu:addOption(getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseSelf"), worldObjects, BF.TriggerSelfDefecate, player)
        BF.AddTooltip(selfPoopOption, getText("ContextMenu_tooltip_PoopSelf", tostring(poopOnSelfRequirement)))
        selfPoopOption.iconTexture = getTexture("media/ui/PoopedSelf.png")
        if defecateValue < (poopOnSelfRequirement / 100) * bowelsMaxValue or hasShyBowels then
            selfPoopOption.notAvailable = true
            if hasShyBowels then
                BF.AddTooltip(selfPoopOption, getText("ContextMenu_tooltip_ShyPoopSelf"))
            end
        end
    end
end

function BF.AddToiletOptions(vanillaToiletSubMenu, worldObjects, player, urinateValue, defecateValue,
    bladderMaxValue, bowelsMaxValue, peeInToiletRequirement, poopInToiletRequirement, toiletTiles)

    if not vanillaToiletSubMenu then return end

    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)
        for j = 1, #toiletTiles do
            local tile = toiletTiles[j]
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local isPodiumToilet = tile == "location_entertainment_gallery_02_56"
                local toiletText = isPodiumToilet and getText("ContextMenu_UsePodiumToilet") or getText("ContextMenu_UseToilet")

                local toiletPeeOption = vanillaToiletSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. toiletText, object, BF.TriggerToiletUrinate, player)
                local toiletPoopOption = vanillaToiletSubMenu:addOption(getText("ContextMenu_Poop") .. " " .. toiletText, object, BF.TriggerToiletDefecate, player)
                BF.AddTooltip(toiletPeeOption, "Urinate in the " .. (isPodiumToilet and "podium toilet" or "toilet") .. ". (Requires " .. peeInToiletRequirement .. "%)")
                BF.AddTooltip(toiletPoopOption, "Defecate in the " .. (isPodiumToilet and "podium toilet" or "toilet") .. ". (Requires " .. poopInToiletRequirement .. "%)")
                toiletPeeOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png")
                toiletPoopOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png")

                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue then
                    toiletPeeOption.notAvailable = true
                elseif player:isFemale() then
                    -- Female characters can wipe after urinating in the toilet.
                    local wipeSubMenuForToiletPee = BF.AddWipingOptions(
                        vanillaToiletSubMenu, worldObjects, player, urinateValue, peeInToiletRequirement, bladderMaxValue, BF.TriggerToiletUrinate, object, "pee"
                    )
                    if wipeSubMenuForToiletPee then
                        vanillaToiletSubMenu:addSubMenu(toiletPeeOption, wipeSubMenuForToiletPee)
                    end
                end

                if defecateValue < (poopInToiletRequirement / 100) * bowelsMaxValue then
                    toiletPoopOption.notAvailable = true
                else
                    local wipeSubMenuForToiletPoop = BF.AddWipingOptions(
                        vanillaToiletSubMenu, worldObjects, player, defecateValue, poopInToiletRequirement, bowelsMaxValue, BF.TriggerToiletDefecate, object, "poop"
                    )
                    if wipeSubMenuForToiletPoop then
                        vanillaToiletSubMenu:addSubMenu(toiletPoopOption, wipeSubMenuForToiletPoop)
                    end
                end

                return
            end
        end
    end
end
function BF.AddUrinalOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, bladderMaxValue, peeInToiletRequirement, urinalTiles, hasShyBladder)
    if not player:isFemale() then
        for i = 0, worldObjects:size() - 1 do
            local object = worldObjects:get(i)
            for j = 1, #urinalTiles do
                local tile = urinalTiles[j]
                if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                    local urinalPeeOption = peeSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseUrinal"), object, BF.TriggerToiletUrinate, player)
                    BF.AddTooltip(urinalPeeOption, getText("ContextMenu_tooltip_PeeUrinal", tostring(peeInToiletRequirement)))
                    urinalPeeOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png")
                    if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue or hasShyBladder then
                        urinalPeeOption.notAvailable = true
                        if hasShyBladder then
                            BF.AddTooltip(urinalPeeOption, getText("ContextMenu_tooltip_ShyPeeUrinal"))
                        end
                    end

                    local urinalPoopOption = poopSubMenu:addOption(getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseUrinal"), object, nil, player)
                    BF.AddTooltip(urinalPoopOption, getText("ContextMenu_tooltip_PoopUrinal"))
                    urinalPoopOption.notAvailable = true
                    urinalPoopOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png")
                    break
                end
            end
        end
    end
end
function BF.AddOuthouseOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeInToiletRequirement, poopInToiletRequirement, outhouseTiles, toiletOptionAdded)
    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)
        for j = 1, #outhouseTiles do
            local tile = outhouseTiles[j]
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local outhousePeeOption = peeSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseOuthouse"), object, BF.TriggerToiletUrinate, player)
                local outhousePoopOption = poopSubMenu:addOption(getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseOuthouse"), object, BF.TriggerToiletDefecate, player)
                BF.AddTooltip(outhousePeeOption, getText("ContextMenu_tooltip_PeeOuthouse", tostring(peeInToiletRequirement)))
                BF.AddTooltip(outhousePoopOption, getText("ContextMenu_tooltip_PoopOuthouse", tostring(poopInToiletRequirement)))
                outhousePeeOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png")
                outhousePoopOption.iconTexture = getTexture("media/textures/ContextMenuToilet.png")
                toiletOptionAdded = true

                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue then
                    outhousePeeOption.notAvailable = true
                end
                if defecateValue < (poopInToiletRequirement / 100) * bowelsMaxValue then
                    outhousePoopOption.notAvailable = true
                end
                if outhousePoopOption.notAvailable then
                    return
                end

                local wipeSubMenuForToilet = BF.AddWipingOptions(
                    poopSubMenu, worldObjects, player, defecateValue, poopInToiletRequirement, bowelsMaxValue, BF.TriggerToiletDefecate, object, "poop"
                )
                poopSubMenu:addSubMenu(outhousePoopOption, wipeSubMenuForToilet)
                break
            end
        end
    end
end

function BF.AddSinkOptions(vanillaSinkSubMenu, worldObjects, player, urinateValue,
    bladderMaxValue, peeInToiletRequirement, sinkTiles, hasShyBladder)

    if not vanillaSinkSubMenu then return end

    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)
        if object:getTextureName() and luautils.stringStarts(object:getTextureName(), "fixtures_sinks_01")
            and object:getSquare():DistToProper(player:getSquare()) < 5 then

            local sinkPeeOption = vanillaSinkSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseSink"), object, BF.TriggerFixtureUrinate, player)
            BF.AddTooltip(sinkPeeOption, getText("ContextMenu_tooltip_PeeSink", tostring(peeInToiletRequirement)))
            sinkPeeOption.iconTexture = getTexture("media/textures/ContextMenuSink.png")

            if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue or hasShyBladder then
                sinkPeeOption.notAvailable = true
                if hasShyBladder then
                    BF.AddTooltip(sinkPeeOption, getText("ContextMenu_tooltip_ShyPeeSink"))
                end
            elseif player:isFemale() then
                -- Female characters can wipe after urinating at the sink.
                local wipeSubMenuForSink = BF.AddWipingOptions(
                    vanillaSinkSubMenu, worldObjects, player, urinateValue, peeInToiletRequirement, bladderMaxValue, BF.TriggerFixtureUrinate, object, "pee"
                )
                if wipeSubMenuForSink then
                    vanillaSinkSubMenu:addSubMenu(sinkPeeOption, wipeSubMenuForSink)
                end
            end

            return
        end
    end
end

function BF.AddShowerOptions(peeSubMenu, worldObjects, player, urinateValue, bladderMaxValue, peeInToiletRequirement, showerTiles, hasShyBladder)
    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)
        for j = 1, #showerTiles do
            local tile = showerTiles[j]
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local showerPeeOption = peeSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseShower"), object, BF.TriggerFixtureUrinate, player)
                BF.AddTooltip(showerPeeOption, getText("ContextMenu_tooltip_PeeShower", tostring(peeInToiletRequirement)))
                showerPeeOption.iconTexture = getTexture("media/textures/ContextMenuShower.png")
                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue or hasShyBladder then
                    showerPeeOption.notAvailable = true
                    if hasShyBladder then
                        BF.AddTooltip(showerPeeOption, getText("ContextMenu_tooltip_ShyPeeShower"))
                    end
                end
                break
            end
        end
    end
end
--- Doesn't work yet.
function BF.AddBathtubOptions(peeSubMenu, worldObjects, player, urinateValue, bladderMaxValue, peeInToiletRequirement, bathtubTiles, hasShyBladder)
    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)
        for j = 1, #bathtubTiles do
            local tile = bathtubTiles[j]
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local bathtubPeeOption = peeSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseBathtub"), object, BF.TriggerFixtureUrinate, player)
                BF.AddTooltip(bathtubPeeOption, getText("ContextMenu_tooltip_PeeBathtub", tostring(peeInToiletRequirement)))
                bathtubPeeOption.iconTexture = getTexture("media/textures/ContextMenuBathtub.png")
                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue or hasShyBladder then
                    bathtubPeeOption.notAvailable = true
                    if hasShyBladder then
                        BF.AddTooltip(bathtubPeeOption, getText("ContextMenu_tooltip_ShyPeeBathtub"))
                    end
                end
                break
            end
        end
    end
end

function BF.AddBushOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeInToiletRequirement, poopInToiletRequirement, bushTiles, hasShyBladder, hasShyBowels)
    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)
        for j = 1, #bushTiles do
            local tile = bushTiles[j]
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local bushPeeOption = peeSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseBush"), object, BF.TriggerFixtureUrinate, player)
                local bushPoopOption = poopSubMenu:addOption(getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseBush"), object, BF.TriggerFixtureDefecate, player)
                BF.AddTooltip(bushPeeOption, getText("ContextMenu_tooltip_PeeBush", tostring(peeInToiletRequirement)))
                BF.AddTooltip(bushPoopOption, getText("ContextMenu_tooltip_PoopBush", tostring(poopInToiletRequirement)))
                bushPeeOption.iconTexture = getTexture("media/textures/ContextMenuBush.png")
                bushPoopOption.iconTexture = getTexture("media/textures/ContextMenuBush.png")

                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue or hasShyBladder then
                    bushPeeOption.notAvailable = true
                    if hasShyBladder then
                        BF.AddTooltip(bushPeeOption, getText("ContextMenu_tooltip_ShyPeeBush"))
                    end
                end

                if defecateValue < (poopInToiletRequirement / 100) * bowelsMaxValue or hasShyBowels then
                    bushPoopOption.notAvailable = true
                    if hasShyBowels then
                        BF.AddTooltip(bushPoopOption, getText("ContextMenu_tooltip_ShyPoopBush"))
                    end
                else
                    local wipeSubMenuForBush = BF.AddWipingOptions(
                        poopSubMenu, worldObjects, player, defecateValue, poopInToiletRequirement, bowelsMaxValue, BF.TriggerFixtureDefecate, object, "poop"
                    )
                    if wipeSubMenuForBush then
                        poopSubMenu:addSubMenu(bushPoopOption, wipeSubMenuForBush)
                    end
                end
                break
            end
        end
    end
end
--- Trees unimplemented so far
function BF.AddTreeOptions(peeSubMenu, worldObjects, player, urinateValue, bladderMaxValue, peeInToiletRequirement, treeTiles, hasShyBladder)
    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)
        for j = 1, #treeTiles do
            local tile = treeTiles[j]
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local treePeeOption = peeSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseTree"), object, BF.TriggerFixtureUrinate, player)
                BF.AddTooltip(treePeeOption, getText("ContextMenu_tooltip_PeeTree", tostring(peeInToiletRequirement)))
                treePeeOption.iconTexture = getTexture("media/textures/ContextMenuTree.png")
                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue or hasShyBladder then
                    treePeeOption.notAvailable = true
                    if hasShyBladder then
                        BF.AddTooltip(treePeeOption, getText("ContextMenu_tooltip_ShyPeeTree"))
                    end
                end
                break
            end
        end
    end
end
function BF.AddWaterOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeInToiletRequirement, poopInToiletRequirement, waterTiles, hasShyBladder, hasShyBowels)
    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)
        for j = 1, #waterTiles do
            local tile = waterTiles[j]
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local waterPeeOption = peeSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseWater"), object, BF.TriggerFixtureUrinate, player)
                local waterPoopOption = poopSubMenu:addOption(getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseWater"), object, BF.TriggerFixtureDefecate, player)
                BF.AddTooltip(waterPeeOption, getText("ContextMenu_tooltip_PeeWater", tostring(peeInToiletRequirement)))
                BF.AddTooltip(waterPoopOption, getText("ContextMenu_tooltip_PoopWater", tostring(poopInToiletRequirement)))
                waterPeeOption.iconTexture = getTexture("media/textures/ContextMenuWater.png")
                waterPoopOption.iconTexture = getTexture("media/textures/ContextMenuWater.png")

                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue or hasShyBladder then
                    waterPeeOption.notAvailable = true
                    if hasShyBladder then
                        BF.AddTooltip(waterPeeOption, getText("ContextMenu_tooltip_ShyPeeWater"))
                    end
                end

                if defecateValue < (poopInToiletRequirement / 100) * bowelsMaxValue or hasShyBowels then
                    waterPoopOption.notAvailable = true
                    if hasShyBowels then
                        BF.AddTooltip(waterPoopOption, getText("ContextMenu_tooltip_ShyPoopWater"))
                    end
                else
                    local wipeSubMenuForWater = BF.AddWipingOptions(
                        poopSubMenu, worldObjects, player, defecateValue, poopInToiletRequirement, bowelsMaxValue, BF.TriggerFixtureDefecate, object, "poop"
                    )
                    if wipeSubMenuForWater then
                        poopSubMenu:addSubMenu(waterPoopOption, wipeSubMenuForWater)
                    end
                end
                break
            end
        end
    end
end

function BF.AddTrashCanOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeInToiletRequirement, poopInToiletRequirement, trashCanTiles, hasShyBladder, hasShyBowels)
    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)
        for j = 1, #trashCanTiles do
            local tile = trashCanTiles[j]
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local trashCanPeeOption = peeSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseTrashCan"), object, BF.TriggerFixtureUrinate, player)
                local trashCanPoopOption = poopSubMenu:addOption(getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseTrashCan"), object, BF.TriggerFixtureDefecate, player)
                BF.AddTooltip(trashCanPeeOption, getText("ContextMenu_tooltip_PeeTrashCan", tostring(peeInToiletRequirement)))
                BF.AddTooltip(trashCanPoopOption, getText("ContextMenu_tooltip_PoopTrashCan", tostring(poopInToiletRequirement)))
                trashCanPeeOption.iconTexture = getTexture("media/textures/ContextMenuTrashCan.png")
                trashCanPoopOption.iconTexture = getTexture("media/textures/ContextMenuTrashCan.png")

                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue or hasShyBladder then
                    trashCanPeeOption.notAvailable = true
                    if hasShyBladder then
                        BF.AddTooltip(trashCanPeeOption, getText("ContextMenu_tooltip_ShyPeeTrashCan"))
                    end
                end

                if defecateValue < (poopInToiletRequirement / 100) * bowelsMaxValue or hasShyBowels then
                    trashCanPoopOption.notAvailable = true
                    if hasShyBowels then
                        BF.AddTooltip(trashCanPoopOption, getText("ContextMenu_tooltip_ShyPoopTrashCan"))
                    end
                else
                    local wipeSubMenuForTrashCan = BF.AddWipingOptions(
                        poopSubMenu, worldObjects, player, defecateValue, poopInToiletRequirement, bowelsMaxValue, BF.TriggerFixtureDefecate, object, "poop"
                    )
                    if wipeSubMenuForTrashCan then
                        poopSubMenu:addSubMenu(trashCanPoopOption, wipeSubMenuForTrashCan)
                    end
                end
                break
            end
        end
    end
end
function BF.AddDumpsterOptions(peeSubMenu, poopSubMenu, worldObjects, player, urinateValue, defecateValue, bladderMaxValue, bowelsMaxValue, peeInToiletRequirement, poopInToiletRequirement, dumpsterTiles, hasShyBladder, hasShyBowels)
    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)
        for j = 1, #dumpsterTiles do
            local tile = dumpsterTiles[j]
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local dumpsterPeeOption = peeSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseDumpster"), object, BF.TriggerFixtureUrinate, player)
                local dumpsterPoopOption = poopSubMenu:addOption(getText("ContextMenu_Poop") .. " " .. getText("ContextMenu_UseDumpster"), object, BF.TriggerFixtureDefecate, player)
                BF.AddTooltip(dumpsterPeeOption, getText("ContextMenu_tooltip_PeeDumpster", tostring(peeInToiletRequirement)))
                BF.AddTooltip(dumpsterPoopOption, getText("ContextMenu_tooltip_PoopDumpster", tostring(poopInToiletRequirement)))
                dumpsterPeeOption.iconTexture = getTexture("media/textures/ContextMenuDumpster.png")
                dumpsterPoopOption.iconTexture = getTexture("media/textures/ContextMenuDumpster.png")

                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue or hasShyBladder then
                    dumpsterPeeOption.notAvailable = true
                    if hasShyBladder then
                        BF.AddTooltip(dumpsterPeeOption, getText("ContextMenu_tooltip_ShyPeeDumpster"))
                    end
                end

                if defecateValue < (poopInToiletRequirement / 100) * bowelsMaxValue or hasShyBowels then
                    dumpsterPoopOption.notAvailable = true
                    if hasShyBowels then
                        BF.AddTooltip(dumpsterPoopOption, getText("ContextMenu_tooltip_ShyPoopDumpster"))
                    end
                else
                    local wipeSubMenuForDumpster = BF.AddWipingOptions(
                        poopSubMenu, worldObjects, player, defecateValue, poopInToiletRequirement, bowelsMaxValue, BF.TriggerFixtureDefecate, object, "poop"
                    )
                    if wipeSubMenuForDumpster then
                        poopSubMenu:addSubMenu(dumpsterPoopOption, wipeSubMenuForDumpster)
                    end
                end
                break
            end
        end
    end
end

function BF.AddOpenWindowOptions(peeSubMenu, worldObjects, player, urinateValue, bladderMaxValue, peeInToiletRequirement, openWindowTiles, hasShyBladder)
    for i = 0, worldObjects:size() - 1 do
        local object = worldObjects:get(i)
        for j = 1, #openWindowTiles do
            local tile = openWindowTiles[j]
            if object:getTextureName() == tile and object:getSquare():DistToProper(player:getSquare()) < 5 then
                local openWindowPeeOption = peeSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseOpenWindow"), object, BF.TriggerFixtureUrinate, player)
                BF.AddTooltip(openWindowPeeOption, getText("ContextMenu_tooltip_PeeOpenWindow", tostring(peeInToiletRequirement)))
                openWindowPeeOption.iconTexture = getTexture("media/textures/ContextMenuOpenWindow.png")
                if urinateValue < (peeInToiletRequirement / 100) * bladderMaxValue or hasShyBladder then
                    openWindowPeeOption.notAvailable = true
                    if hasShyBladder then
                        BF.AddTooltip(openWindowPeeOption, getText("ContextMenu_tooltip_ShyPeeOpenWindow"))
                    end
                end
                break
            end
        end
    end
end

function BF.AddContainerOptions(peeSubMenu, worldObjects, player, urinateValue, bladderMaxValue, peeInContainerRequirement, hasShyBladder, modOptions)
    local canPeeContainerOption = modOptions:getOption("1")
    if canPeeContainerOption:getValue(1) then
        local containerPeeOption = peeSubMenu:addOption(getText("ContextMenu_Pee") .. " " .. getText("ContextMenu_UseContainer"), worldObjects, nil)
        BF.AddTooltip(containerPeeOption, getText("ContextMenu_tooltip_PeeContainer", tostring(peeInContainerRequirement)))
        local containerSubMenu = ISContextMenu:getNew(peeSubMenu)
        peeSubMenu:addSubMenu(containerPeeOption, containerSubMenu)
        containerPeeOption.iconTexture = getTexture("media/textures/Item_BottleOfPee.png")

        local hasValidContainers = false
        for i = 0, player:getInventory():getItems():size() - 1 do
            local item = player:getInventory():getItems():get(i)
            if item:getFluidContainer() and item:getFluidContainer():isEmpty() then
                containerSubMenu:addOption("Use " .. item:getName(), item, BF.PeeInContainer)
                hasValidContainers = true
            end
        end

        if urinateValue < (peeInContainerRequirement / 100) * bladderMaxValue or hasShyBladder or not hasValidContainers then
            containerPeeOption.notAvailable = true
            if hasShyBladder then
                BF.AddTooltip(containerPeeOption, getText("ContextMenu_tooltip_ShyPeeContainer"))
            end
        end
    end
end

-- =====================================================
--
-- EXTRAS
--
-- =====================================================

function BF.IsBeingWatched(player)
    local isBeingWatched = false
    
    if player:hasTrait(BFTraits.Paruresis) or player:hasTrait(BFTraits.Paruresis) or 
       player:hasTrait(BFTraits.ShyBladder) or player:hasTrait(BFTraits.ShyBladder) then
        
        local checkRange = 10
        local playerX = player:getX()
        local playerY = player:getY()
        local playerZ = player:getZ()
        local playerSquare = player:getSquare()
        
        local function hasLineOfSight(fromSquare, toSquare)
            if not fromSquare or not toSquare then return false end
            return LosUtil.lineClear(getCell(), fromSquare:getX(), fromSquare:getY(), fromSquare:getZ(), 
                                     toSquare:getX(), toSquare:getY(), toSquare:getZ(), false)
        end
        
        local zombies = getCell():getZombieList()
        for i = 0, zombies:size() - 1 do
            local zombie = zombies:get(i)
            if zombie:getZ() == playerZ and 
               math.abs(zombie:getX() - playerX) <= checkRange and 
               math.abs(zombie:getY() - playerY) <= checkRange then
                if hasLineOfSight(zombie:getSquare(), playerSquare) then
                    isBeingWatched = true
                    break
                end
            end
        end
        
        if not isBeingWatched then
            local players = getOnlinePlayers()
            if players then
                for i = 0, players:size() - 1 do
                    local otherPlayer = players:get(i)
                    if otherPlayer ~= player and otherPlayer:getZ() == playerZ and 
                       math.abs(otherPlayer:getX() - playerX) <= checkRange and 
                       math.abs(otherPlayer:getY() - playerY) <= checkRange then
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
-- Generic wiping submenu builder. Works for both defecation and (female-only)
-- urination. Lists EVERY reachable wipeable as its own option so the player can
-- pick which item to use. `bodilyFunction` is "poop" or "pee".
function BF.AddWipingOptions(parentMenu, worldObjects, player, value, requirement, maxValue, triggerFunction, targetObject, bodilyFunction)
    bodilyFunction = bodilyFunction or "poop"

    if value < (requirement / 100) * maxValue then
        return nil
    end

    -- Shyness checks (poop uses bowel traits, pee uses bladder traits).
    local isBeingWatched = BF.IsBeingWatched(player)
    if bodilyFunction == "poop" then
        if (player:hasTrait(BFTraits.Parcopresis) or player:hasTrait(BFTraits.ShyBowels)) and isBeingWatched then
            return nil
        end
    else
        if (player:hasTrait(BFTraits.Paruresis) or player:hasTrait(BFTraits.ShyBladder)) and isBeingWatched then
            return nil
        end
    end

    local wipeSubMenu = ISContextMenu:getNew(parentMenu)
    local isGround = (triggerFunction == BF.TriggerGroundDefecate or triggerFunction == BF.TriggerGroundUrinate)

    -- "Don't wipe" option.
    local penaltyText = (bodilyFunction == "pee") and "3% soiling penalty" or "5% soiling penalty"
    local dontWipeOption
    if isGround then
        dontWipeOption = wipeSubMenu:addOption(getText("ContextMenu_DontWipe"), false, triggerFunction, nil, nil, 0)
    else
        dontWipeOption = wipeSubMenu:addOption(getText("ContextMenu_DontWipe"), targetObject, triggerFunction, player, false, nil, nil, 0)
    end
    BF.AddTooltip(dontWipeOption, "Choose not to wipe. (" .. penaltyText .. ")")

    -- One option per reachable wipeable item.
    local wipeables = BF.CollectWipeables(player)
    for _, opt in ipairs(wipeables) do
        local wipeType = opt.wipeType
        local wipeItem = opt.item
        local wipeEfficiency = opt.efficiency
        local pooledTypes = opt.pooledTypes

        local wipePercentage = math.floor(wipeEfficiency * 100)
        -- Use the pooled label if present (e.g. "Wipe With: Paper scraps"),
        -- otherwise fall back to the item's own name.
        local label = opt.label or (getText("ContextMenu_WipeWith") .. " " .. wipeItem:getName())
        label = label .. " (" .. wipePercentage .. "%)"

        local doWipeOption
        if isGround then
            doWipeOption = wipeSubMenu:addOption(label, true, triggerFunction, wipeType, wipeItem, wipeEfficiency, pooledTypes)
        else
            doWipeOption = wipeSubMenu:addOption(label, targetObject, triggerFunction, player, true, wipeType, wipeItem, wipeEfficiency, pooledTypes)
        end

        local basePenalty = (bodilyFunction == "pee") and 3 or 5
        local penaltyPercentage = basePenalty * (1 - wipeEfficiency)
        BF.AddTooltip(doWipeOption, "Wipe using this item. (" .. string.format("%.2f", penaltyPercentage) .. "% soiling penalty)")
    end

    return wipeSubMenu
end

Events.OnFillWorldObjectContextMenu.Add(BF.ReliefRightClick)