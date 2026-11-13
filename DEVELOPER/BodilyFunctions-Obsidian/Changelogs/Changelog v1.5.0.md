## 1.5.0

> [!question] 11/11/26
> Urges (hiccups):
> - Rewrote `BF.HandleUrgencyHiccup`. All the numbers for it are in the `BF.Urge` table in `BodilyFunctions.lua`.
> 	- The bladder and bowels each check for an urge every 10 minutes.
> 	- No urge below 60% full (bladder) or 65% (bowels). Above that, the chance goes from 4% up to 30% at overflow, with a max of 60%.
> 	- Panic, stress, alcohol, and diarrhea increase the urge chance. Alcohol affects the bladder more than the bowels.
> 	- Alcohol is read from `MoodleType.DRUNK`.
> 	- After an urge, that organ can't have another one for 2 ticks (bladder) or 3 ticks (bowels). Stored in `modData.bfUrgeCooldown`.
> 	- If both roll an urge in the same tick, only the one that's fuller happens.
> 	- An urge can only cause an accident for the organ that had it. Before, a bladder urge could possibly also cause a poop accident and the other way around.
> 	- No accident chance below 75% full (bladder) or 80% (bowels), except from panic. Above that, the chance goes from 3% up to 30%.
> 	- Alcohol, panic, low endurance, sprinting, and running increase the accident chance. Sitting on the ground lowers it.
> 	- Diarrhea lowers both bowel thresholds, by up to 24% at its worst.
> 	- Incontinence lowers the thresholds to 35% and 45% and multiplies the accident chance by 2.5. It no longer causes a full accident on every urge.
> 	- Bladder/Bowel Control halves the accident chance and keeps the 75% chance of only leaking.
> 	- Without a Control trait, an accident has up to a 70% chance to be a leak when barely past the threshold, going down to 0% at overflow.
> 	- No urges while asleep, or while peeing, pooping, wiping, or getting dressed.
> 	- The hold animation only plays if nothing is queued and the character isn't in a vehicle. Otherwise a strong urge only sets the game speed to normal.
> 	- The hold animation lasts from 40 to 120, longer the fuller the character is.
> - New functions: `BF.GetUrgeThresholds`, `BF.GetUrgeChance`, `BF.GetUrgeAccidentChance`, `BF.RollUrgeLeak`, `BF.DoUrgeWave`, `BF.GetUrgeFullness`. `BF.PlayUrgencyIdles` takes an optional hold time.
> - New sandbox options `BF.UrgeFrequencyMultiplier` and `BF.UrgeAccidentMultiplier` on the Bathroom page.
> - New translation key `IGUI_announce_UrgeHiccupMild` for weaker urges.
> ---
> Capacity:
> - `urinateValue` and `defecateValue` are still in mL. Capacity is now different per character, and fullness is mL divided by capacity.
> - New functions in `shared/BF_Shared.lua`:
> 	- `BF.GetBladderCapacity(player)`, `BF.GetBowelCapacity(player)`: the sandbox value times 0.75 for Small or 1.25 for Large (`BF.SmallCapacityScale`, `BF.LargeCapacityScale`).
> 	- `BF.GetBladderFullness(player)`, `BF.GetBowelFullness(player)`: 0 to 1.
> 	- `BF.GetBladderAmount(player)`, `BF.GetBowelAmount(player)`: mL currently held.
> 	- `BF.GetBaseBladderCapacity()`, `BF.GetBaseBowelCapacity()`: the sandbox value without traits.
> - Everything now uses these functions instead of reading `SandboxVars.BathroomFunctions.*MaxValue` directly. The old fallback values didn't match each other (100, 500, 600 or 800), but they didn't really even matter since the sandbox value is normally set.
> - `BF.GetMaxBladderValue` and `BF.GetMaxBowelValue` still work and call the new functions, in case other mods use them.
> - The server's `setValues` now limits each player to their own capacity, so Large Bladder/Bowels aren't changed based on the sandbox value (gotta look into this a little more though).
> - Moodles now use the player being updated instead of `getPlayer()`.
> - Pills add or remove an amount based on the sandbox value, limited to the player's capacity.
> - `BF.PeeInContainer` now adds the mod's fluid, trying `BF.HumanUrine` then `HumanUrine`, and converts mL to liters. The old code added a fluid called `Urine` and passed mL. Not checked whether the old code worked, whether vanilla has a `Urine` fluid, whether `addFluid` takes liters, or which name the new code needs.
> ---
> Dumpsters and trash cans:
> - `FixtureDefecate` now gets the object being used. When it finishes on a dumpster or trash can (`BF.IsWasteBin`), the client sends `depositWaste`.
> - The server finds that object's container and adds `BF.HumanFeces`. If the object has no container, it also checks the tiles around it, in case two-tile dumpsters only have a container on one piece (not checked). If the container is full, the feces drops on the ground next to it. It only happens if Create Poop Piles is on, and uses the same spam limit as waste spawning.
> - The full-container check uses `container:hasRoomFor(player, item)`. Not checked that this overload exists in B42.
> ---
> Cleanup:
> - Removed the `BF.EnableFecalFootprints` sandbox option and its text in all four languages, and the old commented-out footprint code in `BF_WasteProducts.lua`.

