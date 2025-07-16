BF_ReliefPoints = {}

-- =====================================================
-- 
-- BODILY FUNCTION: USABLE TILE LISTS
-- 
-- Includes toilets and alternatives for peeing, pooping, puking, etc.
-- 
-- =====================================================

-- Standard Toilets
function BF_ReliefPoints.GetToiletTiles()
    local toiletTiles = {
        "fixtures_bathroom_01_0", "fixtures_bathroom_01_1", "fixtures_bathroom_01_2", "fixtures_bathroom_01_3", 
        "fixtures_bathroom_01_4", "fixtures_bathroom_01_5", "fixtures_bathroom_01_6", "fixtures_bathroom_01_7",
        "location_entertainment_gallery_02_56" -- podium toilet for custom string lol
    }
    return toiletTiles
end

-- Urinals
function BF_ReliefPoints.GetUrinalTiles()
    local urinalTiles = {
        "fixtures_bathroom_01_8", "fixtures_bathroom_01_9", "fixtures_bathroom_01_10", "fixtures_bathroom_01_11"
    }
    return urinalTiles
end

-- Outhouses
function BF_ReliefPoints.GetOuthouseTiles()
    local outhouseTiles = {
        "fixtures_bathroom_02_24", "fixtures_bathroom_02_25", "fixtures_bathroom_02_26", "fixtures_bathroom_02_27",
        "fixtures_bathroom_02_4", "fixtures_bathroom_02_5", "fixtures_bathroom_02_14", "fixtures_bathroom_02_15"
    }
    return outhouseTiles
end

-- Showers
function BF_ReliefPoints.GetShowerTiles()
    local showerTiles = {
        "fixtures_bathroom_01_32", "fixtures_bathroom_01_33"
    }
    return showerTiles
end

-- Bathtubs
function BF_ReliefPoints.GetBathtubTiles()
    local bathtubTiles = {
        "fixtures_bathroom_01_24", "fixtures_bathroom_01_25", "fixtures_bathroom_01_26", "fixtures_bathroom_01_27",
        "fixtures_bathroom_01_55", "fixtures_bathroom_01_54", "fixtures_bathroom_01_53", "fixtures_bathroom_01_52"
    }
    return bathtubTiles
end

-- Bushes
function BF_ReliefPoints.GetBushTiles()
    local bushTiles = {
        "vegetation_ornamental_01_7", "vegetation_ornamental_01_6", "vegetation_ornamental_01_3", "vegetation_ornamental_01_2",
        "vegetation_ornamental_01_5", "vegetation_ornamental_01_4", "vegetation_ornamental_01_1", "vegetation_ornamental_01_0",
        "vegetation_ornamental_01_10", "vegetation_ornamental_01_11", "vegetation_ornamental_01_12", "vegetation_ornamental_01_13",
        "vegetation_ornamental_01_9", "vegetation_ornamental_01_8",

        "vegetation_foliage_01_0", "vegetation_foliage_01_3", "vegetation_foliage_01_2", "vegetation_foliage_01_1",
        "vegetation_foliage_01_4", "vegetation_foliage_01_5", "vegetation_foliage_01_8", "vegetation_foliage_01_9",
        "vegetation_foliage_01_10", "vegetation_foliage_01_11", "vegetation_foliage_01_12", "vegetation_foliage_01_13",
        "vegetation_foliage_01_14",

        "f_bushes_2_2", "f_bushes_2_1", "f_bushes_2_0", "f_bushes_2_3", "f_bushes_2_4", "f_bushes_2_5",
        "f_bushes_2_6", "f_bushes_2_7", "f_bushes_2_8", "f_bushes_2_9", "f_bushes_2_10", "f_bushes_2_11",
        "f_bushes_2_12", "f_bushes_2_13", "f_bushes_2_14", "f_bushes_2_15", "f_bushes_2_16", "f_bushes_2_17",
        "f_bushes_2_18", "f_bushes_2_19",
        
        "f_bushes_1_66", "f_bushes_1_64", "f_bushes_1_65", "f_bushes_1_72", "f_bushes_1_74", "f_bushes_1_73",
        "f_bushes_1_75", "f_bushes_1_77", "f_bushes_1_76", "f_bushes_1_78", "f_bushes_1_79", "f_bushes_1_71",
        "f_bushes_1_68", "f_bushes_1_67", "f_bushes_1_111", "f_bushes_1_110", "f_bushes_1_108", "f_bushes_1_109",
        "f_bushes_1_107", "f_bushes_1_106", "f_bushes_1_102", "f_bushes_1_103", "f_bushes_1_101", "f_bushes_1_100",
        "f_bushes_1_96", "f_bushes_1_97", "f_bushes_1_101", "f_bushes_1_98", "f_bushes_1_99", "f_bushes_1_104", "f_bushes_1_105"
    }
    return bushTiles
end

