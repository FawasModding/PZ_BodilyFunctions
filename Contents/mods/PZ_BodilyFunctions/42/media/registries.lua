-- required for build 42.13+
BFTraits = BFTraits or {}
BFBodyLocations = BFBodyLocations or {}
BFTags = BFTags or {}

BFTraits.SmallBowels = CharacterTrait.register("BF:SmallBowels")
BFTraits.Bedsoiler = CharacterTrait.register("BF:Bedsoiler")
BFTraits.FecalIncontinence = CharacterTrait.register("BF:FecalIncontinence")
BFTraits.Parcopresis = CharacterTrait.register("BF:Parcopresis")
BFTraits.ShyBowels = CharacterTrait.register("BF:ShyBowels")
BFTraits.BigBowels = CharacterTrait.register("BF:BigBowels")
BFTraits.BowelControl = CharacterTrait.register("BF:BowelControl")

BFTraits.SmallBladder = CharacterTrait.register("BF:SmallBladder")
BFTraits.Bedwetter = CharacterTrait.register("BF:Bedwetter")
BFTraits.UrinaryIncontinence = CharacterTrait.register("BF:UrinaryIncontinence")
BFTraits.Paruresis = CharacterTrait.register("BF:Paruresis")
BFTraits.ShyBladder = CharacterTrait.register("BF:ShyBladder")
BFTraits.BigBladder = CharacterTrait.register("BF:BigBladder")
BFTraits.BladderControl = CharacterTrait.register("BF:BladderControl")

BFBodyLocations.PeedOverlay_Underwear = ItemBodyLocation.register("BF:PeedOverlay_Underwear")
BFBodyLocations.PeedOverlay_Pants = ItemBodyLocation.register("BF:PeedOverlay_Pants")
BFBodyLocations.PoopedOverlay_Underwear = ItemBodyLocation.register("BF:PoopedOverlay_Underwear")
BFBodyLocations.PoopedOverlay_Pants = ItemBodyLocation.register("BF:PoopedOverlay_Pants")

BFTags.PeedOverlay = ItemTag.register("BF:PeedOverlay")
BFTags.PoopedOverlay = ItemTag.register("BF:PoopedOverlay")

BFTags.HumanUrine = ItemTag.register("BF:HumanUrine")
BFTags.HumanFeces = ItemTag.register("BF:HumanFeces")
BFTags.HumanVomit = ItemTag.register("BF:HumanVomit")