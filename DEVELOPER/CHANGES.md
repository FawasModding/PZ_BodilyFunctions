-gotta make SelfUrinate SelfDefecate happen if using ground or toilet action ends too quickly

==============
[VERSION 0.12.0]
==============

- Reorganized Sandbox Menu.
- Changed "BodilyFunctions" function prefix to "BF"

- Flies now appear on human feces, whether it's on the ground or being held by the player.
- Standing near feces now applied food sickness (nausea) and unhappiness.
- Human Feces can now be used as fuel for fires.

- Added custom smell moodle (Bodily Fumes), for reacting to bodily fluids / functions (farting, poop, etc.)

==============
[VERSION 0.11.0]
==============

- Moved wipeable items to BF_WipingConfig
- Added partial wiping if you don't have enough of a certain item.
- Added the need to use multiple of each item type for wiping. For example, to fully wipe with paper, you need 4 of them.

- Fixed clothing with "Pants_Skinny" body location not being taken off when defecating (for example, Jeans)

- Changed tooltip for soiled clothing from percentage number to progress bar
- Changed "Soiled (Pee):" to "Urinated:", and "Soiled (Poop):" to "Defecated:".

==============
[VERSION 0.10.0]
==============

- Changed "Bathroom" to "BF" prefix for item scripts
- Added all pill boxes to distributions:
	- BathroomCabinet
	- BathroomCounter
	- MedicalClinicDrugs
	- MedicalStorageDrugs
	- SafehouseMedical
- Added crafting recipes for opening pill boxes.
- Medicine's tooltips are more accurate, showing that it just adds / removes from the value.

- Created "BF_ClothingConfig.lua" for new mapping of overlays to clothing items
- Renamed "BF_ClothingStains" to "BF_ClothingOverlays" and merged most of the functionality for simplicity (and better organization)
- Ensured no dirt on the body when player pees or poops themselves

- Changed "SuitTrousersMesh_Peed.png" to feature urine on the inner legs, as well as the back.
- Improved "Kate_SuitTrousers_Peed.fbx" to be significantly closer to the vanilla model. Less visible on the outside
	- This also fixes the issue of poop overlays not being visible

- Made male and female pooped overlay textures translucent

- Added support for LongShorts_Peed and LongShorts_Pooped models
- Added support for ShortShorts_Peed and ShortShorts_Pooped models
- Added support for BoxingShorts_Peed and BoxingShorts_Pooped models
- Added support for Trousers_Peed and Trousers_Pooped models

- Deleted "Bathroom_PeedPants", previously used for testing the overlay system at the beginning.

- Converted all script files from CRLF to LF to try to fix a potential Linux OS issue.

==============
[VERSION 0.9]
==============

- Made urine puddle object not appear when peeing in bed
- Created Pills and Pill Boxes for
	- Anti-Diarrheal Pills
	- Laxative Pills
	- Diuretic Pills
	- Anticholinergic Pills
- Created BathroomFunctions.GetMaxBowelValue() and BathroomFunctions.GetMaxBladderValue() in BF_Utils.lua
- Added Russian language support (from M1ST0R)
- Added Espanol (ES) support (from AI, may be wrong, feel free to give suggestions on how to improve it)

==============
[VERSION 0.81]
==============

- Replaced Bladder & Bowel moodles with more Zomboid B42 themed ones

==============
[VERSION 0.8]
==============

- Lots of script reorganization
- Fixed wiping items not being created
- Added mechanic where soiling yourself will first go through underwear, then pants. For example, peeing 5% in underwear will only add 5% severity in underwear, until you're at 100%, then it does 5% for pants.

- Organized BF_Urination and BF_Defecation more
- Changed "PeedOverlay" and "PeedOverlay2" to "PeedOverlay_Underwear" and "PeedOverlay_Pants"
- Changed "PoopedOverlay" and "PoopedOverlay2" to "PoopedOverlay_Underwear" and "PoopedOverlay_Pants"
- Fixed tags in pooped clothing overlays (PoopedOverlay)
- Fixed BF_ClothingStains to allow having two overlays at once for each function. So underwear and pants both get overlays at once.

- Added "Pants_Skinny" body location to BF_Lists. Allows them to be useable for urination / defecation.
- Added support for more clothing types

==============
[VERSION 0.7]
==============

