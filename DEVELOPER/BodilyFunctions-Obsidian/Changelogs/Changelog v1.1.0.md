
## 1.1.0
> [!success] 8/25/26
> - Pee option for sinks is now nested within the sink context menu option, like toilets.
> - Wash Soiled Items / Clothing option is now nested within the sink context menu option.
> - Non-toilet things like sinks, bushes, water, etc. are now fully useable (for peeing, not pooping yet. Soon though).
> 	- (!) This was due to them using the same functionality as toilets, and, the game couldn't "sit down on" a sink, or move the player into the sink tile. Now that it's separate, I can have more unique functionality per object.

## 1.0.1
> [!success] 8/25/26
> - Replaced instances of old logo with new.
> - Fixed "Spanish" and "Russian" translations to fit the new Build 42 translation format.
> - Fixed debug menu WARNING spam on right click by changing string handling for relief actions. Example:
> 	- OLD: BF.AddTooltip(urinalPeeOption, string.format(getText("ContextMenu_tooltip_PeeUrinal"), peeInToiletRequirement))
> 	- NEW: BF.AddTooltip(urinalPeeOption, getText("ContextMenu_tooltip_PeeUrinal", tostring(peeInToiletRequirement)))
> - Attempted to fix "https://github.com/FawasModding/PZ_BodilyFunctions/issues/87" by changing the way strings are formed in the Excretion menu. May not have fixed it.