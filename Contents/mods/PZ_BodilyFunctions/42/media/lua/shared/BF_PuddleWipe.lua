-- =====================================================
--
-- BF_PuddleWipe
--
-- Wiping up a urine puddle with the same things used for wiping yourself,
-- plus soap. Shared so the client menu and the server (Commands.wipePuddle in
-- BF_ServerCommands) count supplies the same way.
--
-- Amounts are in "wipes": one wipe is what wiping yourself once takes
-- (usesRequired in BF_WipingConfig), for example 4 of a toilet paper roll's 32
-- uses. A puddle needs WIPES_PER_LITER wipes per liter, so a typical 0.5 L pee
-- puddle takes about 20% of a roll.
--
-- Soap is counted in units: one use of a bar of soap, or 0.1 L of cleaning
-- liquid (the same as vanilla clothes washing). A puddle needs
-- SOAP_PER_LITER units per liter, at least one.
--
-- With too few wipes or too little soap, only part of the puddle is wiped up
-- and the rest is left. Books aren't used for this.
--
-- =====================================================

require "BF_Shared"
require "BF_Sewage"
require "BF_Wipes"

BF_PuddleWipe = {}
local P = BF_PuddleWipe

P.WIPES_PER_LITER = 3.2
P.SOAP_PER_LITER = 1
P.SOAP_LITERS_PER_UNIT = 0.1

-- Wipe types that can be used, and their config tables.
local function configs()
    return {
        usingDrainable = BF_WipingConfig.drainableWipeables,
        usingOneTime = BF_WipingConfig.oneTimeWipeables,
        usingClothTool = BF_WipingConfig.clothToolWipeables,
    }
end

function P.config(wipeType, itemType)
    local list = configs()[wipeType]
    return list and type(itemType) == "string" and list[itemType] or nil
end

-- Only puddles that are mostly urine.
function P.canWipe(puddle)
    return puddle ~= nil and BF_Sewage.isPuddle(puddle) and BF_Sewage.kindOf(puddle) == "urine"
end

function P.wipesNeeded(liters)
    return math.max(0, liters) * P.WIPES_PER_LITER
end

function P.soapNeeded(liters)
    return math.max(1, math.ceil(math.max(0, liters) * P.SOAP_PER_LITER))
end

local function soapUnits(item)
    if item:getFullType() == "Base.Soap2" and instanceof(item, "DrainableComboItem") then
        return item:getCurrentUses()
    end
    local fc = item:getFluidContainer()
    if fc and fc:contains(Fluid.CleaningLiquid) then
        return math.floor(fc:getSpecificFluidAmount(Fluid.CleaningLiquid) / P.SOAP_LITERS_PER_UNIT + 0.0001)
    end
    return 0
end

-- Soap units in the records (BF.BuildReachableItemRecords).
function P.soapAvailable(records)
    local total = 0
    for _, record in ipairs(records) do total = total + soapUnits(record.item) end
    return total
end

-- Server only: uses up `units` of soap from the records, bars first.
function P.useSoap(records, units)
    for _, record in ipairs(records) do
        if units <= 0 then return end
        local item = record.item
        if item:getFullType() == "Base.Soap2" and instanceof(item, "DrainableComboItem") then
            local take = math.min(units, item:getCurrentUses())
            for _ = 1, take do item:UseAndSync() end
            units = units - take
        end
    end
    for _, record in ipairs(records) do
        if units <= 0 then return end
        local item = record.item
        local take = math.min(units, soapUnits(item))
        if take > 0 and item:getFullType() ~= "Base.Soap2" then
            item:getFluidContainer():removeFluid(take * P.SOAP_LITERS_PER_UNIT, false)
            item:syncItemFields()
            units = units - take
        end
    end
end

-- How many wipes the records hold of one wipe type and item type. Pooled
-- "paper" items count together, as when wiping yourself. Grass only ever
-- counts up to its maxEfficiency share of what's needed (see P.share).
function P.wipesAvailable(records, wipeType, itemType)
    local config = P.config(wipeType, itemType)
    if not config then return 0 end
    local total = 0
    for _, record in ipairs(records) do
        local item = record.item
        local t = item:getType()
        if wipeType == "usingDrainable" then
            if t == itemType and BF.IsChargeBasedWipeable(item) then
                total = total + item:getCurrentUses() / config.usesRequired
            end
        elseif wipeType == "usingOneTime" then
            local other = BF_WipingConfig.oneTimeWipeables[t]
            if other and (t == itemType or (config.category == "paper" and other.category == "paper")) then
                total = total + 1 / other.usesRequired
            end
        elseif t == itemType then
            total = total + 1 / config.usesRequired
        end
    end
    return total
end

-- Share of the puddle (0 to 1) that can be wiped up with this item and the soap there is.
function P.share(records, wipeType, itemType, liters)
    local config = P.config(wipeType, itemType)
    if not config or liters <= 0 then return 0 end
    local byWipes = P.wipesAvailable(records, wipeType, itemType) / P.wipesNeeded(liters)
    local bySoap = P.soapAvailable(records) / P.soapNeeded(liters)
    return math.min(1, byWipes, bySoap, config.maxEfficiency or 1)
end

-- Server only: uses up `wipes` wipes of the item type from the records and
-- returns how many wipes were actually used. Uses and items are whole, so the
-- last one is spent in full. Cloth comes back as its wet or dirty version, as
-- after peeing.
function P.consume(player, records, wipeType, itemType, wipes)
    local config = P.config(wipeType, itemType)
    if not config or wipes <= 0 then return 0 end
    local done = 0

    if wipeType == "usingDrainable" then
        local rolls = {}
        for _, record in ipairs(records) do
            local item = record.item
            if item:getType() == itemType and BF.IsChargeBasedWipeable(item) and item:getCurrentUses() >= 1 then
                rolls[#rolls + 1] = item
            end
        end
        -- Sorted fullest last, so a nearly used up roll is used first.
        table.sort(rolls, function(a, b) return a:getCurrentUses() < b:getCurrentUses() end)
        local uses = math.ceil(wipes * config.usesRequired - 0.0001)
        for _, item in ipairs(rolls) do
            local take = math.min(uses, item:getCurrentUses())
            for _ = 1, take do item:UseAndSync() end
            uses = uses - take
            done = done + take / config.usesRequired
            if uses <= 0 then break end
        end

    elseif wipeType == "usingOneTime" then
        for _, record in ipairs(records) do
            if done >= wipes - 0.000001 then break end
            local t = record.item:getType()
            local other = BF_WipingConfig.oneTimeWipeables[t]
            if other and (t == itemType or (config.category == "paper" and other.category == "paper"))
                and BF.RemoveItemRecord(record) then
                done = done + 1 / other.usesRequired
            end
        end

    else
        local count = math.ceil(wipes * config.usesRequired - 0.0001)
        local inventory = player:getInventory()
        for _, record in ipairs(records) do
            if count <= 0 then break end
            if record.item:getType() == itemType and BF.RemoveItemRecord(record) then
                count = count - 1
                done = done + 1 / config.usesRequired
                if config.peeReplace then
                    local wet = inventory:AddItem(config.peeReplace)
                    if wet then sendAddItemToContainer(inventory, wet) end
                end
            end
        end
    end

    return math.min(done, wipes)
end

return P
