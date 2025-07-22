-- =====================================================
--
-- GET CLOTHING LISTS
--
-- =====================================================

--[[
Function defining all of the soilable clothing.
]]--
function BF.GetSoilableClothing()
    local bodyLocations = {"UnderwearBottom", "Underwear", "Torso1Legs1", "Legs1", "Pants", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume", "ShortPants", "ShortsShort", "Pants_Skinny"}
    return bodyLocations
end

--[[
Clothes that need to be removed before using the bathroom. Includes dresses and skirts, which cannot be soiled (yet)
]]--
function BF.GetExcreteObstructiveClothing()
    local bodyLocations = {
    "UnderwearBottom", "Underwear", "Torso1Legs1", "Legs1", "Pants", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume", "ShortPants", "ShortsShort",
    "LongDress", "Dress", "LongSkirt", "Skirt", "Pants_Skinny"
    }

    return bodyLocations
end

-- =====================================================
--
-- GET WIPING LISTS
--
-- =====================================================

--[[
Items (usually paper variants) that can be used to wipe either for peeing (females only) or for defecation.
]]--

-- These ones are things that have multiple per, like toilet paper
function BF.GetDrainableWipeables()
    local wipeItems = {
    "ToiletPaper" }

    return wipeItems
end
-- These ones are things that can only be used once. So paper, to poop you'll need 4 individual Paper items
function BF.GetOneTimeWipeables()
    local wipeItems = {
    "Tissue", "PaperNapkins2", "GraphPaper", "Paperwork",
    "SheetPaper2", "Receipt", "RippedSheets",
    "Newspaper_Old", "Newspaper_Recent", "Newspaper_New", "Newspaper_Dispatch_New", "Newspaper_Herald_New", "Newspaper_Knews_New", "Newspaper_Times_New",
    "TVMagazine", "Magazine_Art", "Magazine_Business", "Magazine_Car", "Magazine_Childs", "Magazine_Cinema", "Magazine_Crime",
    "Magazine_Fashion", "Magazine_Firearm", "Magazine_Gaming", "Magazine_Golf", "Magazine_Health", "Magazine_Hobby", "Magazine_Horror", "Magazine_Humor", "Magazine_Military",
    "Magazine_Music", "Magazine_Outdoors", "Magazine_Police", "Magazine_Popular", "Magazine_Rich", "Magazine_Science", "Magazine_Sports", "Magazine_Tech", "Magazine_Teens",
    "HottieZ_New", "HottieZ", "HunkZ"}

    return wipeItems
end
-- These ones are clothing. Sets the peed and pooped values to the ones that happen when you actually pee / poop, only soft / realistic materials can be included here.
function BF.GetClothingWipeables()
    local wipeItems = { -- Bras and underwear bottoms are soft, therefore they'd be useable.
    "UnderwearBottom", "UnderwearTop" }

    return wipeItems
end