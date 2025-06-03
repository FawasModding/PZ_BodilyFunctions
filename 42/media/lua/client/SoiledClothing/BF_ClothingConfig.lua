BF_ClothingConfig = {}

BF_ClothingConfig = {
    soilableLocations = {"UnderwearBottom", "Underwear", "Torso1Legs1", "Legs1", "Pants", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume", "ShortPants", "ShortsShort", "Pants_Skinny"},
    clothingModels = {
        SuitTrousersMesh = {
            types = {"Trousers_Suit", "Trousers_SuitTEXTURE", "Trousers_SuitWhite", "Trousers_Scrubs", "Trousers", "Trousers_Jeans", "Trousers_Camo", "Trousers_Army", "Trousers_Denim", "Trousers_Crafted_Cotton", "TrousersMesh_DenimLight", "Trousers_Crafted_Burlap"},
            peeOverlay = "BathroomFunctions.SuitTrousersMesh_Peed",
            poopOverlay = "BathroomFunctions.SuitTrousersMesh_Pooped"
        },
        MaleUnderwear = {
            types = {"Boxers_White", "Male_Boxers_Pants_2", "Male_Boxers_Pants_3", "Boxers_Hearts", "Boxers_Silk_Black", "Boxers_Silk_Red", "Boxers_RedStripes", "Briefs_SmallTrunks_Black", "Briefs_SmallTrunks_Blue", "Briefs_SmallTrunks_Red", "Briefs_SmallTrunks_WhiteTINT", "Briefs_Garbage", "Briefs_Burlap", "Briefs_Denim", "Briefs_Hide", "Briefs_Rag", "Briefs_Tarp"},
            peeOverlay = "BathroomFunctions.Male_Underpants_Peed",
            poopOverlay = "BathroomFunctions.Male_Underpants_Pooped"
        },
        FemaleUnderwear = {
            types = {"Underpants_White", "Bikini_TINT", "Underpants_Black", "Underpants_RedSpots", "Underpants_AnimalPrint", "Underpants_Hide", "FrillyUnderpants_Black", "FrillyUnderpants_Pink", "FrillyUnderpants_Red", "Briefs_White", "Briefs_AnimalPrints", "SwimTrunks_Blue", "SwimTrunks_Green", "SwimTrunks_Red", "SwimTrunks_Yellow", "Shorts_ShortDenim", "Shorts_ShortFormal", "Shorts_BoxingRed", "Shorts_BoxingBlue", "Shorts_ShortSport", "Shorts_FootballPants", "Shorts_FootballPants_Black", "Shorts_FootballPants_Gold", "Shorts_FootballPants_White", "Shorts_HockeyPants", "Shorts_HockeyPants_Black", "Shorts_HockeyPants_Red", "Shorts_HockeyPants_UniBlue", "Shorts_HockeyPants_White"},
            peeOverlay = "BathroomFunctions.Female_Underpants_Peed",
            poopOverlay = "BathroomFunctions.Female_Underpants_Pooped"
        },
        LongShorts = {
            types = {"Shorts_LongDenim", "Shorts_LongDenim_Punk", "Shorts_LongSport", "Shorts_LongSport_Red"},
            peeOverlay = "BathroomFunctions.LongShorts_Peed",
            poopOverlay = "BathroomFunctions.LongShorts_Pooped"
        },
        BoxingShorts = {
            types = {},
            peeOverlay = "BathroomFunctions.BoxingShorts_Peed",
            poopOverlay = "BathroomFunctions.BoxingShorts_Pooped"
        }
    }
}