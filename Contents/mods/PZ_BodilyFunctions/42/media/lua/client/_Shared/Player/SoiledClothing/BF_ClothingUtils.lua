-- Helper function to check if the player is wearing any of the specified clothing
function BF.HasClothingOn(player, ...)
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
function BF.DirtyBottomsEffects()
    local player = getPlayer()
    local totalPoopedSeverity = 0
    local totalPeedSeverity = 0

    -- Iterate over all worn items
    for i = 0, player:getWornItems():size() - 1 do
        local item = player:getWornItems():getItemByIndex(i)

        -- Ensure the item is not nil before calling RefreshSoiledSeverityFromModData
        if item ~= nil then
            -- Update values for pooped and peed states based on item mod data
            local itemUpdatedPooped, itemUpdatedPeed = BF.RefreshSoiledSeverityFromModData(item)

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
    -- Bodily fumes from soiled *clothing* only appear once total soiling passes
    -- 30%. Below that, clothing contributes no smell (waste piles on the ground
    -- are handled separately in BF_WasteProducts).
    local FUMES_THRESHOLD = 30

    BF.SetPoopedSelfValue(totalPoopedSeverity > 0 and totalPoopedSeverity or 0)
    BF.SetPeedSelfValue(totalPeedSeverity > 0 and totalPeedSeverity or 0)

    if totalPoopedSeverity > FUMES_THRESHOLD then
        BF.SetBodilyFumesValue(50) -- feces smell (stage 2 of 4)
    elseif totalPeedSeverity > FUMES_THRESHOLD then
        BF.SetBodilyFumesValue(30) -- urine smell (stage 1 of 4)
    else
        -- Clothing isn't soiled enough to smell; clear the clothing-sourced fume.
        BF.SetBodilyFumesValue(0)
    end
end

-- FOR ITEMS IN GENERAL
function BF.ApplySoilingEffects(item, isLeak)
    -- Get the player object
    local player = getSpecificPlayer(0)
    
    -- If the item is marked as "peed" (wet), modify the item's properties
    if item:getModData().peed == true then
        if item:IsClothing() then
            local severity = item:getModData().peedSeverity / 100
            item:setWetness(math.min(500 * severity, 500))
            if item.setDirtiness then item:setDirtiness(math.min(100 * severity, 100)) end
            -- Apply dirt per covered body part instead of the above, deprecated.
            --local dirtVal = math.min(100 * severity, 100)
            --local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
            --if coveredParts then
            --    for j = 0, coveredParts:size() - 1 do
            --        item:setDirt(coveredParts:get(j), dirtVal)
            --    end
            --end
        end
    end

    -- If the item is marked as "pooped" (dirty), modify the item's properties
    if item:getModData().pooped == true then
        if item:IsClothing() then
            local severity = item:getModData().poopedSeverity / 100
            if item.setDirtyness then item:setDirtyness(math.min(100 * severity, 100)) end
            -- Apply dirt per covered body part instead of the above, deprecated.
            --local dirtVal = math.min(100 * severity, 100)
            --local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
            --if coveredParts then
            --    for j = 0, coveredParts:size() - 1 do
            --        item:setDirt(coveredParts:get(j), dirtVal)
            --    end
            --end
        end
    end
end

-- FOR CLOTHING SPECIFICALLY
function BF.RefreshSoiledSeverityFromModData(clothing)
    local updatedPooped = false
    local updatedPeed = false

    -- Ensure 'clothing' and its 'modData' are valid before proceeding
    if clothing ~= nil and clothing:getModData() ~= nil then
        local modData = clothing:getModData()

        if modData.pooped ~= nil then -- Check if the worn item is defecated
            BF.SetPoopedSelfValue(modData.poopedSeverity)
            updatedPooped = true
        else
            -- If no pooped state, set to 0 (can be skipped here if handled at the end of the loop)
            BF.SetPoopedSelfValue(0)
        end

        if modData.peed ~= nil then -- Check if the worn item is urinated
            BF.SetPeedSelfValue(modData.peedSeverity)
            updatedPeed = true
        else
            -- If no peed state, set to 0 (can be skipped here if handled at the end of the loop)
            BF.SetPeedSelfValue(0)
        end
    else
        print("Error: Clothing or mod data is nil in RefreshSoiledSeverityFromModData.")
    end

    -- Debugging output
    --print("Updated PeedSelfValue: " .. BF.GetPeedSelfValue())
    --print("Updated PoopedSelfValue: " .. BF.GetPoopedSelfValue())

    return updatedPooped, updatedPeed
