## 1.4.0

> [!question] 11/4/26
> Multiplayer architecture:
> - Item and world changes now happen on the server, through `server/BF_ServerCommands.lua`. Timed actions send a command, and `client/BF_Commands.lua` routes the reply back.
> 	- Single player takes the same path, because `sendClientCommand` loops back into `OnClientCommand` there. `sendServerCommand` does nothing in single player, so the server file calls `BF.OnCommandResult` directly when there's no real server.
> 	- `sendAddItemToContainer` does nothing on a client, so items a client made with `AddItem` never existed on the server. That was the cause of soiled rags that couldn't be moved until relogging.
> 	- The server checks requests: item types against the wipe config, world objects by distance from the player, and it picks every output item itself.
> - Soiling is still simulated on the client and the server doesn't hold those values, so `wipe` and `wash` reply and the client updates the garment. `WipeSelf` applies its penalty and `WashSoiled:applyWash` applies the clean when that reply arrives.
> 	- TODO: Soiling isn't saved on the server, so it may not survive a relog in multiplayer.
> - `syncPlayerValues` no longer calls `transmitModData`. It sends only changed values through `setValues`, and the server clamps them. It covers bladder, bowels, peed self, pooped self, fumes and bladder strain.
> - Waste spawning moved to the server through `BF.SpawnWaste`, which replaces the client-side `AddWorldInventoryItem` calls.
> - Urine pickup is now blocked in `ISGrabItemAction:isValid` instead of `transferItem`. `start()` opens an item transaction, so blocking later still let the server move the item.
> ---
> File moves:
> - `BF_ScanUtils.lua` and `BF_Wipes.lua` moved to `lua/shared` so the server can use them.
> - New `shared/BF_Shared.lua` holds sandbox and trait checks, cleaning agents, wash costs and toilet water use.
> - `BF.RemoveBottomClothing` and `BF.ReequipBottomClothing` moved to the new `client/BF_Redress.lua`.
> - `BF.WalkThenRelief`, `BF.CanSitOnObject` and `BF.StandUpAfterToilet` now exist only in `BF_Urination.lua`. They were duplicated in `BF_Defecation.lua`.
> - Removed `BF.RemoveReachableItemType`, since clients no longer remove items themselves. Server code uses `BF.RemoveItemRecord`.
> ---
> Traits:
> - Vanilla fills the trait lists once, in `create()` at the main menu, before sandbox settings are chosen. `BF_TraitOptions.lua` rebuilds them in `setVisible` and removes any selected trait that's now disabled, refunding its points.
> - `BF.IsTraitEnabled` reads `getSandboxOptions()`, because `SandboxVars` may not hold the chosen settings yet on that screen.
> - All BF trait checks now go through `BF.HasTrait`. Characters keep the trait on their sheet, but it does nothing while disabled.
> ---
> Re-dressing:
> - Garments are remembered by item ID in `modData.bfRedress` until they're worn again. `modData.removedClothing` holds item objects, which don't survive a save, so it's now only used for the wiping penalty.
> - `BF.ReequipBottomClothing` skips anything already worn and does nothing if a re-dress is already queued, checked by looking for `BF_RedressComplete` in the queue.
> - Removed the re-dress calls made while the actions were being queued. The relief action's `perform` handles it, so re-dressing now comes after wiping and standing up.
> ---
> Performance:
> - Reachable item scans are cached on the client for 200ms (`BF.ReachableScanCacheMs`). One right-click menu could run the scan up to eleven times. The server always uses a fresh scan through `BF.BuildReachableItemRecords`.
> - `BF_ReliefTiles` lists are built once and also hold hash keys, so tile checks are a single lookup. The tables are shared, so don't change them.
> - All five moodles now skip `setValue` when the value hasn't changed, and mod option lookups are cached.
> ---
> Sounds:
> - `BF_Pee_Self` pointed at `media/sound/pee_ground_light.ogg`, which doesn't exist. It's now `Relief/pee_ground_light.ogg`. It loops, so only the `SelfUrinate` action plays it, and the extra `PlayWorldSound` in `BF.UrinateBottoms` is gone because nothing could stop it.
> - The throwable feces used `BF_PoopLanding`, but the sound is called `BF_Poop_Landing`.
> ---
> Outhouses and towels:
> - Outhouses have no vanilla seat data, so `BF.CanSitOnObject` is false and nothing seats the character. Pooping looked right only because `ToiletDefecate` plays `bathroomSitToilet` in that case. `ToiletUrinate` now does the same for female characters and uses the toilet's facing.
> - `BF.WashableJunk` in `BF_Shared.lua` now lists soiled cloth, what it washes into and its water cost. It replaces the rag-only check in `BF.IsSoiledJunk` and the server's `wash` command.
> - New item `BF.BathTowelPooped`, with its own icon and world texture. Both were made by staining the vanilla towel art.
> ---
> Known gaps:
> - TODO: `EnableVomiting`, `EnableFarting`, `EnableBurping`, `EnableSneezing`, `EnableCoughing` and `EnableFecalFootprints` still do nothing. They're also still labelled WIP where they were before.
> - TODO: Small Bladder, Big Bladder, Small Bowels and Big Bowels have no effect in the code.
> - TODO: New sandbox tooltips and action messages are EN and RU only. ES and PTBR need them.

