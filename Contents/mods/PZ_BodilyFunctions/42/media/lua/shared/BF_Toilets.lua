-- =====================================================
--
-- BF_Toilets
--
-- Toilet state on the game objects: what kind of toilet an object is, its
-- water, its state table, and using and flushing it.
--
-- State is stored in modData.movableData.bfSanitation. Vanilla copies movableData
-- onto the item when a toilet is picked up and back onto the toilet when it is
-- placed, so the state is kept.
--
-- Kinds of toilet:
--   flush     vanilla toilets and urinals; flushed with the toilet's own water
--   chemical  chemical toilets; a 30 L tank that is emptied with a bucket
--   wooden    outhouse seats; only get dirty
--
-- With Toilets Store Items on, flush toilets (not urinals) have a container
-- (BF_ToiletStorage). Pooping puts a feces item in it, and those items and
-- wipe junk count as the toilet's contents until flushed or taken out.
--
-- The whole system is disabled while Lifestyle: Hobbies is active, since it has its
-- own toilet dirt, clogging and flushing.
--
-- =====================================================

require "BF_Shared"
require "BF_Sewage"
require "BF_ToiletRules"
require "BF_ToiletVisuals"
require "BF_ToiletStorage"

BF_Toilets = {}
local S, R = BF_Toilets, BF_ToiletRules

-- Liters of mix per point of dirt washed off.
S.WASH_MIX = 0.0025
-- Without cleaning liquid or bleach, one wash removes at most DRY_WASH dirt and
-- can't get the toilet below DRY_FLOOR. With cleaner, one wash removes all of it.
S.DRY_WASH = 15
S.DRY_FLOOR = 20

-- Dirt a wash can take off: all of it with cleaner, otherwise the dry amount.
function S.washable(dirt, hasCleaner)
	if hasCleaner then return dirt end
	return math.max(0, math.min(S.DRY_WASH, dirt - S.DRY_FLOOR))
end
-- Maximum liters a failed flush spills; 3 L mostly stays on one square.
S.SPILL_MAX = 3
-- Clog chance (%) each waste item that doesn't flush adds to a flush.
S.NON_FLUSHABLE_CLOG = 15

-- Waste items that count as a stored toilet's contents. True = flushes away
-- cleanly; false = goes down but can clog the toilet.
S.WASTE_ITEMS = {
	["BF.HumanFeces"] = true,
	["BF.TissuePooped"] = true,
	["BF.SheetPaper2Pooped"] = true,
	["BF.ReceiptPooped"] = true,
	["BF.PaperNapkins2Pooped"] = true,
	["BF.GraphPaperPooped"] = true,
	["BF.MagazinePooped"] = false,
	["BF.NewspaperPooped"] = false,
	["BF.HottieZPooped"] = false,
	["BF.HunkZPooped"] = false,
	["BF.PaperworkPooped"] = false,
	["BF.GrassTuftPooped"] = false,
	["BF.RippedSheetsPooped"] = false,
	["BF.BathTowelPooped"] = false,
}

local lifestyle
function S.lifestyle()
	if lifestyle == nil then
		local mods = getActivatedMods()
		lifestyle = mods:contains("LifestyleHobbies") or mods:contains("\\LifestyleHobbies")
	end
	return lifestyle
end

-- False while Lifestyle: Hobbies handles toilets.
function S.active()
	return not S.lifestyle()
end

function S.group(obj)
	local sprite = obj and obj:getSprite()
	local props = sprite and sprite:getProperties()
	if props and props:has("CustomName") and props:get("CustomName") == "Toilet" then
		return props:has("GroupName") and props:get("GroupName") or "Low"
	end
	return nil
end

function S.kind(obj)
	local group = S.group(obj)
	if not group then return nil end
	if group == "Wooden" then return "wooden" end
	if group == "Chemical" then return "chemical" end
	return "flush"
end

S.canStore = BF.CanToiletStore

function S.waterUse(obj)
	if S.kind(obj) ~= "flush" then return nil end
	return BF.ToiletWaterUse[S.group(obj)] or 10
