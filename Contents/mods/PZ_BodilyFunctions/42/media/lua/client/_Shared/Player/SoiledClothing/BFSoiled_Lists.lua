---@diagnostic disable: duplicate-set-field
BF_Soiling = BF_Soiling or {}

-- Check if player wearing any of specified clothing
function BF_Soiling.HasClothingOn(player, ...)
    
end

-- Function defining soilable clothing.
function BF_Soiling.GetSoilableClothing()
    local bodyLocations = {"UnderwearBottom", "Underwear", "Torso1Legs1", "Legs1", "Pants", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume", "ShortPants", "ShortsShort"}
    return bodyLocations
end

-- Clothes that need removed before using toilet. Includes dresses and skirts, which cannot be soiled (yet)
function BF_Soiling.GetExcreteObstructiveClothing()
    local bodyLocations = {
    "UnderwearBottom", "Underwear", "Torso1Legs1", "Legs1", "Pants", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume", "ShortPants", "ShortsShort",
    "LongDress", "Dress", "LongSkirt", "Skirt"
    }

    return bodyLocations
end