- Added "RippedSheetsPooped" and "NewspaperPooped" items to Bathroom_SoiledWipes.txt
- Added support for all newspapers + Ripped Sheets in BathroomUtils.lua (for wiping)

- Added "MagazinePooped", "HottieZPooped", and "HunkZPooped" items to Bathroom_SoiledWipes.txt
- Added support for all magazines + all HottieZ mags in BathroomUtils.lua (for wiping)

- Fixed error where right clicking a toilet or outhouse toilet causes an error when you don't need to pee / poop

- Improved visuals of the BathroomCharacterInfo_GUIHandler tab ("Excretion" tab), includes gradient progress bars now.

==============
[VERSION 0.6]
==============

- Renamed "changelog.txt" to "CHANGES.md"
- Updated fileGuidTable.xml to include pooped clothing
- Added RunSpeedModifier and DiscomfortModifier to peed / pooped overlay items.
- Added "Kate_Shorts_Peed.fbx"

	============================
	[ BathroomClothOverlays.lua ]
	============================

- Now stores overlay types for both peed and pooped items using:
	- wornItem:getModData().peeOverlayItemType
	- wornItem:getModData().pooOverlayItemType

- Default overlay changed from "BathroomFunctions.SuitTrousersMesh_Peed" to "BathroomFunctions.BoxingShorts_Peed" (slightly safer, looks less weird for unadded clothing support)
- Added matching pooped overlay visuals for each peed overlay type
- Overlay only applies if peedSeverity or poopedSeverity is ≥ 25
- After equipping/unequipping, overlays are re-applied after a short delay to avoid conflicts

	============================
	[ BathroomFunctions.lua ]
	============================

- Added new function: BathroomFunctions.OverrideSandboxMax()
- Adjusts BladderMaxValue and BowelsMaxValue based on player traits:
	- SmallBladder, BigBladder, SmallBowels, BigBowels
	- Automatically runs when the game starts via Events.OnGameStart.Add()

- Rewrote BathroomFunctions.UpdateBathroomValues()
	- Now calculates urination and defecation rates with more realism.

- New factors affecting urgency:
	- Thirst level (affects bladder urgency)
	- Hunger level (affects bowel urgency)
	- Stress level (increases both bladder and bowel urgency)
	- Endurance level (nutrient need affects urgency)
	- Random variation added

- Enhanced BathroomFunctions.HandleInstantAccidents()
	- Added leak chance system that increases under: [ Drunkenness, Panic moodle level ]
	- Players with UrinaryIncontinence or FecalIncontinence can leak at lower thresholds
	- Leak chance can trigger self-urinate/defecate actions silently

- Modified BathroomFunctions.UrinateBottoms(leakTriggered) and DefecateBottoms(leakTriggered)
	- Both now accept an optional leakTriggered flag
	- Apply only 5% of full accident severity for leaks
	- Pee/poop overlays only applied if severity ≥ 25
	- Pee/poop objects only created if threshold met (not for small leaks)

- Improved BathroomFunctions.TriggerSelfUrinate(isLeak) and BathroomFunctions.TriggerSelfDefecate(isLeak)
	- Both now accept isLeak parameter to differentiate between small leaks and full accidents
	- Applies appropriate severity and messaging based on leak status

- Enhanced right-click context menu logic
	- Added trait-based restrictions:
		- ShyBladder, ShyBowels: Prevent peeing/defecating in public
		- Paruresis, Parcopresis: Prevent peeing/defecating when watched
		- Added helper function: BathroomFunctions.IsBeingWatched(player) to check nearby zombies or players

- Enhanced hygiene integration in BathroomFunctions.WashingRightClick(...)
	- Tracks original name of soiled clothing using originalName
	- Improved washing logic for soiled items

- Body overlay rendering improved:
	- PeedOverlay, PoopedOverlay rendered above pants
	- Additional layers for undies and pants-specific stains
	- Ensures proper visual layering of pee/poop overlays

	============================
	[ SelfDefecate.lua ]
	============================

- Added support for leak behavior with new constructor parameter: isLeak
	- When true, only 5% of bowel content is released gradually during defecation (This allows small leaks without full accidents)
