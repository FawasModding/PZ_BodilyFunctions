-- Hides Bodily Functions traits in character creation when their sandbox options
-- are off. The rules are in BF.IsTraitEnabled (shared/BF_Shared.lua).
require "OptionScreens/CharacterCreationProfession"

local originalIsTraitEnabled = CharacterCreationProfession.isTraitEnabled
function CharacterCreationProfession:isTraitEnabled(trait)
	if not BF.IsTraitEnabled(trait:getType()) then return false end
	return originalIsTraitEnabled(self, trait)
end

-- Vanilla fills the trait lists once, when this screen is created at the main
-- menu, which is before the player has chosen any sandbox settings. So the lists
-- are rebuilt each time the screen opens. Anything already selected that has since
-- been disabled is removed through removeTrait, which refunds its points.
local originalSetVisible = CharacterCreationProfession.setVisible
function CharacterCreationProfession:setVisible(visible, joypadData)
	originalSetVisible(self, visible, joypadData)
	if not visible or not self.listboxTraitSelected then return end

	local items = self.listboxTraitSelected.items
	for i = #items, 1, -1 do
		if not BF.IsTraitEnabled(items[i].item:getType()) then
			self:removeTrait(i)
		end
	end
	self:repopulateTraitLists()
end