end

--[[
Function defining all of the soilable clothing.
]]--
function BF.GetSoilableClothing()
    local bodyLocations = {ItemBodyLocation.UNDERWEAR_BOTTOM, ItemBodyLocation.UNDERWEAR, ItemBodyLocation.TORSO1LEGS1, ItemBodyLocation.LEGS1, ItemBodyLocation.PANTS, ItemBodyLocation.PANTS_SKINNY, ItemBodyLocation.BATH_ROBE, ItemBodyLocation.FULL_SUIT, ItemBodyLocation.FULL_SUIT_HEAD, ItemBodyLocation.FULL_TOP, ItemBodyLocation.BODY_COSTUME, ItemBodyLocation.SHORT_PANTS, ItemBodyLocation.SHORTS_SHORT}
    return bodyLocations
end

--[[
Clothes that need to be removed before using the bathroom. Includes dresses and skirts, which cannot be soiled (yet)
]]--
function BF.GetExcreteObstructiveClothing()
    local bodyLocations = {
    ItemBodyLocation.UNDERWEAR_BOTTOM, ItemBodyLocation.UNDERWEAR, ItemBodyLocation.TORSO1LEGS1, ItemBodyLocation.LEGS1,
    ItemBodyLocation.PANTS, ItemBodyLocation.PANTS_SKINNY, ItemBodyLocation.PANTS_EXTRA,
    ItemBodyLocation.BATH_ROBE, ItemBodyLocation.FULL_ROBE, ItemBodyLocation.FULL_SUIT, ItemBodyLocation.FULL_SUIT_HEAD, ItemBodyLocation.FULL_TOP,
    ItemBodyLocation.BOILERSUIT, ItemBodyLocation.BODY_COSTUME, ItemBodyLocation.CODPIECE,
    ItemBodyLocation.SHORT_PANTS, ItemBodyLocation.SHORTS_SHORT,
    ItemBodyLocation.LONG_DRESS, ItemBodyLocation.DRESS, ItemBodyLocation.LONG_SKIRT, ItemBodyLocation.SKIRT
    }

    return bodyLocations
end

--[[
Slots where tights, stockings, garters and modded legwear all live together, so
whether the garment blocks has to be decided per item instead of per slot.
]]--
function BF.GetExcreteConditionalClothing()
    local bodyLocations = {
    ItemBodyLocation.UNDERWEAR_EXTRA1, ItemBodyLocation.UNDERWEAR_EXTRA2, ItemBodyLocation.LEGS5
    }

    return bodyLocations
end

-- Per-item verdict that overrides every other rule. Key is the full item type.
-- Example: BF.ExcreteObstructiveOverride["Base.Stockings_60D"] = true
BF.ExcreteObstructiveOverride = BF.ExcreteObstructiveOverride or {}

-- When true every garment in a conditional legwear slot comes off, stockings included.
BF.RemoveAllLegwear = false

-- Names that mean the garment covers the crotch and has to come off.
BF.ExcreteObstructiveKeywords = {
    "tights", "pantyhose", "pantihose", "bodystocking", "leggings", "legging",
    "jeggings", "treggings", "leotard", "bodysuit", "catsuit", "unitard",
    "onesie", "jumpsuit", "romper", "playsuit", "longjohn", "girdle", "shapewear"
}

