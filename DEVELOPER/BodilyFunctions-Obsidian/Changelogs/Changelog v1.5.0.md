## 1.5.0

> Added:
- **Urge Wave Frequency** and **Urge Wave Accident Chance** sandbox options. Set either to 0 to turn it off.
- **Pooping in a dumpster or trash can** now puts feces in its container. If it's full, the feces drops next to it.
- The character info tab now shows the bladder and bowels in mL, for example `52.5%  (420 / 800 mL)`.
- New line "I really need to go..." for weaker urges.
- **Puddles:** Peeing on the ground now leaves a urine puddle instead of a urine item. The more was in the bladder, the bigger the puddle. [Not Tested]
	- Puddles next to each other in the same room join into one stain. Urine, sewage, and vomit puddles each look different.
	- Puddles on soil soak in over time, faster in rain. Urine on a hard floor slowly dries. Sewage and vomit stay until cleaned.
	- **Clean up:** Right-click a puddle and choose **Clean up urine**, **Clean up sewage** or **Clean up vomit**. Every way to clean it is in that one menu, and a way you can't use yet says why. [Not Tested]
		- **Scrub with cleaner:** A sponge or toilet brush and cleaning liquid or bleach. The cleaner can be thinned with water, as long as at least a tenth of it is cleaner. Bigger puddles take longer and use more cleaner. Tools in nearby containers or on the floor are picked up and put back afterward. [Not Tested]
		- **Wipe with...** (urine only): Anything you can wipe yourself with except books, plus a bar of soap or cleaning liquid. A small puddle (0.5 L) takes about a fifth of a roll of toilet paper and one use of soap. Each choice shows how much of the puddle it can wipe up; with too little, part of the puddle stays. Rags and towels come back wet or dirty. [Not Tested]
		- **Cover with soil:** Puddles on soil can be covered with a shovel. [Not Tested]
	- Emptying a container with urine, feces,or vomit in it onto the ground leaves a puddle. [Not Tested]
	- Peeing into a bush leaves a puddle on the bush's tile. Sinks, showers, tubs, water, and trash cans leave nothing. [Not Tested]
- Pooping into a bush now leaves a poop pile under the character. [Not Tested]
- **Toilet upkeep:** Toilets now get dirty, need flushing and can clog. All of it is off while Lifestyle: Hobbies is active, which has its own. [Not Tested]
	- Pooping adds dirt. Peeing doesn't.
	- After 3 visits a toilet has to be flushed before it can be used again.
	- Each visit has a 3% chance to clog the toilet, or 20% if it wasn't flushed since the last visit. A clogged toilet can't be used, and the pee and poop options say why. [Not Tested]
	- **Flush toilet** uses the toilet's own water, so it works with running water, rain collectors and plumbing mods. Flushing a clogged toilet doesn't work, adds some dirt and has a 25% chance to overflow into a small sewage puddle. [Not Tested]
	- **Unclog toilet** needs a plunger. Progress is kept if you stop, and a cleared toilet flushes by itself if it has water. [Not Tested]
	- **Wash toilet** needs a sponge or toilet brush. With cleaning liquid or bleach, plain or thinned with water, it takes off all the dirt. Without it, one wash only takes off 15 dirt and can't get the toilet below 20%. The option says what's missing. [Not Tested]
	- **Fill tank:** Pour water from a bucket or other container into a toilet that isn't on running water. [Not Tested]
	- **Chemical toilets** have a 30 L tank instead. **Empty chemical toilet** scoops out as much as an empty bucket holds, as urine and feces. **Refill chemical toilet** adds 1 L of bleach, which keeps the toilet from smelling for about 15 L of waste. [Not Tested]
	- Dirty toilets show stains in three stages. Outhouse seats have their own. [Not Tested]
	- An unflushed toilet, and a chemical toilet without bleach, now smell like other waste nearby. [Not Tested]
	- Tools, water and cleaners are taken from your bags and from containers in the same room, then put back. [Not Tested]
	- Everything above is in the toilet's own right-click entry, which also shows its dirt and why it can't be used. A toilet keeps all of this when picked up and moved. [Not Tested]
	- New sandbox options: **Visits Before Flushing**, **Toilet Clog Chance**, **Unflushed Toilet Clog Chance** and **Clogged Toilet Overflow Chance**. [Not Tested]