-- Dumpsters
function BF_ReliefPoints.GetDumpsterTiles()
    local dumpsterTiles = {
        "trashcontainers_01_10", "trashcontainers_01_11", "trashcontainers_01_8", "trashcontainers_01_9", "trashcontainers_01_12",
        "trashcontainers_01_13", "trashcontainers_01_14", "trashcontainers_01_15"
    }
    return dumpsterTiles
end

-- Sinks
function BF_ReliefPoints.GetSinkTiles()
    local sinkTiles = {
        "fixtures_sinks_01_30", "fixtures_sinks_01_31", "fixtures_sinks_01_29", "fixtures_sinks_01_28",
        "fixtures_sinks_01_12", "fixtures_sinks_01_13", "fixtures_sinks_01_10", "fixtures_sinks_01_11",
        "fixtures_sinks_01_8", "fixtures_sinks_01_14", "fixtures_sinks_01_15", "fixtures_sinks_01_18",
        "fixtures_sinks_01_32", "fixtures_sinks_01_33", "fixtures_sinks_01_35", "fixtures_sinks_01_34"
    }
    return sinkTiles
end

-- Trees
function BF_ReliefPoints.GetTreeTiles()
    local treeTiles = {
        "e_americanlinden_1_7", "e_americanlinden_1_7", "e_americanlinden_1_6", "e_americanlinden_1_3", "e_americanlinden_1_2",
        "e_yellowwood_1_7", "e_yellowwood_1_6", "e_yellowwood_1_3", "e_yellowwood_1_2", "e_easternredbud_1_3", "e_easternredbud_1_2",
        "e_easternredbud_1_7", "e_easternredbud_1_6", "e_redmaple_1_7", "e_redmaple_1_6", "e_redmaple_1_3", "e_redmaple_1_2",
        "e_canadianhemlock_1_5", "e_canadianhemlock_1_6", "e_canadianhemlock_1_7", "e_canadianhemlock_1_3", "e_canadianhemlock_1_2",
        "e_canadianhemlock_1_1", "e_carolinasilverbell_1_7", "e_carolinasilverbell_1_6", "e_carolinasilverbell_1_3", "e_carolinasilverbell_1_2",
        "e_dogwood_1_6", "e_dogwood_1_7", "e_cockspurhawthorn_1_2", "e_cockspurhawthorn_1_3", "e_cockspurhawthorn_1_6", "e_cockspurhawthorn_1_7",
        "e_dogwood_1_3", "e_dogwood_1_2", "e_riverbirch_1_3", "e_riverbirch_1_2", "e_riverbirch_1_7", "e_riverbirch_1_6", "e_virginiapine_1_5",
        "e_virginiapine_1_6", "e_virginiapine_1_7", "e_virginiapine_1_1", "e_virginiapine_1_2", "e_virginiapine_1_3", "e_americanholly_1_1",
        "e_americanholly_1_2", "e_americanholly_1_3", "e_americanholly_1_5", "e_americanholly_1_7", "e_americanholly_1_6"
    }
    return treeTiles
end

-- Trash Cans
function BF_ReliefPoints.GetTrashCanTiles()
    local trashCanTiles = {
        "trashcontainers_01_0", "trashcontainers_01_1", "trashcontainers_01_2", "trashcontainers_01_3",
        "trashcontainers_01_17", "trashcontainers_01_16", "trashcontainers_01_18", "trashcontainers_01_19",
        "trashcontainers_01_20", "trashcontainers_01_21", "location_restaurant_seahorse_01_39", "location_restaurant_seahorse_01_38",
        "location_shop_mall_01_44"
    }
    return trashCanTiles
end

-- Water Sources
function BF_ReliefPoints.GetWaterTiles()
    local waterTiles = {
        "blends_natural_02_7", "blends_natural_02_6", "blends_natural_02_5", "blends_natural_02_0"
    }
    return waterTiles
end

-- Open Windows
function BF_ReliefPoints.GetOpenWindowTiles()
    local openWindowTiles = {
        "fixtures_windows_01_34", "fixtures_windows_01_35", "fixtures_windows_01_26", "fixtures_windows_01_27",
        "fixtures_windows_01_11", "fixtures_windows_01_10", "fixtures_windows_01_18", "fixtures_windows_01_19",
        "fixtures_windows_01_3", "fixtures_windows_01_2", "location_barn_01_8", "location_barn_01_9"}
    return openWindowTiles
end

-- Holes (like graves)
function BF_ReliefPoints.GetHoleTiles()
    local holeTiles = {
        "location_community_cemetary_01_19", "location_community_cemetary_01_21", "location_community_cemetary_01_18", "location_community_cemetary_01_17",
        "location_community_cemetary_01_16", "location_community_cemetary_01_32", "location_community_cemetary_01_33", "location_community_cemetary_01_35",
        "location_community_cemetary_01_34", "location_community_cemetary_01_20"
    }
    return holeTiles
end

return BF_ReliefPoints