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

> Removed:
- The **Footprints When Stepping On Poop** sandbox option. Footprints were removed in 1.0.0 and the option did nothing.

> **Testing disclaimer:** These changes **have not been tested in multiplayer**.
