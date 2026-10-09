## 1.3.2

> [!question] 10/6/26
> - 

## 1.3.1

## 1.3.0

> [!question] 9/10/26
> Bug Fixes:
> - Since **B42.15** translation files must not carry the language code in the filename. `Translate/RU/` included `IG_UI_RU.json`, `Sandbox_RU.json`, etc., so the game looked for `RU/IG_UI.json` and failed.
> 	- This affects **RU, ES and PTBR**. RU was renamed + brought up to date.
> 	- TODO: ES needs the same rename; PTBR is still outdated and needs fixing.
> - Recipe prefix for Recipe localization was removed for similar reasons. Should be fixed.
> Bug Fixes:
- Fixed non-English translations failing to load due to incorrect filenames. Affects **RU, ES and PTBR**. RU has also been updated.
- Fixed recipe localization keys not being recognized.
- Fixed **PaperNapkins 2** being missing from the wipe configuration.
- Fixed washing failing to remove soiling at most levels.
- Fixed cleaning agents not being detected correctly.
- Fixed the run speed bonus stacking after repeated washes.
- Fixed stain overlays remaining after successful washing.
- Fixed cloth tools incorrectly bypassing the residual soiling penalty.
- Fixed removed clothing not being cleared after wiping.
- Fixed an issue with item tracking causing errors in some cases.

> Added:
- Washing machine support.
- Some multiplayer fixes (experimental).

> Multiplayer Fixes:
- Added multiplayer synchronization for bowel and bladder values.
- Added multiplayer item synchronization around wiping and washing, including container changes.
- Added item field synchronization after washing.
- Added server synchronization for client-side modData changes that were previously not being transmitted.

> **Multiplayer disclaimer:** These changes use the same vanilla synchronization methods used by the game, but **have not been tested on a multiplayer server**. They are intended to address reported issues such as bodily-function values reverting after using a toilet and wiped clothing becoming stuck until a server restart. Please report any remaining multiplayer desyncs or related issues.