end

function S.hasWater(obj)
	local use = S.waterUse(obj)
	return not use or (obj:hasWater() and obj:getFluidAmount() >= use)
end

-- -----------------------------------------------------
-- Tank top-up
-- -----------------------------------------------------

function S.waterSource(item)
	local fc = item and item:getFluidContainer()
	if not fc or fc:getAmount() <= 0 or not fc:canPlayerEmpty() then return nil end
	if fc:isPureFluid(Fluid.Water) or fc:isPureFluid(Fluid.TaintedWater) then return fc end
	return nil
end

-- Water reserve of a toilet that was never moved from its map position, accessed like a fluid container.
local function reserveTank(obj)
	local md = obj:getModData()
	if md.canBeWaterPiped == true then return nil end
	local props = obj:getSprite() and obj:getSprite():getProperties()
	local max = tonumber(md.waterMaxAmount) or (props and (tonumber(props:get("waterMaxAmount")) or tonumber(props:get("waterAmount"))))
	if not max or max <= 0 or max >= 9999 then return nil end
	local tank = { reserve = true }
	function tank:getCapacity() return max end
	function tank:getAmount() return obj:getFluidAmount() end
	function tank:addFluid(_, amount)
		md.waterMaxAmount = max
		md.waterAmount = math.min(max, (tonumber(md.waterAmount) or tank:getAmount()) + amount)
		obj:transmitModData()
	end
	return tank
end

-- The toilet's tank when it can be topped up by hand: a flush toilet that isn't
-- on the mains or a plumbing mod's supply, with room left.
function S.tank(obj)
	if not S.waterUse(obj) or obj:getUsesExternalWaterSource() or obj:getFluidCapacity() >= 9999 then return nil end
	local fc = obj:getFluidContainer() or reserveTank(obj)
	if fc and fc:getAmount() < fc:getCapacity() then return fc end
	return nil
end

-- A tank's water source: a reserve only accepts clean water, since water taken from it is always clean.
function S.tankSource(tank, item)
	local fc = S.waterSource(item)
	if fc and tank and tank.reserve and not fc:isPureFluid(Fluid.Water) then return nil end
	return fc
end

-- -----------------------------------------------------
-- State
-- -----------------------------------------------------

function S.state(obj)
	local md = obj:getModData()
	return (md.movableData and md.movableData.bfSanitation) or R.newState(md.movableData)
end

-- The toilet's state, created if it has none yet. Server side only.
function S.ensure(obj)
	local md = obj:getModData()
	md.movableData = md.movableData or {}
	local movable = md.movableData
	if not movable.bfSanitation then
		movable.bfSanitation = R.newState(movable)
		-- The flag this mod's earlier versions used; now part of the state.
		movable.needFlush = nil
	end
	return movable.bfSanitation
end

-- Updates the stain and sends the state to clients. Server side only.
function S.sync(obj)
	local state = S.state(obj)
	local stage = BF_ToiletVisuals.stage(state.dirt)
	state.visualStage = stage
	BF_ToiletVisuals.apply(obj, stage, true)
	obj:transmitModData()
end

-- The toilet's item storage, when Toilets Store Items is on and it has one.
function S.storage(obj)
	if SandboxVars.BF.ToiletStorage ~= true or not S.canStore(obj) then return nil end
	local container = obj:getContainer()
	if container and container:getType() == BF.ToiletContainerType then return container end
	return nil
end

-- Waste items in a toilet's storage: feces count, other waste count, and how
-- many of them don't flush cleanly.
function S.storedWaste(container)
	local feces, other, stuck = 0, 0, 0
	if not container then return feces, other, stuck end
	local items = container:getItems()
	for i = 0, items:size() - 1 do
		local flushes = S.WASTE_ITEMS[items:get(i):getFullType()]
		if flushes ~= nil then
			if items:get(i):getFullType() == "BF.HumanFeces" then feces = feces + 1 else other = other + 1 end
			if flushes == false then stuck = stuck + 1 end
		end
	end
	return feces, other, stuck