- Updated start() and update() to track initial defecate value and simulate gradual release
- Added new method: finishDefecation()
	- Centralized logic to reset defecate value:
		- Full reset (= 0.0) for normal defecation
		- Partial reset (= 95% of original) for leak events
- Overridden stop() and cancel() methods to ensure finishDefecation() runs once
- Refactored perform() to call finishDefecation() before completing the action

	============================
	[ SelfUrinate.lua ]
	============================

- Added support for leak behavior with a new constructor parameter: isLeak
	- When true, only 5% of bladder content is released gradually during urination (this allows small leaks without full accidents)
- Updated start() and update() to track initial urinate value and simulate gradual release
- Added new method: finishUrination()
	- Centralized logic to reset urinate value:
		- Full reset (= 0.0) for normal urination
		- Partial reset (= 95% of original) for leak events
- Overridden stop() and cancel() methods to ensure finishUrination() runs once
- Refactored perform() to call finishUrination() before completing the action

	============================
	[ WashSoiled.lua ]
	============================

- Now properly restores the original name of a soiled item after washing:
	- Retrieves originalName from the item's modData
	- Sets the item's name back to its original value
	- Clears the originalName flag after use
- Resets visual and physical state:
	- Sets wetness = 100 (to simulate fresh washing)
	- Sets dirtyness = 0 (removes all dirtiness)

==============
[VERSION 0.51]
==============

==============
[VERSION 0.5]
==============

-Added rounding to the bladder / bowel values in the GUI, and the peed / pooped values on the soiled clothing.
-Removed "Bodily Functions" tab in the context menu for simplicity, might return at some point as a mod option
-Added "https://steamcommunity.com/sharedfiles/filedetails/?id=3378285185&searchtext=starl" requirement
-Added tooltips to peed / pooped clothing items, additionally removed text from the soiled item name.
-Replaced many ipairs with for loops for optimization
-Removed "Bladder / Bowel Moodle Type" mod option for now. Might come back eventually.
-Renamed health menu tab from "Bathroom" to "Excretion"
-MASSIVE optimization for peed clothing textures. Therefore also removed the "(Testing)" text for the "(Testing) Show Wet Spot" sandbox option.
-Added "'Say' Status" mod option that lets you choose if you want text displaying your status above your head.
-Fixed "Improper Toilet Sitting" problem. Now rotates to face the right direction when using toilets.
-Created "Wiped" variants of some items that replace wipe-able items.
-Added "Pee In Sink" and "Pee In Shower" options.
-Fixed the double toilet context menu option bug.
-Added "BF_" prefix to all sounds to prevent mod incompatabilities.

==============
[VERSION 0.42]
==============

-Added BathroomFunctions.ReequipBottomClothing and BathroomFunctions.ResetRemovedClothing
-Implemented re-equiping clothes after taking them off during bathroom functions
-Slightly modified Moodles_EN for consistency

==============
[VERSION 0.41]
==============

-Temporarily reversed thirst and hunger impacting bladder and bowel raise

==============
[VERSION 0.40]
==============

-Added code for a "Reset Sandbox Values" button in GUI. Maybe remove

-Simplified the UrinePuddle model by removing unnecessary faces. It is now a flat plane.
-Replaced the 3D model with a flat square plane, allowing for texture-based variations instead of relying on complex models.
-Introduced new textures for urine puddles:
	Hydrated texture (blue-er and clearer).
	Dehydrated texture (yellowish).
-Added Icons To Context Options
	Wash soiled clothing (uses PeedSelf texture)
	Pee in container (uses pee water bottle texture)
-Moved Bathroom_WasteProducts.txt models into Bathroom_Models.txt
-Added most (if not all) shorts to different list, meaning they will no longer show the peed jeans overlay.
-Renamed "Urine_Hydrated_0" to "Urine_Hydrated_0" and removed DisplayName
-Renamed "Urine_Hydrated_0" to "Urine_Hydrated_0" and removed DisplayName

-Thirst and Hunger Mechanics:
	Thirst and hunger levels now influence the production of urine and poop:
	Higher thirst/hunger slows down production.
	Lower thirst/hunger speeds it up.

-Increased the base urine production rate from 1% to 1.2% per cycle, making the system slightly faster.

