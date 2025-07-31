-- Generates the full nested overlay table for pee or poop overlays
-- baseName example: "BF.Trousers_Peed"
function generateOverlayStates(baseName, includeSat)
    local overlays = {
        fresh = {
            ["25"]  = baseName .. "_25",
            ["50"]  = baseName .. "_50",
            ["75"]  = baseName .. "_75",
            ["100"] = baseName .. "_100",
        },
        dried = {
            ["25"]  = baseName .. "_Dried_25",
            ["50"]  = baseName .. "_Dried_50",
            ["75"]  = baseName .. "_Dried_75",
            ["100"] = baseName .. "_Dried_100",
        }
    }
    if includeSat then
        overlays.fresh.sat = baseName .. "_Sat"
    end
    return overlays
end

BF_Overlays = {
    soilableLocations = {"UnderwearBottom", "Underwear", "Torso1Legs1", "Legs1", "Pants", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume", "ShortPants", "ShortsShort"},
    clothingModels = {
        Trousers = {
            types = {"Trousers_Black","Trousers_CamoDesert","Trousers_CamoDesertNew","Trousers_CamoGreen","Trousers_CamoMilius","Trousers_CamoTigerStripe","Trousers_CamoUrban","Trousers_Chef","Trousers_DeerHide","Trousers_Denim_Punk","Trousers_Denim","Trousers_FaunHide","Trousers_Fireman","Trousers_Hide","Trousers_HuntingCamo","Trousers_JeanBaggy_Punk","Trousers_JeanBaggy","Trousers_LeatherBlack","Trousers_LeatherCrafted","Trousers_NavyBlue","Trousers_OliveDrab","Trousers_Padded_HuntingCamo","Trousers_Padded","Trousers_Police","Trousers_PoliceGrey","Trousers_PrisonGuard","Trousers_Ranger","Trousers_Scrubs","Trousers_Shellsuit_Black", "Trousers_Shellsuit_Blue", "Trousers_Shellsuit_Green", "Trousers_Shellsuit_Pink", "Trousers_Shellsuit_Teal", "Trousers_Shellsuit_White", "Trousers_Sheriff", "Trousers_Sport", "Trousers_WhiteTINT", "Trousers", "TrousersMesh_DenimLight", "TrousersMesh_Leather"}, 

            overlays = {
                pee = generateOverlayStates("BF.Trousers_Peed", true),
                poop = generateOverlayStates("BF.Trousers_Pooped", false),
            }
        }
        },
        SuitTrousersMesh = {
            types = {"Trousers_Suit", "Trousers_SuitTEXTURE", "Trousers_SuitWhite", "Trousers_Jeans", "Trousers_Camo", "Trousers_Army", "Trousers_Crafted_Cotton", "Trousers_Crafted_Burlap"},

            overlays = {
                pee = generateOverlayStates("BF.SuitTrousersMesh_Peed", true),
                poop = generateOverlayStates("BF.SuitTrousersMesh_Pooped", false),
            }
        },
        MaleUnderwear = {
            types = {"Boxers_White", "Male_Boxers_Pants_2", "Male_Boxers_Pants_3", "Boxers_Hearts", "Boxers_Silk_Black", "Boxers_Silk_Red", "Boxers_RedStripes", "Briefs_SmallTrunks_Black", "Briefs_SmallTrunks_Blue", "Briefs_SmallTrunks_Red", "Briefs_SmallTrunks_WhiteTINT", "Briefs_Garbage", "Briefs_Burlap", "Briefs_Denim", "Briefs_Hide", "Briefs_Rag", "Briefs_Tarp", "Briefs_White", "Briefs_AnimalPrints"},

            overlays = {
                pee = generateOverlayStates("BF.Male_Boxers_Peed", true),
                poop = generateOverlayStates("BF.Male_Boxers_Pooped", false),
            }
        },
        FemaleUnderwear = {
            types = {"Underpants_White", "Bikini_TINT", "Underpants_Black", "Underpants_RedSpots", "Underpants_AnimalPrint", "Underpants_Hide", "FrillyUnderpants_Black", "FrillyUnderpants_Pink", "FrillyUnderpants_Red", "SwimTrunks_Blue", "SwimTrunks_Green", "SwimTrunks_Red", "SwimTrunks_Yellow", "Shorts_HockeyPants", "Shorts_HockeyPants_Black", "Shorts_HockeyPants_Red", "Shorts_HockeyPants_UniBlue", "Shorts_HockeyPants_White", "Shorts_FootballPants", "Shorts_FootballPants_Black", "Shorts_FootballPants_Gold", "Shorts_FootballPants_White"},

            overlays = {
                pee = generateOverlayStates("BF.Female_Underpants_Peed", true),
                poop = generateOverlayStates("BF.Female_Underpants_Pooped", false),
            }
        },
        LongShorts = {
            types = {"Shorts_LongDenim", "Shorts_LongDenim_Punk", "Shorts_LongSport", "Shorts_LongSport_Red", "Shorts_CamoGreenLong", "Shorts_CamoUrbanLong", "Shorts_OliveDrabLong", "Shorts_CamoDesertNewLong", "Shorts_CamoMiliusLong", "item Shorts_CamoTigerStripeLong"},

            overlays = {
                pee = generateOverlayStates("BF.LongShorts_Peed", true),
                poop = generateOverlayStates("BF.LongShorts_Pooped", false),
            }
        },
        BoxingShorts = {
            types = {"Shorts_BoxingRed", "Shorts_BoxingBlue"},

            overlays = {
                pee = generateOverlayStates("BF.BoxingShorts_Peed", true),
                poop = generateOverlayStates("BF.BoxingShorts_Pooped", false),
            }
        },
        ShortShorts = {
            types = {"Shorts_ShortDenim", "Shorts_ShortFormal", "Shorts_ShortSport"},

            overlays = {
                pee = generateOverlayStates("BF.ShortShorts_Peed", true),
                poop = generateOverlayStates("BF.ShortShorts_Pooped", false),
            }
        }
    }
}

