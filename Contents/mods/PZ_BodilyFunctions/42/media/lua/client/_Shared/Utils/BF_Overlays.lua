BF_Overlays = {
    soilableLocations = {
        "UnderwearBottom", "Underwear", "Torso1Legs1", "Legs1", "Pants",
        "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume",
        "ShortPants", "ShortsShort"
    },

    clothingModels = {
        Trousers = {
            types = {
                "Trousers_Black","Trousers_CamoDesert","Trousers_CamoDesertNew",
                "Trousers_CamoGreen","Trousers_CamoMilius","Trousers_CamoTigerStripe",
                "Trousers_CamoUrban","Trousers_Chef","Trousers_DeerHide",
                "Trousers_Denim_Punk","Trousers_Denim","Trousers_FaunHide",
                "Trousers_Fireman","Trousers_Hide","Trousers_HuntingCamo",
                "Trousers_JeanBaggy_Punk","Trousers_JeanBaggy","Trousers_LeatherBlack",
                "Trousers_LeatherCrafted","Trousers_NavyBlue","Trousers_OliveDrab",
                "Trousers_Padded_HuntingCamo","Trousers_Padded","Trousers_Police",
                "Trousers_PoliceGrey","Trousers_PrisonGuard","Trousers_Ranger",
                "Trousers_Scrubs","Trousers_Shellsuit_Black","Trousers_Shellsuit_Blue",
                "Trousers_Shellsuit_Green","Trousers_Shellsuit_Pink",
                "Trousers_Shellsuit_Teal","Trousers_Shellsuit_White","Trousers_Sheriff",
                "Trousers_Sport","Trousers_WhiteTINT","Trousers",
                "TrousersMesh_DenimLight","TrousersMesh_Leather"
            },
            overlays = { pee = true, poop = true }
        },

        SuitTrousersMesh = {
            types = {
                "Trousers_Suit","Trousers_SuitTEXTURE","Trousers_SuitWhite",
                "Trousers_Jeans","Trousers_Camo","Trousers_Army",
                "Trousers_Crafted_Cotton","Trousers_Crafted_Burlap"
            },
            overlays = { pee = true, poop = true }
        },

        MaleUnderwear = {
            types = {
                "Boxers_White","Male_Boxers_Pants_2","Male_Boxers_Pants_3",
                "Boxers_Hearts","Boxers_Silk_Black","Boxers_Silk_Red",
                "Boxers_RedStripes","Briefs_SmallTrunks_Black",
                "Briefs_SmallTrunks_Blue","Briefs_SmallTrunks_Red",
                "Briefs_SmallTrunks_WhiteTINT","Briefs_Garbage","Briefs_Burlap",
                "Briefs_Denim","Briefs_Hide","Briefs_Rag","Briefs_Tarp",
                "Briefs_White","Briefs_AnimalPrints"
            },
            overlays = { pee = true, poop = true }
        },

        FemaleUnderwear = {
            types = {
                "Underpants_White","Bikini_TINT","Underpants_Black","Underpants_RedSpots",
                "Underpants_AnimalPrint","Underpants_Hide","FrillyUnderpants_Black",
                "FrillyUnderpants_Pink","FrillyUnderpants_Red","SwimTrunks_Blue",
                "SwimTrunks_Green","SwimTrunks_Red","SwimTrunks_Yellow",
                "Shorts_HockeyPants","Shorts_HockeyPants_Black","Shorts_HockeyPants_Red",
                "Shorts_HockeyPants_UniBlue","Shorts_HockeyPants_White",
                "Shorts_FootballPants","Shorts_FootballPants_Black",
                "Shorts_FootballPants_Gold","Shorts_FootballPants_White"
            },
            overlays = { pee = true, poop = true }
        },

        LongShorts = {
            types = {
                "Shorts_LongDenim","Shorts_LongDenim_Punk","Shorts_LongSport",
                "Shorts_LongSport_Red","Shorts_CamoGreenLong","Shorts_CamoUrbanLong",
                "Shorts_OliveDrabLong","Shorts_CamoDesertNewLong","Shorts_CamoMiliusLong",
                "Shorts_CamoTigerStripeLong"
            },
            overlays = { pee = true, poop = true }
        },

        BoxingShorts = {
            types = { "Shorts_BoxingRed", "Shorts_BoxingBlue" },
            overlays = { pee = true, poop = true }
        },

        ShortShorts = {
            types = { "Shorts_ShortDenim", "Shorts_ShortFormal", "Shorts_ShortSport" },
            overlays = { pee = true, poop = true }
        }
    }
}

-- ================================================================================== --
-- ========================= FOR ADDON MODDERS ====================================== --
-- ================================================================================== --

-- Register a new clothing category with soil overlays
function BF_RegisterClothingCategory(name, data)
    if not BF_Overlays then return end
    if not BF_Overlays.clothingModels then
        BF_Overlays.clothingModels = {}
    end
    if BF_Overlays.clothingModels[name] then
        print("BF_RegisterClothingCategory: '" .. name .. "' already exists. Skipping.")
        return
    end

    BF_Overlays.clothingModels[name] = {
        types = data.types or {},
        overlays = {
            pee = data.pee or false,
            poop = data.poop or false
        }
    }
    print("BF_RegisterClothingCategory: Registered category '" .. name .. "'")
end

-- Add new body location
function BF_AddSoilableLocation(location)
    if not BF_Overlays or not BF_Overlays.soilableLocations then return end
    for _, loc in ipairs(BF_Overlays.soilableLocations) do
        if loc == location then return end
    end
    table.insert(BF_Overlays.soilableLocations, location)
    print("BF_AddSoilableLocation: Added '" .. location .. "'")
end

-- Add clothing item types to an existing category
function BF_AddClothingTypesToCategory(category, newTypes)
    if not BF_Overlays or not BF_Overlays.clothingModels then return end
    local model = BF_Overlays.clothingModels[category]
    if not model or not model.types then return end

    for _, newType in ipairs(newTypes) do
        local exists = false
        for _, existingType in ipairs(model.types) do
            if existingType == newType then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(model.types, newType)
            print("BF_AddClothingTypesToCategory: Added type '" .. newType .. "' to '" .. category .. "'")
        end
    end
end