- **Relief Options In Fixture Menus** mod option (off by default), set by each player. The options to pee or poop in a toilet or sink are back in the Urinate and Defecate menus. Turn this on to put them in the toilet's or sink's own right-click menu instead, as before. [Not Tested]
- **Toilets Store Items** sandbox option (off by default). Toilets (not urinals, chemical toilets or outhouses) get a small container that shows in the loot window. A toilet gets it the next time its area loads, or when it's placed. In multiplayer, a toilet placed while you're nearby may only show the container after the area reloads. A toilet that already has a container from another mod is left alone. [Not Tested]
	- Pooping in a toilet puts feces in its container. If it's full, the feces still counts toward what needs flushing.
	- Soiled items from wiping after pooping in a toilet go into its container instead of your inventory. Whatever doesn't fit goes to your inventory.
	- The waste in the container counts as the toilet's contents. Taking it all out by hand empties the toilet without flushing, unless someone peed in it since the last flush.
	- Flushing removes only the waste. Other items you put in the toilet stay. Soiled magazines, newspapers, rags, towels and grass don't flush well: each one adds a 15% chance that the flush clogs the toilet.
- **Debug mode:** Right-click the Excretion tab to set the bladder or bowels to an amount.

> Changed:
- **Urges reworked:**
	- Urges happen more often the fuller you are, with a short break after each one.
	- An urge can only cause an accident for the bladder or bowels that had it.
	- Going by the numbers, if you go when the moodle shows a high urge, accidents should be rare. If you wait for hours, they should be likely. [Not Tested]
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
- Poop piles now land exactly where the character is standing. Before, they showed up off to the side. [Not Tested]
- Eating a poop pile now actually poisons you. Its poison was too weak to matter before. [Not Tested]
- Urine items left on the ground in older saves turn into small puddles when that area loads. [Not Tested]

> Bug Fixes:
- Fixed a Lua error when a character with Bladder Control had an accident during an urge.
- Fixed urges being able to happen while already using the toilet.
- Peeing into a container may not have worked correctly before. It now uses the mod's urine and the real amount from your bladder.
- **Split screen:** Each player should now have their own bladder and bowels. Before, they only worked for one of the players, and which one could change. Toilets and other fixtures should also work for both players now.
- **Controller:** Players using a controller should now get the pee, poop, flush and wash options for toilets, sinks and other things in front of them. Before, they only got them for things on the tile they were standing on. Flushing [Not Tested]
- **Controller:** Players using a controller can now open the wipe list on pee and poop options with A. Before, A always chose "Don't Wipe".
- **Controller:** The Excretion tab in the character info window can now be left with LB/RB and closed with B, and scrolled with up/down. Before, the controller got stuck on it.
- "Pee on self" and "Poop on self" from the menu only released a small leak. They should now empty fully. [Not Tested]
- Shy Bowels and Parcopresis never counted anyone as watching. They now work the same as Shy Bladder and Paruresis. [Not Tested]
- Toilets and outhouses are now greyed out with a reason when you're too shy to use them because someone can see you. Before, clicking them did nothing. [Not Tested]
- Pooping yourself with no pants or underwear on now leaves a poop pile on the ground. Before, nothing was left. [Not Tested]

> Removed:
- The **Footprints When Stepping On Poop** sandbox option. Footprints were removed in 1.0.0 and the option did nothing.
- The "Clean Urine With..." options for mops, toilet brushes, dish cloths and bath towels. Puddles are now cleaned from their **Clean up** menu. [Not Tested]

> **Testing disclaimer:** These changes **have not been tested in multiplayer**.

---