-- ================================================================================== --
-- ========================= FOR ADDON MODDERS ====================================== --
-- ================================================================================== --

-- Registers a new clothing category with soil overlays (pee/poop) in the BF_Overlays table.
-- @param name: The name/key of the clothing category (ex "Trousers", "UtilitySuitSTF").
-- @param data: A table containing 'types', 'peeOverlay', and 'poopOverlay'.
function BF_RegisterClothingCategory(name, data)
    if not BF_Overlays then return end
    if not BF_Overlays.clothingModels then
        BF_Overlays.clothingModels = {}
    end

    -- Avoid overwriting existing category
    if BF_Overlays.clothingModels[name] then
        print("BF_RegisterClothingCategory: '" .. name .. "' already exists. Skipping.")
        return
    end

    BF_Overlays.clothingModels[name] = data
    print("BF_RegisterClothingCategory: Registered category '" .. name .. "'")
end

-- EXAMPLE
-- Events.OnInitGlobalModData.Add(function()
--     if BF_RegisterClothingCategory then
--         BF_RegisterClothingCategory("UtilitySuitSTF", {
--             types = { "Utility_Suit_STF" },
--             peeOverlay = "STF.Utility_Suit_STF_Peed",
--             poopOverlay = "STF.Utility_Suit_STF_Pooped"
--         })
--     end
-- end)


-- Adds a new body location string to the list of soilable clothing locations.
-- This is used to determine which body location slots can receive pee/poop overlays.
-- @param location: A string body location name (ex. "Pants", "UnderwearBottom").
function BF_AddSoilableLocation(location)
    if not BF_Overlays then return end
    if not BF_Overlays.soilableLocations then
        BF_Overlays.soilableLocations = {}
    end

    -- Prevent duplicates
    for _, loc in ipairs(BF_Overlays.soilableLocations) do
        if loc == location then return end
    end

    table.insert(BF_Overlays.soilableLocations, location)
    print("BF_AddSoilableLocation: Added '" .. location .. "'")
end

-- Adds one or more clothing item type strings to an existing category.
-- Prevents duplicates and ensures the category exists before adding.
-- @param category: The clothing category name to modify.
-- @param newTypes: A list of string item type names to add (ex. "Trousers_Chef").
function BF_AddClothingTypesToCategory(category, newTypes)
    if not BF_Overlays or not BF_Overlays.clothingModels then return end
    local model = BF_Overlays.clothingModels[category]
    if not model or not model.types then return end

    for _, newType in ipairs(newTypes) do

        -- Check if this type already exists in the category
        local exists = false
        for _, existingType in ipairs(model.types) do
            if existingType == newType then
                exists = true
                break
            end
        end

        -- Only add if not already present
        if not exists then
            table.insert(model.types, newType)
            print("BF_AddClothingTypesToCategory: Added type '" .. newType .. "' to '" .. category .. "'")
        end
    end
end