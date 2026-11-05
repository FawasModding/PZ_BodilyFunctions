-- =====================================================
--
-- BF_Shared
--
-- Handles client (menus, timed actions) and server (BF_ServerCommands)
-- both need this, so it's kept here so they don't have confusion
--
-- =====================================================

BF = BF or {}

-- -----------------------------------------------------
-- Sandbox switches and traits
-- -----------------------------------------------------

-- getSandboxOptions() rather than SandboxVars, because this is also read on the
-- character creation screen, before SandboxVars holds the chosen settings.
function BF.IsSandboxOptionOn(shortName)
    local option = getSandboxOptions():getOptionByName("BF." .. shortName)
    if option then
        return option:getValue() ~= false
    end
    local page = SandboxVars and SandboxVars.BF
    return not page or page[shortName] ~= false
end

function BF.IsUrinationEnabled()
    return BF.IsSandboxOptionOn("EnableUrination")
end

function BF.IsDefecationEnabled()
    return BF.IsSandboxOptionOn("EnableDefecation")
end

-- A group of traits is available only while its bodily function and its trait
-- option are both on.
local TRAIT_GROUPS = {
    {
        options = { "EnableDefecation", "EnableDefecationTraits" },
        traits = { "SmallBowels", "Bedsoiler", "FecalIncontinence", "Parcopresis", "ShyBowels", "BigBowels", "BowelControl" },
    },
    {
        options = { "EnableUrination", "EnableUrinationTraits" },
        traits = { "SmallBladder", "Bedwetter", "UrinaryIncontinence", "Paruresis", "ShyBladder", "BigBladder", "BladderControl" },
    },
}

-- True for every trait that isn't one of ours.
function BF.IsTraitEnabled(trait)
    for _, group in ipairs(TRAIT_GROUPS) do
        for _, name in ipairs(group.traits) do
            if BFTraits[name] == trait then
                return BF.IsSandboxOptionOn(group.options[1]) and BF.IsSandboxOptionOn(group.options[2])
            end
        end
    end
    return true
end

-- Using this instead of player:hasTrait for BF traits. A character who already has
-- a trait keeps it on their sheet when the option is turned off, but it stops
-- doing anything, and comes back if the option is turned on again.
function BF.HasTrait(player, trait)
    return player:hasTrait(trait) and BF.IsTraitEnabled(trait)
end

-- -----------------------------------------------------
-- Wiping
-- -----------------------------------------------------

-- Whether this item really spends charges, rather than whether its type happens
-- to be listed in drainableWipeables. Mods redefine vanilla items (Bath Towels
-- Overhaul turns Base.BathTowel into base:clothing), and those must not reach a
-- path that calls :Use() on something that can't be used up.
function BF.IsChargeBasedWipeable(item)
    return item ~= nil
        and instanceof(item, "DrainableComboItem")
        and item.getCurrentUses ~= nil
end

-- -----------------------------------------------------
-- Washing
-- -----------------------------------------------------

BF.WashWaterCost = { garment = 15, rag = 5 }

-- Soiled cloth that can be washed: what it turns into and the water that takes. A
-- towel comes out wet and dries back into a full towel on its own. Paper and grass
-- are disposable, so they aren't here.
BF.WashableJunk = {
    ["BF.RippedSheetsPooped"] = { clean = "Base.RippedSheets", water = BF.WashWaterCost.rag },
    ["BF.BathTowelPooped"] = { clean = "Base.BathTowelWet", water = BF.WashWaterCost.garment },
}

-- Cleaning agents changed shape in B42: soap is still a drainable with uses,
-- but bleach and cleaning liquid became FluidContainer items whose remaining
-- amount has nothing to do with getCurrentUses(). Checking uses alone treats an
-- empty bleach bottle as a full one, so both shapes are handled explicitly.
function BF.IsCleaningAgent(item)
    if not item then return false end

    if item:hasComponent(ComponentType.FluidContainer) then
        local fluidContainer = item:getFluidContainer()
        if not fluidContainer or fluidContainer:getAmount() <= 0 then return false end
        if Fluid.CleaningLiquid and fluidContainer:contains(Fluid.CleaningLiquid) then return true end
        if Fluid.Bleach and fluidContainer:contains(Fluid.Bleach) then return true end
        if Fluid.Soapy and fluidContainer:contains(Fluid.Soapy) then return true end
        return false
    end

    if instanceof(item, "DrainableComboItem") and item:getType() == "Soap2" then
        return item:getCurrentUses() > 0
    end

    return false
end

-- Spends one dose of the agent. Returns true when a dose was actually spent,
-- which is what decides whether the wash counts as a full clean.
function BF.ConsumeCleaningAgent(item)
    if not BF.IsCleaningAgent(item) then return false end

    if item:hasComponent(ComponentType.FluidContainer) then
        local fluidContainer = item:getFluidContainer()
        local newAmount = fluidContainer:getAmount() - ZomboidGlobals.CleanStainCleaningFluidAmount
        if newAmount <= 0.001 then
            fluidContainer:Empty()
        else
            fluidContainer:adjustAmount(newAmount)
        end
        sendItemStats(item)
        return true
    end

    item:UseAndSync()
    return true
end

-- One wash step. With an agent the garment comes out clean; with plain water it
-- halves and anything left under the threshold is close enough to call clean.
-- Previously a severity between 11 and 50 hit neither branch and washing did
-- nothing at all, no matter how many times it was repeated.
BF.WaterOnlyClearThreshold = 10

function BF.ReduceSoilSeverity(severity, usedCleaningAgent)
    severity = severity or 0
    if usedCleaningAgent then return 0 end

    severity = severity * 0.5
    if severity <= BF.WaterOnlyClearThreshold then return 0 end
    return severity
end

-- -----------------------------------------------------
-- Waste on the ground
-- -----------------------------------------------------

BF.WasteCleaningTools = { Mop = true, ToiletBrush = true, DishCloth = true, BathTowel = true }

BF.UrineWorldTypes = { ["BF.Urine_Hydrated_0"] = true, ["BF.Urine_Hydrated_1"] = true }

function BF.IsCleanableWaste(item)
    if not item then return false end
    local fullType = item:getFullType()
    return BF.UrineWorldTypes[fullType] == true or fullType == "BF.HumanFeces"
end

-- -----------------------------------------------------
-- Toilets
-- -----------------------------------------------------

-- Litres per flush, by the sprite's GroupName.
BF.ToiletWaterUse = { Fancy = 5, Low = 10, Hanging = 5 }

function BF.GetToiletGroup(object)
    local sprite = object and object:getSprite()
    local props = sprite and sprite:getProperties()
    if not props or not props:has("CustomName") or props:get("CustomName") ~= "Toilet" then return nil end
    return props:has("GroupName") and props:get("GroupName") or nil
end

-- nil for toilets that are not flushed (chemical, outhouse, unknown).
function BF.GetToiletWaterUse(object)
    local group = BF.GetToiletGroup(object)
    return group and BF.ToiletWaterUse[group] or nil
end
