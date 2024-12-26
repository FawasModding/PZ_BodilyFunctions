require('NPCs/MainCreationMethods');
local function initBathroomTraits()	
	local strongBladder = TraitFactory.addTrait("StrongBladder", ("Steel Bladder"), 4, ("Bladder fills slower (Iron Gut fills bowels slower)."), false, false);
	local weakBladder = TraitFactory.addTrait("WeakBladder", ("Weak Bladder"), -4, ("Bladder fills faster (Weak Stomach fills bowels faster)"), false, false);
	--local strongBladder = TraitFactory.addTrait("StrongBladder", getText("Traits_StrongBladder"), 4, getText("Traits_StrongBladder_description"), false, false);
	--local weakBladder = TraitFactory.addTrait("WeakBladder", getText("Traits_WeakBladder"), -4, getText("Traits_WeakBladder_description"), false, false);
end


Events.OnGameBoot.Add(initBathroomTraits);