
## 1.2.0
> [!question] 8/26/26
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
> 	    use the actual label positions saved when the labels are created.