> [!success] Commit #3
> Puddles:
> - New `shared/BF_Sewage.lua`. A puddle is an `IsoObject` named `BF_Spill` with `modData.bfSpill = true` and its volume in liters in `modData.bfVolume`. `modData.bfUrine` and `modData.bfVomit` hold how many of those liters are urine and vomit.
> - `BF_Sewage.add(square, liters, kind)` adds to the puddle on a square or makes a new one. `BF_Sewage.spread(square, liters, kind)` fills a square up to 3 L (`SQUARE_MAX`), then runs on to open squares of the same room, up to 3 squares away (`SPREAD`). `kind` is `"urine"`, `"vomit"` or nil for sewage.
> - Sprites come from an autotile sheet: 47 shapes (by which of the 8 neighbors also have a puddle in the same room and aren't blocked) times 3 sizes (under 1 L, under 2.5 L, 2.5 L and up). If at least half the volume is vomit the vomit sheet is used, otherwise if at least half is urine the urine sheet, otherwise sewage. Neighbors are re-joined whenever a puddle is added or removed. [Vomit & Sewage Not Tested]
> - New tilesets `bfp_puddles_01`, `bfp_urine_01` and `bfp_vomit_01` in `media/BFP_Sanitation.tiles` with the texture pack `BFP_Sanitation.floor.pack`. `mod.info` now has `pack=BFP_Sanitation.floor` and `tiledef=BFP_Sanitation 8161`. The tile file and pack also hold tilesets for toilets, pit covers and stains that nothing uses yet. [Not Tested]
> - Puddle tiles have `FloorOverlay` without `RenderLayer = Floor`, and each puddle tileset has a depth map in `common/media/depthmaps`. Depth maps only load when `common/media/tileGeometry.txt` exists, so that file was added too. This is meant to make puddles draw over rugs, which otherwise hide them.
> - Puddles are listed in the global mod data `BF_Puddles`. Every 10 minutes the server goes through them: on soil (`floors_exterior_natural*` or `blends_natural_01*`) a puddle loses 0.5 L per game hour, 1.5 L while it rains or snows on an outdoor square. On other floors only the urine part dries, 0.1 L per game hour. A puddle at 0.05 L or less is removed. [Not Tested]
> - On `LoadGridsquare`, `BF.Urine_Hydrated_0` and `BF.Urine_Hydrated_1` world items are replaced with a 0.3 L urine puddle. The item scripts stay so old saves can still load them. [Not Tested]
> - `ISDumpWaterAction` and `ISFluidEmptyAction` are wrapped: if the container has any urine, feces or vomit, a sewage puddle of the container's whole amount is spread where it was poured. Stopping partway spreads the poured part. [Not Tested]
> ---
> Cleaning puddles:
> - New `shared/TimedActions/BF_CleanPuddle.lua` with two operations:
> 	- `clean`: needs a `Base.Sponge` or `Base.ToiletBrush` and a container of only cleaning liquid or bleach and water, at least 10% cleaning agent and at least 0.05 L. Uses 0.05 L of the mix per liter of puddle (`SPILL_MIX`); with less, part of the puddle stays. Takes 60 ticks per liter, at least 60. [Not Tested]
> 	- `bury`: needs an item with the `DIG_GRAVE` tag, only on soil. Removes the whole puddle. Takes 200 ticks. [Not Tested]
> - It's in `shared` so the server runs `complete()` in multiplayer. The fields keep the same names as the `new()` parameters, because the server rebuilds the action from them. [Not Tested]
> - New `client/_Shared/Player/ContextMenu/BF_PuddleActions.lua` adds the two options. The clean option's tooltip says what's missing: no sponge or brush, no cleaner, a mix that's too weak, or too little left. [Not Tested]
> - New `client/_Shared/Utils/BF_Supplies.lua` finds tools in the inventory, bags, and containers or floor items within one tile of the puddle in the same room. Ones not in the main inventory are fetched first and returned afterward. [Not Tested]
> - New translation keys in English and Russian: `ContextMenu_BF_CleanSpill`, `ContextMenu_BF_CleanSpillHint`, `ContextMenu_BF_BurySpill`, `ContextMenu_BF_BuryHint`, `ContextMenu_BF_NoBrush`, `ContextMenu_BF_WeakMix`, `ContextMenu_BF_LittleCleaner`, `ContextMenu_BF_NoCleaner`. [Not Tested]
> - Removed `BF_CleanActions.lua`, `CleanWasteProduct.lua`, the server's `cleanWaste` command, `BF.WasteCleaningTools`, `BF.UrineWorldTypes`, `BF.IsCleanableWaste`, and the keys `IGUI_announce_CantPickUpPee` and `IGUI_BF_CleanWasteFailed` in all four languages. `media/textures/Mop.png` isn't used anymore.
> ---
> Waste on the ground:
> - New `shared/BF_Waste.lua`. `BF.SpawnWaste(player, kind, bladderValue, square)` now sends the target square: [Not Tested]
> 	- `pee`: a urine puddle of `bladderValue / 1000` liters, from 0.1 to 1.5 L. `bladderValue` defaults to the current `urinateValue`, but relief actions count that down to about 0 by the time they finish, so `GroundUrinate` and `FixtureUrinate` pass the value they started with. [Not Tested]
> 	- `poop`: a pile at the character's exact position inside their square. Before, it was placed 0.1-0.5 into the northwest corner of the square. [Not Tested]
> - The server's `spawnWaste` accepts a square up to 3 tiles away and up to 8 floors below the character (for peeing out of a window), and limits pee to 1.5 L. Poop is only accepted on the character's own square. `depositWaste` only accepts poop now. [Not Tested]
> - `FixtureUrinate:new` now takes the fixture. Into a bush, the puddle goes on the bush's square. Out of an open window (`BF_Waste.isOpenWindow`), it goes on the far side of the window, falling to the first floor below that has one. There's no menu option for peeing out of a window yet, so that part does nothing for now. [Not Tested]
> - `FixtureDefecate` on a bush now spawns a poop pile under the character. Dumpsters and trash cans still store it. [Not Tested]
> - `BF.TriggerSelfDefecate` had an empty branch for when no soilable clothing is worn. It now calls `BF.SpawnWaste(player, "poop")` there if Create Poop Piles is on, the same way `BF.TriggerSelfUrinate` already spawns pee.
> - `BF.HumanFeces` has `PoisonPower = 30` instead of 1. [Not Tested]
> - `BF_WasteProducts.lua` counts puddles in its smell check, as urine. Before, it counted the urine items. Flies still only come from poop. [Not Tested]
> - The Create Urine Puddles tooltip now says "Peeing on the ground leaves a urine puddle." [Not Tested]
> ---
> Debug:
> - Right-clicking the Excretion tab in the character info window opens a menu while the game is in debug mode (`isDebugEnabled()`). It has a Bladder and a Bowels submenu, each showing the current mL and capacity, with 0%, 25%, 50%, 75%, 90%, and 100% of capacity, and "Set mL..." to type an amount. Values are kept between 0 and the capacity and set with `BF.SetUrinateValue` / `BF.SetDefecateValue`. The menu text is English only.

> [!success] Commit #2
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
> 	- Status: Relief options working. Flush [Not Tested]
> - Second split-screen test:
> 	- Washing soiled clothing did nothing when clicked. This was caused with the change above: removing `worldObjects[1]` also removed the `square` the wash options pass to `BF.WashSoiled`, so it was `nil` and the function returned right away. This affected mouse players too. `square` is now the water source's tile.
> 	- Controller players couldn't open the wipe list because `ISContextMenu:onJoypadDown` only opens submenus when `onSelect` is `nil`, but our pee/poop options had their own `onSelect`. Added `BF.AddWipeSubMenu` that attaches the wipe list and sets `onSelect` to `nil` for controller players only. "Don't Wipe" in the list performs the same action. Mouse players can still click the option directly.
> 	- Added `onJoypadDown` to handle LB/RB tab switching and B to close the window, plus `onJoypadDirUp/Down` for scrolling.
> ---
> Being watched:
> - `BF.IsBeingWatched` checked Paruresis twice and Shy Bladder twice, and never checked Parcopresis or Shy Bowels. A character with only bowel shyness was never "watched". Fixed. [Not Tested]
> - Split-screen players now count as watchers. They already did on a server through `getOnlinePlayers()`, but not in single player. [Not Tested]
> - New `BF.DisableIfWatched`. Toilet and outhouse options are now greyed out with a tooltip when a shy character is watched. Before, the option looked usable but clicking it did nothing. [Not Tested]
> - New translation keys `ContextMenu_tooltip_WatchedPee` and `ContextMenu_tooltip_WatchedPoop`, English only so far. [Not Tested]

> [!success] Commit #1
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