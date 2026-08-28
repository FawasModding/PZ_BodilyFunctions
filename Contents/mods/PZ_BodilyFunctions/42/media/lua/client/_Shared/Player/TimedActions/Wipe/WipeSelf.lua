-- WipeSelf: consumes wiping material and applies a soiling penalty to worn
-- clothing when the wipe was insufficient.
--
-- Wipe types:
--   usingDrainable  - toilet paper (charges)
--   usingOneTime    - paper items (count-based, possibly pooled across tiers)
--   usingBook       - books/notebooks; tears pages, returns clean paper + scraps
--   usingClothTool  - dishcloth/towel/rag: defecation -> mod junk, urination -> wet/dirty vanilla
--
-- bodilyFunction is "poop" or "pee". Pee wiping is female-only (gated by caller)
-- and applies a smaller penalty when insufficient.

---@class WipeSelf : ISBaseTimedAction
---@field character IsoPlayer
---@field wipeType string
---@field wipingWith InventoryItem
---@field bodilyFunction string
WipeSelf = ISBaseTimedAction:derive("WipeSelf")

-- Fallback junk if an item isn't in BF_WipeJunkMap.
local DEFAULT_JUNK_ITEM = "BF.SheetPaper2Pooped"
-- Clean pages returned when wiping with a book.
local BOOK_CLEAN_RETURN = "Base.SheetPaper2"
local BOOK_CLEAN_PAGES = 10

function WipeSelf:isValid()
    return true
end

function WipeSelf:update()
end

function WipeSelf:start()
end

function WipeSelf:stop()
    ISBaseTimedAction.stop(self)
end

-- Applies the residual soiling penalty to unequipped bottom clothing (stored in
-- removedClothing), preferring underwear. Works for both pee and poop.
function WipeSelf:applyResidualPenalty(soilPenalty)
    local func = self.bodilyFunction
    local severityKey = (func == "pee") and "peedSeverity" or "poopedSeverity"
    local flagKey = (func == "pee") and "peed" or "pooped"

    local removedClothing = self.character:getModData().removedClothing or {}

    local underwearLocations = {
        ItemBodyLocation.UNDERWEAR_BOTTOM,
        ItemBodyLocation.UNDERWEAR
    }

    -- Prefer unequipped underwear.
    for _, bodyLocation in ipairs(underwearLocations) do
        for _, entry in ipairs(removedClothing) do
            if entry:getBodyLocation() == bodyLocation then
                local modData = entry:getModData()
                modData[flagKey] = true
                modData[severityKey] = math.min((modData[severityKey] or 0) + soilPenalty, 100)
                return true
            end
        end
    end

    -- Otherwise, any unequipped non-underwear soilable garment.
    local soilableClothing = BF.GetSoilableClothing()
    for _, loc in ipairs(soilableClothing) do
        if loc ~= ItemBodyLocation.UNDERWEAR and loc ~= ItemBodyLocation.UNDERWEAR_BOTTOM then
            for _, entry in ipairs(removedClothing) do
                if entry:getBodyLocation() == loc then
                    local modData = entry:getModData()
                    modData[flagKey] = true
                    modData[severityKey] = math.min((modData[severityKey] or 0) + soilPenalty, 100)
                    return true
                end
            end
        end
    end

    return false
end

