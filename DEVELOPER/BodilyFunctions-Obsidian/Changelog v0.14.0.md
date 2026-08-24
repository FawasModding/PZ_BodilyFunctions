
> [!SUCCESS] 8/24/26
> - Set "Umbrella" back up, and figured out how to add correct fields into the script files.
> - Organized [WipeSelf](jetbrains://rider/navigate/reference?project=42&path=42/media/lua/client/_Shared/Player/TimedActions/Wipe/WipeSelf.lua) to move chunks out of "perform"
> 	- Fixed (I think) the bug where using an item to wipe without a junk variant caused an error. Now it just doesn't add anything.
> - Changed "setDirtyness" to "setDirtiness" to update [WashSoiled](vscode://file/{code-root}/42/media/lua/client/_Shared/Player/TimedActions/Cleaning/WashSoiled.lua) from 42.13 to 42.14.
> 	- Fixes the errors when cleaning soiled clothing.
> - Removed FecalFootprints.lua in its entirely. Deprecated.