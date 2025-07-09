-- =====================================================
--
-- GET CLOTHING LISTS
--
-- =====================================================

--[[
Function defining all of the soilable clothing.
]]--
function BF.GetSoilableClothing()
    local bodyLocations = {"UnderwearBottom", "Underwear", "Torso1Legs1", "Legs1", "Pants", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume", "ShortPants", "ShortsShort"}
    return bodyLocations
end

--[[
Clothes that need to be removed before using the bathroom. Includes dresses and skirts, which cannot be soiled (yet)
]]--
function BF.GetExcreteObstructiveClothing()
    local bodyLocations = {
    "UnderwearBottom", "Underwear", "Torso1Legs1", "Legs1", "Pants", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume", "ShortPants", "ShortsShort",
    "LongDress", "Dress", "LongSkirt", "Skirt"
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

-- =====================================================
--
-- GET TOILET / ALTERNATIVES LISTS
--
-- =====================================================

function BF.GetToiletTiles()
    local toiletTiles = {
    "fixtures_bathroom_01_0", "fixtures_bathroom_01_1", "fixtures_bathroom_01_2", "fixtures_bathroom_01_3", 
    "fixtures_bathroom_01_4", "fixtures_bathroom_01_5", "fixtures_bathroom_01_6", "fixtures_bathroom_01_7"}

    return toiletTiles
end

function BF.GetUrinalTiles()
    local urinalTiles = {
    "fixtures_bathroom_01_8", "fixtures_bathroom_01_9", "fixtures_bathroom_01_10", "fixtures_bathroom_01_11" }

    return urinalTiles
end

function BF.GetOuthouseTiles()
    local outhouseTiles = {
    "fixtures_bathroom_02_24", "fixtures_bathroom_02_25", "fixtures_bathroom_02_26", "fixtures_bathroom_02_27",
    "fixtures_bathroom_02_4", "fixtures_bathroom_02_5", "fixtures_bathroom_02_14", "fixtures_bathroom_02_15" }

    return outhouseTiles
end

function BF.GetShowerTiles()
    local showerTiles = {
    "fixtures_bathroom_01_24", "fixtures_bathroom_01_25", "fixtures_bathroom_01_26", "fixtures_bathroom_01_27",
    "fixtures_bathroom_01_32", "fixtures_bathroom_01_33", "fixtures_bathroom_01_52", "fixtures_bathroom_01_53",
    "fixtures_bathroom_01_54", "fixtures_bathroom_01_55"}

    return showerTiles
end