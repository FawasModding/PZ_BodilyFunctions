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
        "fixtures_bathroom_01_4", "fixtures_bathroom_01_5", "fixtures_bathroom_01_6", "fixtures_bathroom_01_7"
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
        "fixtures_bathroom_01_24", "fixtures_bathroom_01_25", "fixtures_bathroom_01_26", "fixtures_bathroom_01_27",
        "fixtures_bathroom_01_32", "fixtures_bathroom_01_33", "fixtures_bathroom_01_52", "fixtures_bathroom_01_53",
        "fixtures_bathroom_01_54", "fixtures_bathroom_01_55"
    }
    return showerTiles
end

-- Bathtubs
function BF_ReliefPoints.GetBathtubTiles()
    local bathtubTiles = {}
    return bathtubTiles
end

-- Bushes
function BF_ReliefPoints.GetBushTiles()
    local bushTiles = {}
    return bushTiles
end

-- Dumpsters
function BF_ReliefPoints.GetDumpsterTiles()
    local dumpsterTiles = {}
    return dumpsterTiles
end

-- Sinks
function BF_ReliefPoints.GetSinkTiles()
    local sinkTiles = {}
    return sinkTiles
end

-- Trees
function BF_ReliefPoints.GetTreeTiles()
    local treeTiles = {}
    return treeTiles
end

-- Trash Cans
function BF_ReliefPoints.GetTrashCanTiles()
    local trashCanTiles = {}
    return trashCanTiles
end

-- Water Sources
function BF_ReliefPoints.GetWaterTiles()
    local waterTiles = {}
    return waterTiles
end

-- Open Windows
function BF_ReliefPoints.GetOpenWindowTiles()
    local openWindowTiles = {}
    return openWindowTiles
end

return BF_ReliefPoints