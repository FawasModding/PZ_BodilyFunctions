---@class WipeSelf : ISBaseTimedAction
---@field character IsoPlayer
---@field wipeType string
---@field wipingWith InventoryItem
---@field bodilyFunction string
WipeSelf = ISBaseTimedAction:derive("WipeSelf")

function WipeSelf:isValid()
    return true
end

function WipeSelf:update()
    print(self.wipeType)
end

function WipeSelf:start()
end

function WipeSelf:stop()
    ISBaseTimedAction.stop(self)
end

function WipeSelf:perform()
    ISBaseTimedAction.perform(self)

    local wipeEfficiency = self:processWipe()

    if wipeEfficiency < 1.0 and self.bodilyFunction == "poop" then
        self:applyFailedWipePenalty(wipeEfficiency)
    end

    if self.wipeType == "usingClothing" then
        self:soilWipingClothing()
    end
end

-----------------------------------------------------------
-- Wipe processing
-----------------------------------------------------------

function WipeSelf:processWipe()
    if self.wipeType == "usingDrainable" then
        return self:processDrainableWipe()
    end

    if self.wipeType == "usingOneTime" then
        return self:processOneTimeWipe()
    end

    return 1.0
end

function WipeSelf:processDrainableWipe()
    local itemType = self.wipingWith:getType()
    local config = BF_WipingConfig.drainableWipeables[itemType]

    if not config then
        print("ERROR: No drainable wipe config for " .. tostring(itemType))
        return 1.0
    end

    local requiredUses = config.usesRequired
    local availableUses = self.wipingWith:getCurrentUses()

    local wipeEfficiency = math.min(
        availableUses / requiredUses,
        1.0
    )

    local usesToConsume = math.min(
        availableUses,
        requiredUses
    )

    for i = 1, usesToConsume do
        self.wipingWith:Use()
    end

    return wipeEfficiency
end

function WipeSelf:processOneTimeWipe()
    local itemType = self.wipingWith:getType()
    local config = BF_WipingConfig.oneTimeWipeables[itemType]

    if not config then
        print("ERROR: No one-time wipe config for " .. tostring(itemType))
        return 1.0
    end

    local requiredUses = config.usesRequired
    local inventory = self.character:getInventory()
    local availableItems = inventory:getNumberOfItem(itemType)

    local wipeEfficiency = math.min(
        availableItems / requiredUses,
        1.0
    )

    local itemsToConsume = math.min(
        availableItems,
        requiredUses
    )

    self:consumeOneTimeWipes(
        inventory,
        itemType,
        itemsToConsume
    )

    return wipeEfficiency
end

-----------------------------------------------------------
-- One-time wipeables
-----------------------------------------------------------

function WipeSelf:consumeOneTimeWipes(inventory, itemType, amount)
    for i = 1, amount do
        inventory:RemoveOneOf(itemType)

        self:addPoopedVariant(inventory, itemType)
    end

    print(
        "DEBUG: Consumed "
        .. amount
        .. " "
        .. itemType
        .. " item(s)"
    )
end

function WipeSelf:addPoopedVariant(inventory, itemType)
-- Only create a pooped item if this wipeable
    local poopedType = "BF." .. itemType .. "Pooped"

    -- Verify that the pooped variant actually exists.
    local scriptItem = ScriptManager.instance:getItem(poopedType)

    if not scriptItem then
        print(
            "DEBUG: No pooped variant found for "
            .. itemType
            .. " (expected "
            .. poopedType
            .. ")"
        )
        return
    end

    inventory:AddItem(poopedType)

    print(
        "DEBUG: Created pooped variant "
        .. poopedType
    )
end

-----------------------------------------------------------
-- Failed wipe penalty
-----------------------------------------------------------

function WipeSelf:applyFailedWipePenalty(wipeEfficiency)
    local soilPenalty = 5 * (1 - wipeEfficiency)

    local removedClothing =
        self.character:getModData().removedClothing or {}

    local applied = self:soilRemovedUnderwear(removedClothing, soilPenalty)

    if applied then
        return
    end

    self:soilRemovedNonUnderwear(
        removedClothing,
        soilPenalty
    )
end

function WipeSelf:soilRemovedUnderwear(removedClothing, soilPenalty)
    local underwearLocations = {
        ItemBodyLocation.UNDERWEAR_BOTTOM,
        ItemBodyLocation.UNDERWEAR
    }

    for _, bodyLocation in ipairs(underwearLocations) do
        local clothingItem = self:findRemovedClothing(
            removedClothing,
            bodyLocation
        )

        if clothingItem then
            self:soilClothing(
                clothingItem,
                soilPenalty,
                bodyLocation
            )

            return true
        end
    end

    return false
end

function WipeSelf:soilRemovedNonUnderwear(removedClothing, soilPenalty)
    local soilableClothing = BF.GetSoilableClothing()

    for _, bodyLocation in ipairs(soilableClothing) do
        if bodyLocation ~= ItemBodyLocation.UNDERWEAR
            and bodyLocation ~= ItemBodyLocation.UNDERWEAR_BOTTOM then

            local clothingItem = self:findRemovedClothing(
                removedClothing,
                bodyLocation
            )

            if clothingItem then
                self:soilClothing(
                    clothingItem,
                    soilPenalty,
                    bodyLocation
                )

                return true
            end
        end
    end

    print("DEBUG: No unequipped soilable clothing found")
    return false
end

function WipeSelf:findRemovedClothing(removedClothing, bodyLocation)
    for _, clothingItem in ipairs(removedClothing) do
        if clothingItem:getBodyLocation() == bodyLocation then
            return clothingItem
        end
    end

    return nil
end

-----------------------------------------------------------
-- Clothing soiling
-----------------------------------------------------------

function WipeSelf:soilClothing(clothingItem, soilPenalty, bodyLocation)
    local modData = clothingItem:getModData()

    modData.pooped = true
    modData.poopedSeverity =
        math.min(
            (modData.poopedSeverity or 0) + soilPenalty,
            100
        )

    print(
        "DEBUG: Applied "
        .. soilPenalty
        .. "% soiling to "
        .. clothingItem:getType()
        .. " at "
        .. tostring(bodyLocation)
    )
end

function WipeSelf:soilWipingClothing()
    local modData = self.wipingWith:getModData()
    local bodyLocation = self.wipingWith:getBodyLocation()

    local config =
        BF_WipingConfig.clothingWipeables[bodyLocation]

    if not config then
        print(
            "ERROR: No clothing wipe config for "
            .. tostring(bodyLocation)
        )
        return
    end

    local soilPenalty = config.soilPenalty or 5

    if self.bodilyFunction == "pee" then
        modData.peed = true
        modData.peedSeverity =
            math.min(
                (modData.peedSeverity or 0) + soilPenalty,
                100
            )

    elseif self.bodilyFunction == "poop" then
        modData.pooped = true
        modData.poopedSeverity =
            math.min(
                (modData.poopedSeverity or 0) + soilPenalty,
                100
            )
    end

    print(
        "DEBUG: Applied "
        .. soilPenalty
        .. "% soiling to wiping clothing "
        .. self.wipingWith:getType()
        .. " at "
        .. tostring(bodyLocation)
    )
end

-----------------------------------------------------------
-- Constructor
-----------------------------------------------------------

function WipeSelf:new(character, time, wipeType, wipingWith, bodilyFunction)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.character = character
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = time
    o.wipeType = wipeType
    o.wipingWith = wipingWith
    o.bodilyFunction = bodilyFunction

    return o
end