-Added Traits: (Most are not yet fully implemented but will be worked on in future updates.)
	Bladder Traits:

	Small Bladder: "Bladder fills quicker and more urgently." (+1 points)
	Bedwetter: "Involuntary urination while asleep." (+3 points)
	Urinary Incontinence: "Poor bladder control in general." (+5 points)
	Paruresis: "Urination is difficult when near zombies or players." (+4 points)
	Shy Bladder: "Urination is difficult without using the toilet." (+6 points)
	Large Bladder: "Bladder takes longer to fill." (-1 point)
	Bladder Control: "75% chance to stop urination 5% of the way through peeing self." (-3 points)

	Bowel Traits:

	Small Bowels: "Bowels fill quicker and more urgently. (+1 points)
	Bedsoiler: "Involuntary defecation while asleep." (+3 points)
	Fecal Incontinence: "Poor bowel control in general." (+6 points)
	Parcopresis: "Defecation is difficult when near zombies or players." (+4 points)
	Shy Bowels: "Defecation is difficult without using the toilet." (+5 points)
	Large Bowels: "Bowels take longer to fill." (-1 point)
	Bowel Control: "75% chance to stop defecation 5% of the way through pooping self." (-3 points)

-Implemented Traits:
	Bedwetter: You will pee the bed if your bladder reaches near max value.
	Bedsoiler: You will poop the bed if your bowels reach near max value.

