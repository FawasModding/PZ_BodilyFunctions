-- Have multiple per. e.g. toilet paper
function BF.GetDrainableWipeables()
    local wipeItems = {
    "ToiletPaper" }

    return wipeItems
end
-- Can only be used once. So paper, to poop you'll need 4 individual Paper items
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
-- Sets the peed and pooped values to the ones that happen when you actually pee / poop, only soft / realistic materials can be included here.
function BF.GetClothingWipeables()
    local wipeItems = { -- Bras and underwear bottoms are soft, therefore they'd be useable.
    "UnderwearBottom", "UnderwearTop" }

    return wipeItems
end