> Added:
- **When To Undress** sandbox option: take clothes off before walking over, on arrival, or after sitting down.
- **Toilets Need Water** sandbox option, on by default: a flushing toilet needs enough water in its tank to be used. Without running water it has to be refilled.
- **Flushing:** a used toilet can now be flushed, which uses water and plays a sound. If Lifestyle: Hobbies is active, the flush option is left to that mod.
- **Get Dressed** option: appears in the right-click menu if clothes taken off for the bathroom are still off, for example after an interruption. It also has an option to forget those clothes.
- **Soiled Bath Towel:** wiping with a bath towel after pooping now gives a soiled towel with its own icon, instead of three rags. Washing it gives back a wet towel that dries on its own.
- Wiping support for Bath Towels Overhaul's Dust Cloth.
- A message when the server refuses a wash, a wipe or a waste cleanup.

> Sandbox Options Now Working:
- **Enable Defecation Traits / Enable Urination Traits:** hides those traits in character creation. They also stop working on existing characters while the option is off, and work again if it's turned back on.
- **Urination Enabled / Defecation Enabled:** when off, the bladder or bowels stay empty, the menu options are hidden and related traits are unavailable.
- **Enable Accidental Pee / Poop:** controls accidents while awake, including urges and incontinence.
- **Enable Bed Wetting / Bed Pooping:** controls accidents while asleep. A full bladder or bowel still wakes the character.
- **Time It Takes To Pee / Poop:** multiplies how long the action takes.
- **Flies Around Poop:** turns flies on or off.
- **Enable Diarrhea:** food sickness now makes the bowels fill faster, about 3x at 50 sickness and up to 5x at the worst.
- Removed the "(WIP)" and "(Placeholder Setting)" tags from these options.

> Changed:
- **Tissues** now use charges instead of the whole box being destroyed per wipe.
- **Toilet paper and tissues** pool their charges across everything in reach and use the fullest first, so a nearly empty roll no longer decides the wipe while a full one sits in your bag.
- **Washing now uses water:** 15 units for clothing and 5 for a rag. Before, it only checked the water level.
- **Outhouses** now offer wiping whenever the bowels are full enough, and female characters can wipe after urinating there, the same as a regular toilet.
- Clothes now go back on after wiping and standing up, instead of while still seated.
- Bladder and bowels now stop at their maximum value.

> Bug Fixes:
- Fixed clothes being put on twice after using the bathroom in some cases.
- Fixed outhouse options appearing twice when a square had two matching sprites.
- Fixed bladder strain never going away after emptying the bladder.
- Fixed female characters standing to pee at outhouses. They now sit, the same as when pooping.
- Fixed the fly sound never playing because of a misspelled sound name.
- Fixed the sound when peeing yourself pointing at a missing file.
- Fixed thrown feces having no landing sound.
- Fixed feces always landing in the corner of the tile instead of scattering slightly.
- Removed debug messages that were spamming the console.

> Multiplayer Fixes:
- Fixed soiled rags and other items made by wiping or washing being stuck in the inventory until relogging.
- Fixed urine puddles and feces only being visible to the player who made them.
- Fixed urine being picked up in multiplayer despite being blocked.
- Fixed toilet paper charges, cleaning agents and wiping items not updating correctly on the server.
- Improved bladder and bowel syncing, which now sends only the values that changed.

> Performance:
- Right-clicking is much lighter, since item scans and tile lists are no longer rebuilt several times per menu.
- Moodles no longer update every frame when nothing has changed.

> **Compatibility:** This update includes the fixes from **Bodily Functions Plus** and **Bodily Functions Dedicated Server Sync Fix**. Both are now marked as incompatible, so please remove them.

> **Multiplayer disclaimer:** These changes **have not been tested on a multiplayer server**. Please report any remaining multiplayer desyncs or related issues.
