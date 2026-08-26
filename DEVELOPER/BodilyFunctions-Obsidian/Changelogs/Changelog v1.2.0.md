
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