-Urgency Hiccup System:
	-Depending on your character's current mood and how full your bladder or bowels are, you might experience a "hiccup" of urgency. This could be a small reminder to go, or an unexpected accident.
	-Currently the only modifiers are "Panic" (increases chance of hiccup, doesn't impact accident chance yet), and "Drunkenness" (increases accident chance)
	-When you feel a sudden urgency, game speed slows down for a better reaction time.
	-The function that manages sudden accidents (formerly "CheckForAccident") is now renamed to HandleInstantAccidents. It triggers accidents in very sudden situations like being injured or overflowing bladder or bowels.
	-Hiccup chance is always 0 when sleeping, but as listed above, bedwetters and bedsoilers are still not safe.

-Cleaning Urine Puddles
	-Removed from inventory (as in not visible)
	-They cannot be picked up with the Grab function
	-They can be cleaned with either a Mop, Dish Towel, Bath Towel, or Toilet Brush
	

==============
[PRE-VERSIONS]
==============

1/5/25
-Player removes items listed in new function "BathroomFunctions.GetExcreteObstructiveClothing()" rather than "BathroomFunctions.GetSoilableClothing()"
-Added "ShortsShort" body location to GetSoilableClothing and GetExcreteObstructiveClothing
-Added "LongDress", "Dress", "LongSkirt", and "Skirt" body locations to GetExcreteObstructiveClothing
-Added IdleUrgencyPee timed action, random chance of playing when bladder is above 80%
-Added IdleUrgencyPoop timed action, random chance of playing when bowels is above 80%

1/4/25
-Made Human Feces edible. Poisonous. And addable to evolved recipes (like sandwiches)
-Remade Urine Puddle and Human Feces textures.
-Temporarily disabled peeing / pooping when sleeping. You now wake up on the verge.
-Changed values: (based on realism and not being horrible to deal with)
	PeeInToiletRequirement: 60% to 40%
	PeeOnGroundRequirement: 70% to 50%
	PeeOnSelfRequirement: 85% to 85%
	PeeInContainerRequirement: 70% to 60%

	PoopInToiletRequirement: 70% to 40%
	PoopOnGroundRequirement: 80% to 50%
	PoopOnSelfRequirement: 75% to 75%
-Changed moodle thresholds: (no more being unable to use the bathroom when the urge shows up)
		defecationThreshold
			[0.4] = 0.4, -- Mild urge starts at 40%
			[0.6] = 0.3, -- Moderate urge at 60%
			[0.8] = 0.2, -- High urge at 80%
			[0.9] = 0.1  -- Critical need at 90% or above
		urinationThreshold
			[0.4] = 0.4, -- Mild urge starts at 40%
			[0.6] = 0.3, -- Moderate urge at 60%
			[0.8] = 0.2, -- High urge at 80%
			[0.9] = 0.1  -- Critical need at 90% or above
-Simplified code in moodle calcualtion

1/3/25
-Removed "CanHavePoopPurpose", "CanHavePeePurpose", "CanPeeBottle" sandbox options
-Added "PeeInContainersOption", "PeeSelfOption", "PoopSelfOption" native B42 mod options
-Removed "DoMoodles" sandbox option
-Added "ShowMoodles", "ShowSoiledMoodles" native B42 mod options
-Added "MoodleType" native B42 mod option, not yet implemented though

-Made player take off soilable clothing before pooping (and peeing if female).
-Improved standing pee animation, still going to be recreated eventually.
-Added "ShortPants" to GetSoilableClothing in BathroomUtils

1/1/25
-Made player force awake if they start peeing or pooping in their sleep.
-Managing to halt the SelfDefecate or SelfUrinate action results in instant defecation / urination
-Renamed many functions for clarity
-Added pee in container context menu option. Takes amount in mL out of bladder and puts it into the selected bottle.
-Added fallback default values in case the mod updates and the player can't set sandbox values
-Temporarily disabled necessity for water in toilet when using.
-Added mod options, not yet integrated all the way.
-Changed mod page to need Moodles Framework B42.
-Increased radius for using toilets.
-Added "WalkTo" function for using toilets. (not thoroughly tested for outhouses and urinals)

12/31/24
-Made ToiletDefecate.lua also reduce urinate value, not just defecate
-Added GUI in player menu
-Fixed percentages in tooltips

12/30/24
-Added 3 new sandbox options
-Added support for disabling purposeful self urination / defecation
-Simplified sandbox-options.txt
-Player needs soap and water to clean soiled clothes + entire clean soiled clothes system added

12/26/24
-Added "icon.png"
-Added icons for context menu options
-Remade trait icons (Unused)
-Added weak and strong bladder traits (unused for now)

12/23/24
-Added context menu options for using the bathroom with a urinal, toilet, ground, and on self
-Added UrinateAction and DefecateAction actions
-GetSoilableClothing() BathroomUtils function
-Added "Liquid Laxative" and "Liquid Diuretic" liquids
-Made Pee, Laxative, and Diuretic liquids mixable.
-Added "Filtered Urine" liquid
-Revamped sandbox options page
-Added more underwear to the clothing overlay list
-Separated out "UrinateAction" and "DefecateAction" timed actions into three types
-Added Urine_Hydrated_0, Urine_Hydrated_0, HumanFeces items.
-Made Urine_Hydrated_0 spawn when the player pees themselves wearing clothes
-Made Urine_Hydrated_0 spawn when the player pees without clothes, either by squatting or having an accident without clothes
-Made HumanFeces spawn when the player poops on the ground
-Shortened PeeToilet and PeeSelf sounds
-Added functionality for:
	Sandbox_BathroomFunctions_PoopOnSelfRequirement
	Sandbox_BathroomFunctions_PoopOnGroundRequirement
	Sandbox_BathroomFunctions_PoopInToiletRequirement
	Sandbox_BathroomFunctions_PeeOnSelfRequirement
	Sandbox_BathroomFunctions_PeeOnGroundRequirement
	Sandbox_BathroomFunctions_PeeInToiletRequirement
-Updated context menu tooltips to show requirements sourced from sandbox settings
-Made peeing / pooping yourself use timed actions, a quarter of the currently pee / poop value
-Pee / poop values slowly go down as pee / poop timed actions go
-Added player voice lines for pooping / peeing self
-Added translation support for bodily functions
-Changed moodles to only cause urination / defecation when 50% or higher. Still VERY flawed though.
-Changed pee and poop moodles to hit 4/4 when 90% or higher

12/22/24
-Created several peed bottoms overlays, created a script that allows these to be applied when necessary.
-Removed display name from clothing items so it no longer shows up in inventory
-Added functionality to "Show Pee Stain" in Sandbox settings
-Added updated Build 42-style Urination and Defecation moodle icons

12/20/24
-Made PeedSelf and PoopedSelf moodles depend on the PeedSeverity and PoopedSeverity values on each clothing item. Which means, moodle disappears after 10 minutes of taking the soiled clothes off.

12/19/24
-Moved Translate to lua/shared to fix
-Added "Defecation" and "Urination" moodles
-Added "PoopedSelf" and "PeedSelf" moodles

12/18/24
-Added original assets
-Created "Urine" liquid type
-Reimplemented main BathroomFunctions.lua script, pee and poop meter
-Reimplemented Sandbox variables