> [!question] 11/12/26
> Split screen:
> - Bug: In split-screen, bodily functions randomly assigned to only one player. Player 2's toilets didn't work near player 1 (ground did).
> - Cause: Code used `getPlayer()` everywhere which returns a random local player depending on update timing. Bladder ticks and toilet triggers checked the wrong player.
> - New `BF.ForEachLocalPlayer(fn)` iterates all active players (`getSpecificPlayer(0)` to `getNumActivePlayers()-1`), skipping dead players.
> - The 10-minute tick now runs filling, accidents, urges, and soiled clothing once for each local player.
> - Every function that used `getPlayer()` now takes the player:
> 	- Player is now required as the last argument: `BF.Get/SetUrinateValue`, `BF.Get/SetDefecateValue`, `BF.Get/SetPeedSelfValue`, `BF.Get/SetPoopedSelfValue`, `BF.Get/SetBodilyFumesValue`, `BF.PeeInContainer`, `BF.RefreshSoiledSeverityFromModData`.
> 	- Optional last argument, falls back to `getPlayer()`: `BF.PlayUrgencyIdles`.
> 	- Optional only argument: `BF.UpdateBathroomValues`, `BF.UpdateUrinationValues`, `BF.UpdateDefecationValues`, `BF.HandleInstantAccidents`, `BF.HandleUrgencyHiccup`, `BF.DirtyBottomsEffects`.
> 	- Player is now the first argument: `BF.TriggerSelfUrinate(player, isLeak)`, `BF.TriggerSelfDefecate(player, isLeak)`, `BF.TriggerGroundUrinate(player, isWiping, ...)`, `BF.TriggerGroundDefecate(player, isWiping, ...)`, `BF.UrinateBottoms(player, leakTriggered)`, `BF.DefecateBottoms(player, leakTriggered)`.
> 	- `BF.TriggerToiletUrinate/Defecate` and `BF.TriggerFixtureUrinate/Defecate` already took the player but replaced it with `getPlayer()`. They now use the one passed in.
> - "On Self" context menu options passed `worldObjects` as `isLeak`, so choosing "Pee/Poop on self" was always treated as a leak (only 5% released). They now pass `false`. (may change again, this wasn't really necessary but did it anyway)
> - Clothing stain overlays refresh for `self.character` after putting on or taking off clothing, instead of `getPlayer()`. They also refresh on `OnCreatePlayer`, so a split-screen player who joins later gets theirs.
> - `syncPlayerValues` sends values for every local player, and remembers what it last sent per player number. Before, a second split-screen player on a server never had their values sent.
> - The washing machine sweep, waste smell and flies check around every local player. A washer near two players is only cleaned once per minute.
> - Pills change the bladder or bowels of the player who took them.
> - A failed server request shows its error text over the player who sent it.
> 
> - First split screen test:
> 	- Bug: Controller player couldn't see toilet options in split-screen (mouse worked fine).
> 	- Cause: `BF.ReliefRightClick`, flush, and wash only checked `worldObjects[1]` tile. With controllers, this is the player's standing tile, not the interacted object.
> 	- Fix: New `BF.GetContextMenuObjects(worldObjects)` returns all objects from all tiles in `worldObjects`. Menus now return early when `test=true` (controller's existence check).
> 	- Status: Relief options working. Flush untested.
> - Second split-screen test:
> 	- Washing soiled clothing did nothing when clicked. This was caused with the change above: removing `worldObjects[1]` also removed the `square` the wash options pass to `BF.WashSoiled`, so it was `nil` and the function returned right away. This affected mouse players too. `square` is now the water source's tile. Tested, works.
> 	- Controller players couldn't open the wipe list because `ISContextMenu:onJoypadDown` only opens submenus when `onSelect` is `nil`, but our pee/poop options had their own `onSelect`. Added `BF.AddWipeSubMenu` that attaches the wipe list and sets `onSelect` to `nil` for controller players only. "Don't Wipe" in the list performs the same action. Mouse players can still click the option directly.
> 	- Added `onJoypadDown` to handle LB/RB tab switching and B to close the window, plus `onJoypadDirUp/Down` for scrolling.
> ---
> Being watched:
> - `BF.IsBeingWatched` checked Paruresis twice and Shy Bladder twice, and never checked Parcopresis or Shy Bowels. A character with only bowel shyness was never "watched". Fixed.
> - Split-screen players now count as watchers. They already did on a server through `getOnlinePlayers()`, but not in single player.
> - New `BF.DisableIfWatched`. Toilet and outhouse options are now greyed out with a tooltip when a shy character is watched. Before, the option looked usable but clicking it did nothing.
> - New translation keys `ContextMenu_tooltip_WatchedPee` and `ContextMenu_tooltip_WatchedPoop`, English only so far.
> - *Not tested in game yet*

> Added:
- **Urge Wave Frequency** and **Urge Wave Accident Chance** sandbox options. Set either to 0 to turn it off.
- **Pooping in a dumpster or trash can** now puts feces in its container. If it's full, the feces drops next to it.
- The character info tab now shows the bladder and bowels in mL, for example `52.5%  (420 / 800 mL)`.
- New line "I really need to go..." for weaker urges.

> Changed:
- **Urges reworked:**
	- Urges happen more often the fuller you are, with a short break after each one.
	- An urge can only cause an accident for the bladder or bowels that had it.
	- Going by the numbers (not tested in-game), if you go when the moodle shows a high urge, accidents should be rare. If you wait for hours, they should be likely.
	- Panic, stress, alcohol, diarrhea, low endurance and running make urges or accidents more likely. Sitting down makes accidents less likely.
	- Accidents are often a small leak if you aren't very full yet.
	- The character holds on longer the fuller they are.
	- Holding on no longer interrupts what you're doing. It only plays if you're standing idle.
- **Small/Large Bladder and Small/Large Bowels now work.** Capacity is 75% or 125% of normal, so you need to go sooner or can wait longer.
- **Urinary/Fecal Incontinence** no longer causes a full accident on every urge. Urges start much earlier and accidents are much more likely, but some are only a leak.
- **Bladder/Bowel Control** now also halves the chance of an accident during an urge.
- **Max Bladder/Bowels Capacity** is renamed to **Average Bladder/Bowel Capacity (mL)**. Traits change it per character.
- Leaking no longer plays the peeing sound.
- Pills now add or remove the same amount for everyone, so a diuretic fills a small bladder by a bigger percentage.

> Bug Fixes:
- Fixed a Lua error when a character with Bladder Control had an accident during an urge.
- Fixed urges being able to happen while already using the toilet.
- Peeing into a container may not have worked correctly before. It now uses the mod's urine and the real amount from your bladder. Tested in game!
- **Split screen:** Each player should now have their own bladder and bowels. Before, they only worked for one of the players, and which one could change. Toilets and other fixtures should also work for both players now. Tested that both players' bladders fill.
- **Controller:** Players using a controller should now get the pee, poop, flush and wash options for toilets, sinks and other things in front of them. Before, they only got them for things on the tile they were standing on. Tested with toilets and washing; flushing not tested yet.
- **Controller:** Players using a controller can now open the wipe list on pee and poop options with A. Before, A always chose "Don't Wipe". Tested in game.
- **Controller:** The Excretion tab in the character info window can now be left with LB/RB and closed with B, and scrolled with up/down. Before, the controller got stuck on it. Tested in game.
- "Pee on self" and "Poop on self" from the menu only released a small leak. They should now empty fully. Not tested in game.
- Shy Bowels and Parcopresis never counted anyone as watching. They now work the same as Shy Bladder and Paruresis. Not tested in game.
- Toilets and outhouses are now greyed out with a reason when you're too shy to use them because someone can see you. Before, clicking them did nothing.

> Removed:
- The **Footprints When Stepping On Poop** sandbox option. Footprints were removed in 1.0.0 and the option did nothing.

> **Testing disclaimer:** These changes **have not been tested in multiplayer**.
