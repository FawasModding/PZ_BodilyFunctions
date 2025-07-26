require('NPCs/MainCreationMethods');
local function initBathroomTraits()	

	-- Bladder Traits
    TraitFactory.addTrait("SmallBladder", getText("UI_trait_SmallBladder"), -1, getText("UI_trait_SmallBladderDesc"), false)
    TraitFactory.addTrait("Bedwetter", getText("UI_trait_Bedwetter"), -3, getText("UI_trait_BedwetterDesc"), false)
    TraitFactory.addTrait("UrinaryIncontinence", getText("UI_trait_UrinaryIncontinence"), -5, getText("UI_trait_UrinaryIncontinenceDesc"), false)
    TraitFactory.addTrait("Paruresis", getText("UI_trait_Paruresis"), -4, getText("UI_trait_ParuresisDesc"), false)
    TraitFactory.addTrait("ShyBladder", getText("UI_trait_ShyBladder"), -6, getText("UI_trait_ShyBladderDesc"), false)
    TraitFactory.addTrait("BigBladder", getText("UI_trait_BigBladder"), 1, getText("UI_trait_BigBladderDesc"), false)
    TraitFactory.addTrait("BladderControl", getText("UI_trait_BladderControl"), 3, getText("UI_trait_BladderControlDesc"), false)

    -- Bowel Traits
    TraitFactory.addTrait("SmallBowels", getText("UI_trait_SmallBowels"), -1, getText("UI_trait_SmallBowelsDesc"), false)
    TraitFactory.addTrait("Bedsoiler", getText("UI_trait_Bedsoiler"), -3, getText("UI_trait_BedsoilerDesc"), false)
    TraitFactory.addTrait("FecalIncontinence", getText("UI_trait_FecalIncontinence"), -6, getText("UI_trait_FecalIncontinenceDesc"), false)
    TraitFactory.addTrait("Parcopresis", getText("UI_trait_Parcopresis"), -4, getText("UI_trait_ParcopresisDesc"), false)
    TraitFactory.addTrait("ShyBowels", getText("UI_trait_ShyBowels"), -5, getText("UI_trait_ShyBowelsDesc"), false)
    TraitFactory.addTrait("BigBowels", getText("UI_trait_BigBowels"), 1, getText("UI_trait_BigBowelsDesc"), false)
    TraitFactory.addTrait("BowelControl", getText("UI_trait_BowelControl"), 3, getText("UI_trait_BowelControlDesc"), false)

    -- Mutual Exclusives
    TraitFactory.setMutualExclusive("SmallBladder", "BigBladder")
    TraitFactory.setMutualExclusive("UrinaryIncontinence", "BladderControl")
    TraitFactory.setMutualExclusive("SmallBowels", "BigBowels")
    TraitFactory.setMutualExclusive("FecalIncontinence", "BowelControl")


	--local strongBladder = TraitFactory.addTrait("StrongBladder", getText("Traits_StrongBladder"), 4, getText("Traits_StrongBladder_description"), false, false);
	--local weakBladder = TraitFactory.addTrait("WeakBladder", getText("Traits_WeakBladder"), -4, getText("Traits_WeakBladder_description"), false, false);
end


Events.OnGameBoot.Add(initBathroomTraits);