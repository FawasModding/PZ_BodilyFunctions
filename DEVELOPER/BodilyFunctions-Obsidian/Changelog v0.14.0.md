
> [!question] 8/24/26
> - Fixed pee overlay system (dev: Changed BodyLocations to BFBodyLocations).
> ---
> - Set "Umbrella" back up, and figured out how to add correct fields into the script files.
> - Organized [WipeSelf](jetbrains://rider/navigate/reference?project=42&path=42/media/lua/client/_Shared/Player/TimedActions/Wipe/WipeSelf.lua) to move chunks out of "perform"
> 	- Fixed (I think) the bug where using an item to wipe without a junk variant caused an error. Now it just doesn't add anything.
> - Changed "setDirtyness" to "setDirtiness" to update [WashSoiled](vscode://file/{code-root}/42/media/lua/client/_Shared/Player/TimedActions/Cleaning/WashSoiled.lua) from 42.13 to 42.14.
> 	- Fixes the errors when cleaning soiled clothing.
> - Removed FecalFootprints.lua in its entirely. Deprecated.
> ---
> - Readded mutual exclusivity to traits.
> - Changed points for "Bedwetter" from +3 to +2.
> - Changed points for "Urinary Incontience" from -5 to -4.
> ---
> - Added "ItemBodyLocation.PANTS_SKINNY" and "ItemBodyLocation.PANTS_EXTRA" to the list of clothing items that get taken off when you're about to use the bathroom.
> - Replaced my previous janky custom code for sitting down on toilets, with the built-in sitting mechanic introduced in Build 42. Toilets no longer clip with the player.
> ---
> - If wearing underwear, pants shares 80% of the peed severity when an accident occurs. If not wearing underwear, it gets full severity.
> - Resolved https://github.com/FawasModding/PZ_BodilyFunctions/issues/82

> [!SUCCESS] 8/23/26
> - Deleted Fecal Footprints system almost entirely.