-- Names that mean the garment leaves the crotch free and can stay on.
BF.ExcreteHarmlessKeywords = {
    "stocking", "thighhigh", "kneehigh", "sock", "garter", "suspender",
    "harness", "legwarmer", "anklet", "holster", "sheath", "gaiter",
    "kneepad", "shinguard", "chaps"
}

-- Lowercased type and display names, once as written and once with separators
-- stripped, so a keyword matches "Socks_ThighHigh1" and "Thigh High Socks" alike.
local function bfNameForms(item)
    local forms = {}

    local function add(text)
        if text then
            local lowered = string.lower(text)
            forms[#forms + 1] = lowered
            forms[#forms + 1] = string.gsub(lowered, "[^%a%d]", "")
        end
    end

    add(item:getType())
    local script = item:getScriptItem()
    if script then add(script:getDisplayName()) end
    add(item:getName())

    return forms
end

local function bfMatchesAny(forms, keywords)
    for i = 1, #forms do
        for j = 1, #keywords do
            if string.find(forms[i], keywords[j], 1, true) then
                return true
            end
        end
    end

    return false
end

local function bfLocationInList(location, list)
    for i = 1, #list do
        if location == list[i] then
            return true
        end
    end

    return false
end

-- True when the garment's blood coverage includes the groin, which means it
-- physically sits over the crotch.
function BF.ItemCoversGroin(item)
    local clothingTypes = item:getBloodClothingType()
    if not clothingTypes or clothingTypes:size() == 0 then return false end

    local coveredParts = BloodClothingType.getCoveredParts(clothingTypes)
    if not coveredParts then return false end

    for i = 0, coveredParts:size() - 1 do
        if coveredParts:get(i) == BloodBodyPartType.Groin then
            return true
        end
    end

    return false
end

-- Decides whether one worn garment has to come off before relieving oneself.
function BF.IsExcreteObstructiveItem(item, location)
    if not item then return false end

    local override = BF.ExcreteObstructiveOverride[item:getFullType()]
    if override ~= nil then return override end

    if bfLocationInList(location, BF.GetExcreteObstructiveClothing()) then return true end

    local conditional = bfLocationInList(location, BF.GetExcreteConditionalClothing())
    local forms = bfNameForms(item)

    if bfMatchesAny(forms, BF.ExcreteObstructiveKeywords) then return true end
    if conditional and BF.RemoveAllLegwear then return true end
    if bfMatchesAny(forms, BF.ExcreteHarmlessKeywords) then return false end
    if conditional and BF.ItemCoversGroin(item) then return true end

    -- Unrecognised garment: strip it only when it sits in a legwear slot, so a
    -- modded item in some custom torso slot is left alone.
    return conditional
end

-- Worn garments that block relieving oneself, innermost layer first so that
-- re-equipping in list order dresses the character back up in the right order.
function BF.GetExcreteObstructiveWornItems(player)
    local inner, middle, outer = {}, {}, {}
    local wornItems = player:getWornItems()
    local seen = {}

    for i = 0, wornItems:size() - 1 do
        local entry = wornItems:get(i)
        local item = entry and entry:getItem()
        local location = entry and entry:getLocation()

        if item and not seen[item:getID()] and BF.IsExcreteObstructiveItem(item, location) then
            seen[item:getID()] = true

            local bucket = middle
            if location == ItemBodyLocation.UNDERWEAR or location == ItemBodyLocation.UNDERWEAR_BOTTOM then
                bucket = inner
            elseif bfLocationInList(location, BF.GetExcreteObstructiveClothing()) then
                bucket = outer
            end

            bucket[#bucket + 1] = item
        end
    end

    local ordered = {}
    for _, bucket in ipairs({inner, middle, outer}) do
        for _, item in ipairs(bucket) do
            ordered[#ordered + 1] = item
        end
    end

    return ordered
end