require('NPCs/MainCreationMethods');
local function initBathroomTraits()	

	-- Bladder Traits
	local smallBladder = TraitFactory.addTrait("SmallBladder", "Small Bladder", -1, "Bladder fills quicker and more urgently.", false)
	local bedwetter = TraitFactory.addTrait("Bedwetter", "Bedwetter", -3, "Involuntary urination while asleep", false)
	local urinaryIncontinence = TraitFactory.addTrait("UrinaryIncontinence", "Urinary Incontinence", -5, "Poor bladder control in general.", false)
	local paruresis = TraitFactory.addTrait("Paruresis", "Paruresis", -4, "Urination is difficult when near zombies or players.", false)
	local shyBladder = TraitFactory.addTrait("ShyBladder", "Shy Bladder", -6, "Urination is difficult without using the toilet.", false)

	local bigBladder = TraitFactory.addTrait("BigBladder", "Large Bladder", 1, "Bladder takes longer to fill.", false, false)
	local bladderControl = TraitFactory.addTrait("BladderControl", "Bladder Control", 3, "75% chance to stop urination 5% of the way through peeing self.", false)

	-- Bowel Traits
	local smallBowels = TraitFactory.addTrait("SmallBowels", "Small Bowels", -1, "Bowels fill quicker and more urgently.", false)
	local bedsoiler = TraitFactory.addTrait("Bedsoiler", "Bedpooper", -3, "Involuntary defecation while asleep", false)
	local fecalIncontinence = TraitFactory.addTrait("FecalIncontinence", "Fecal Incontinence", -6, "Poor bowel control in general.", false)
	local parcopresis = TraitFactory.addTrait("Parcopresis", "Parcopresis", -4, "Defecation is difficult when near zombies or players.", false)
	local shyBowels = TraitFactory.addTrait("ShyBowels", "Shy Bowels", -5, "Defecation is difficult without using the toilet.", false)

	local bigBowels = TraitFactory.addTrait("BigBowels", "Large Bowels", 1, "Bowels take longer to fill.", false)
	local bowelControl = TraitFactory.addTrait("BowelControl", "Bowel Control", 3, "75% chance to stop defecation 5% of the way through pooping self.", false)

	-- Mutual Exclusives

	-- Bladder-related
	TraitFactory.setMutualExclusive("SmallBladder", "BigBladder") -- Can't have a small and big bladder at once 
	TraitFactory.setMutualExclusive("UrinaryIncontinence", "BladderControl")  -- Can't be incontinent and have control

	-- Bowel-related
	TraitFactory.setMutualExclusive("SmallBowels", "BigBowels") -- Can't have a small and big bowels at once 
	TraitFactory.setMutualExclusive("FecalIncontinence", "BowelControl")  -- Can't be incontinent and have control


	--local strongBladder = TraitFactory.addTrait("StrongBladder", getText("Traits_StrongBladder"), 4, getText("Traits_StrongBladder_description"), false, false);
	--local weakBladder = TraitFactory.addTrait("WeakBladder", getText("Traits_WeakBladder"), -4, getText("Traits_WeakBladder_description"), false, false);
end


Events.OnGameBoot.Add(initBathroomTraits);