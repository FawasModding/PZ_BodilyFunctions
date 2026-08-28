
## 1.2.0
> [!question] 8/27/26
> - Removed unused custom sandbox menu code. May revisit this eventually.
> - Added "Paper Scraps" and "Cloth Scraps" to translation file.
> - Renamed "Sheet of Paper (Wiped)" to "Paper Scrap (Wiped)" since it's used more broadly now.
> - Changed "WIP" to "Placeholder Setting" for Sandbox settings; More clarity.
> - Added "Trousers_DefaultTEXTURE_TINT" to Trousers peed overlay.
> - Fixed Fumes Moodle Sticking: `DirtyBottomsEffects` now requires a 30% total stain threshold (summed across all worn garments) before triggering.
> - Added Reset: Below 30%, `BF.SetBodilyFumesValue(0)` is called to prevent the moodle from remaining permanently attached.
> ---
> - Wiping Overhaul:
> 	- Female characters can now wipe when peeing. Similar consequence as pooping, but 3% clothing severity (which is the term for soiled-ness) instead of 5% (for pooping).
> 	- Much larger material list.
> 		- Expanded wipeable items (adding ~45 general items and ~108 books). Skill books are now automatically excluded via category checks rather than hardcoded list
> 		- Each `oneTimeWipeables` entry now carries a `category`:
> 			- `"paper_single"` --- newspapers, magazines, comics. One item = a full wipe.  
> 			    Each type gets **its own menu entry**.
> 			- `"paper"` --- medium sheets (`usesRequired = 2`) and small scraps  
> 			    (`usesRequired = 4`). These are **pooled into one "Paper scraps" entry**.
> 			- `"grass"` --- `GrassTuft`, `usesRequired = 3`, plus `maxEfficiency = 0.75` so grass  
> 			    can never produce a fully clean wipe no matter how much you have.
> 			- `clothToolWipeables` is a separate table for dishcloth / bath towel / ripped sheets, each shown individually.
> 			-`bookWipeables` --- one book = a full wipe, consumes the book, returns 10 clean `Base.SheetPaper2` plus a few dirty scraps (torn-out pages).
> 	- Multiple menu wipe options instead of the first one found.
> 	- The pooled "Paper scraps" entry mixes tiers correctly by weight: each item contributes `1 / usesRequired`, so 2 medium sheets, 4 small scraps, or 1 sheet + 2 scraps all add up to a full wipe.
> 	- Junk is created only when defecating. Urination creates no scrap. For cloth tools, urination instead converts the tool into its wet/dirty vanilla counterpart (Dish Towel = Wet; Bath Towel = Wet; Ripped Sheets = Dirty).
> ---
> - Washing Overhaul:
> 	- All soiled garments are listed, not just the last one.
> 	- Soap is found via `BF.FindReachableItem` (bags + nearby tiles), not just the main inventory.
> 	- `BF.IsSoiledJunk(item)` dictates what's washable. Only `RippedSheetsPooped` shows in the menu for now. Soiled paper is disposable (though thicker ones like paper towels may become reusable with penalties in the future) and grass isn't worth washing.
> 	- `WashSoiledItem.lua` Bug Fixed: The clean item had the incorrect "BF" prefix rather than "Base", leading to its removal from the inventory. Now gives correct Ripped Sheets item.
> 	- Clothes now re-equip after being washed, if worn when washing.
> ---
> - Non-Toilet Usage:
> 	- Water, sinks, etc. Use "FixtureUrinate" and "FixtureDefecate" (partly implemented in the last update.)
> 	- Player walks to the object and then crouches down (if female) or stands (if male), as if using the ground.
> 	- TODO: Players should stand when in the shower or when using sinks, male or female. This'll be fixed later.
> ---
> - Reachable-Item Scanning:
> 	- For wipe-able items, and soap, the game can now detect them within 1 tile of the player as well as in backpacks / other storage slots. For example, if toilet paper is next to the toilet, it uses it without you needing to pick it up.
> ---
> - Clothing Recognition (Including Mod Compatibility)
> 	- The system for detecting clothes to take off when using the bathroom, or soilable, is now more advanced and works better with other mods. An example is "tights vs. stockings". It can detect what's covering the groin (actually in the way), and what's not. Garters and harnesses stay on, leotards on a custom slot come off, a bolero on a neighboring custom slot doesn't.

> [!success] 8/26/26
> - Added "Medical = true" and "CantBeFrozen = true" to pill and pill box items.
> - Fixed tags being broken for BF_SoiledWipes items.
> - Fixed `BF_BoxingShorts_Peed.txt` missing a comma after the `Tags` line.
> - Fixed BodyLocation for a test clothing item.
> ---
> - `BF_Fluids.txt`: hard crash fixed; Removed `Poison` for Snot and Sweat:
> 	- `HumanSnot` and `HumanSweat` had  
`Poison { maxEffect = Low ... }`. There is no `PoisonEffect.Low` constant in  
B42.19, and `FluidDefinitionScript.LoadPoison` threw  
`IllegalArgumentException: No enum constant ...PoisonEffect.Low`, which could abort  
script loading before the main menu. 
> - In some scripts: `TRUE` -> `true` (`IsCookable`, `UseSelf`, `CanBePlaced`, `CanBeReused`, `Medical`,  
`CantBeFrozen`)
> ---
> - Item Distribution: Fixed potential for bugs in `ProceduralDistributions` container lookup by ensuring they exist before referencing them. Also reduced the amount of lines drastically.
> ---
> - Excretion GUI Safety/Improvements:
> 	- `AddCharacterPageTab` could be `nil` at `BF_CharacterInfo_GUIHandler.lua:203`  
> 	    (`Object tried to call nil`) when TchernoLib was present but its  
> 	    `UI/CharacterInfoAddTab` didn't define the global. The require is now wrapped in  
> 	    `pcall` and the result verified with `type(AddCharacterPageTab) == "function"`  
> 	    before deciding whether to define the fallback; the call site is guarded too.
> 	- `FONT_HGT_SMALL` was computed at module load via `getTextManager()`; it's now  
> 	    resolved lazily on first `createChildren`.
> 	- `y` is a module-level local that accumulated between `createChildren` calls; it's  
> 	    reset at the top of each pass.
> 	- Icon X/Y were derived from `getText("Bladder Fullness")` which was not a real key, so the  
> 	    measured width was wrong and icons drifted, badly in non-English locales. They now  
> 		use the actual label positions saved when the labels are created.
> ---
> - Fixed two issues (trailing comma and odd character) in Recipes & Moodles EN locale files.