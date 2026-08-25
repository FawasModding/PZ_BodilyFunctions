
## 1.0.1
> [!success] 8/25/26
> - Replaced instances of old logo with new.
> - Fixed "Spanish" and "Russian" translations to fit the new Build 42 translation format.
> - Fixed debug menu WARNING spam on right click by changing string handling for relief actions. Example:
> 	- OLD: BF.AddTooltip(urinalPeeOption, string.format(getText("ContextMenu_tooltip_PeeUrinal"), peeInToiletRequirement))
> 	- NEW: BF.AddTooltip(urinalPeeOption, getText("ContextMenu_tooltip_PeeUrinal", tostring(peeInToiletRequirement)))
> - Attempted to fix "https://github.com/FawasModding/PZ_BodilyFunctions/issues/87" by changing the way strings are formed in the Excretion menu. May not have fixed it.