function WipeSelf:perform()
    ISBaseTimedAction.perform(self)

    local wipeEfficiency = 1.0

    -- Drainable (toilet paper): consume charges.
    if self.wipeType == "usingDrainable" then
        local itemType = self.wipingWith:getType()
        local requiredUses = BF_WipingConfig.drainableWipeables[itemType].usesRequired
        local availableUses = self.wipingWith:getCurrentUses()
        wipeEfficiency = math.min(availableUses / requiredUses, 1.0)
        for _ = 1, math.min(availableUses, requiredUses) do
            self.wipingWith:Use()
        end
        -- Toilet paper doesn't leave a junk item.
    end

    -- One-time paper: consume from the pooled types until a full wipe (weight 1.0)
    -- is reached. Each item contributes 1/usesRequired, so mixed tiers (tier-2
    -- sheets and tier-4 scraps) combine correctly. Junk is created per consumed
    -- item using that item's own mapping.
    local junkTally = {}   -- junkType -> count
    if self.wipeType == "usingOneTime" then
        local types = self.pooledTypes or { self.wipingWith:getType() }
        local cap = BF_WipingConfig.oneTimeWipeables[types[1]].maxEfficiency or 1.0

        -- Total available cleaning "weight" across the pool.
        local availableWeight = 0
        for _, t in ipairs(types) do
            local req = BF_WipingConfig.oneTimeWipeables[t].usesRequired
            availableWeight = availableWeight + (BF.CountReachableItemType(self.character, t) / req)
        end
        wipeEfficiency = math.min(availableWeight, cap)

        -- Consume items until we've reached weight 1.0 (a full wipe) or run out.
        local neededWeight = math.min(1.0, cap)
        local gatheredWeight = 0
        for _, t in ipairs(types) do
            if gatheredWeight >= neededWeight then break end
            local req = BF_WipingConfig.oneTimeWipeables[t].usesRequired
            local perItem = 1 / req
            local haveThis = BF.CountReachableItemType(self.character, t)
            for _ = 1, haveThis do
                if gatheredWeight >= neededWeight then break end
                local removed = BF.RemoveReachableItemType(self.character, t, 1)
                if removed <= 0 then break end
                gatheredWeight = gatheredWeight + perItem
                local junk = (BF_WipeJunkMap and BF_WipeJunkMap[t]) or DEFAULT_JUNK_ITEM
                junkTally[junk] = (junkTally[junk] or 0) + 1
            end
        end
    end

    -- Cloth tool (dishcloth / bath towel / ripped sheets): individual item.
    -- Defecation -> soiled mod junk (poopCount items). Urination -> the tool is
    -- consumed and replaced with its wet/dirty vanilla counterpart.
    if self.wipeType == "usingClothTool" then
        local itemType = self.wipingWith:getType()
        local cfg = BF_WipingConfig.clothToolWipeables[itemType]
        local available = BF.CountReachableItemType(self.character, itemType)
        wipeEfficiency = math.min(available / cfg.usesRequired, 1.0)

        local toConsume = math.min(available, cfg.usesRequired)
        BF.RemoveReachableItemType(self.character, itemType, toConsume)

        if self.bodilyFunction == "pee" then
            -- Becomes wet/dirty vanilla item (one per consumed tool).
            if cfg.peeReplace then
                for _ = 1, toConsume do
                    self.character:getInventory():AddItem(cfg.peeReplace)
                end
            end
        else
            -- Defecation: create the mod junk item(s).
            if cfg.poopJunk then
                local n = (cfg.poopCount or 1) * toConsume
                junkTally[cfg.poopJunk] = (junkTally[cfg.poopJunk] or 0) + n
            end
        end
    end

    -- Book: always a full wipe, tears pages, returns clean paper + junk scraps.
    if self.wipeType == "usingBook" then
        local itemType = self.wipingWith:getType()
        local bookCfg = BF_WipingConfig.bookWipeables[itemType]
        local pages = (bookCfg and bookCfg.usesRequired) or 10
        wipeEfficiency = 1.0

        -- Consume the book itself (wherever it lives: inv, bag, nearby, floor).
        BF.RemoveReachableItemType(self.character, itemType, 1)

        -- Return clean torn-out pages (the unused part of the book).
        for _ = 1, BOOK_CLEAN_PAGES do
            self.character:getInventory():AddItem(BOOK_CLEAN_RETURN)
        end

        -- A book produces a handful of dirty scraps (generic used paper).
        local bookJunk = math.max(1, math.floor(pages / 5))
        junkTally[DEFAULT_JUNK_ITEM] = (junkTally[DEFAULT_JUNK_ITEM] or 0) + bookJunk
    end

    -- Create the item-specific junk scraps for paper/book wipes.
    -- Only defecation produces soiled junk; urine wiping leaves no scrap.
    if self.bodilyFunction == "poop" then
        for junkType, n in pairs(junkTally) do
            for _ = 1, n do
                self.character:getInventory():AddItem(junkType)
            end
        end
    end

    -- Residual soiling penalty when the wipe was insufficient.
    if (self.wipeType == "usingOneTime" or self.wipeType == "usingDrainable" or self.wipeType == "usingBook")
        and wipeEfficiency < 1.0 then
        -- Pee residue is lighter than poop residue.
        local basePenalty = (self.bodilyFunction == "pee") and 3 or 5
        local soilPenalty = basePenalty * (1 - wipeEfficiency)
        if soilPenalty > 0 then
            self:applyResidualPenalty(soilPenalty)
        end
    end

end

function WipeSelf:new(character, time, wipeType, wipingWith, bodilyFunction, pooledTypes)
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
    o.pooledTypes = pooledTypes
    return o
end