end

-- Unflushed contents: the state's load plus, for a toilet with storage, the
-- waste items in it. Taking them out by hand lowers it.
function S.load(obj)
	local load = S.state(obj).load or 0
	local container = S.storage(obj)
	if container then
		local feces, other = S.storedWaste(container)
		load = load + feces * R.POOP_LOAD + other * R.PEE_LOAD
	end
	return load
end

-- True for a toilet that smells: a flush toilet with unflushed contents, or a
-- chemical toilet with waste in it and its bleach dose used up. Waste items in
-- a toilet's storage are counted separately by the smell check.
function S.smells(obj)
	if not S.active() then return false end
	local kind = S.kind(obj)
	if not kind then return false end
	local md = obj:getModData()
	local state = md.movableData and md.movableData.bfSanitation
	if not state then return false end
	if kind == "flush" then return (state.load or 0) > 0 end
	if kind == "chemical" then return state.chemicalLoad > 0 and R.dose(state) <= 0 end
	return false
end

-- Why the toilet can't be used, as a ContextMenu_BF_ key suffix, or nil.
function S.reason(obj)
	local kind = S.kind(obj)
	if not kind then return nil end
	local hasWater = S.hasWater(obj)
	local water = SandboxVars.BF.ToiletRequiresWater == false or hasWater
	if not S.active() then
		return (kind == "flush" and not water) and "NoWater" or nil
	end
	return R.blockReason(kind, S.state(obj), S.load(obj), water, hasWater)
end

-- -----------------------------------------------------
-- Using and flushing (server side)
-- -----------------------------------------------------

-- Puts a feces item into the toilet's storage. Returns false when it has no
-- storage or no room.
function S.depositFeces(obj, player)
	local container = S.storage(obj)
	local item = container and instanceItem("BF.HumanFeces")
	if not item or not container:hasRoomFor(player, item) then return false end
	container:AddItem(item)
	sendAddItemToContainer(container, item)
	return true
end

-- One visit. amount is the share of the relief completed (0 to 1). With
-- storage, a poop adds a feces item instead of load, if there is room.
function S.applyUse(obj, player, amount, poop)
	local kind = S.kind(obj)
	if not kind then return end
	local state = S.ensure(obj)
	local load = S.load(obj)
	local addLoad = not (poop and S.depositFeces(obj, player))
	if R.use(state, kind, amount, poop, load, addLoad, ZombRand(100)) then
		S.sync(obj)
	end
end

-- Removes the waste items from a toilet's storage. Anything else stays.
local function flushStorage(container)
	local items = container:getItems()
	for i = items:size() - 1, 0, -1 do
		local item = items:get(i)
		if S.WASTE_ITEMS[item:getFullType()] ~= nil then
			container:Remove(item)
			sendRemoveItemFromContainer(container, item)
		end
	end
end

-- Flushes, using the toilet's water. Returns "flushed", "clogged" (a waste item
-- that doesn't flush clogged it; the contents stay), "failed" (it was already
-- clogged) or "spilled" (it was clogged and overflowed onto the floor).
function S.flush(obj)
	local state = S.ensure(obj)
	local use = S.waterUse(obj)
	local load = S.load(obj)
	obj:useFluid(use)
	local result
	if not R.flush(state) then
		result = "failed"
		if ZombRand(100) < R.options().overflowChance then
			BF_Sewage.spread(obj:getSquare(), math.min(S.SPILL_MAX, load + use * 0.5))
			result = "spilled"
		end
	else
		local container = S.storage(obj)
		if container then
			local _, _, stuck = S.storedWaste(container)
			if ZombRand(100) < math.min(90, stuck * S.NON_FLUSHABLE_CLOG) then
				state.clogged, state.unclogProgress = true, 0
				result = "clogged"
			else
				flushStorage(container)
			end
		end
		result = result or "flushed"
	end
	S.sync(obj)
	return result
end

return S