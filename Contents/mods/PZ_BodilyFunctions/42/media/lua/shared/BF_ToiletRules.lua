-- =====================================================
--
-- BF_ToiletRules
--
-- Constants and rules of the toilet system, without any game object access:
-- a toilet's state table and what using, flushing, cleaning, unclogging and
-- emptying do to it.
--
-- =====================================================

BF_ToiletRules = {}
local R = BF_ToiletRules

-- Units of unflushed contents and points of dirt one full visit adds.
R.POOP_LOAD = 2
R.PEE_LOAD = 0.5
R.POOP_DIRT = 4
-- Dirt added by flushing a clogged toilet (20 in the original).
R.CLOGGED_FLUSH_DIRT = 10
-- Liters a chemical toilet's tank holds, and liters of waste one dose of bleach keeps from smelling.
R.CHEMICAL_CAPACITY = 30
R.DOSE_LITRES = 15

function R.clamp(value, low, high)
	local number = tonumber(value) or low
	if number ~= number then return low end
	return math.max(low, math.min(high, number))
end

function R.options()
	local s = SandboxVars.BF or {}
	return {
		maxVisits = R.clamp(s.UnflushedVisits or 3, 1, 20),
		clogChance = R.clamp(s.ToiletClogChance or 3, 0, 100),
		dirtyClogChance = R.clamp(s.UnflushedClogChance or 20, 0, 100),
		overflowChance = R.clamp(s.ToiletOverflowChance or 25, 0, 100),
	}
end

-- A new state. `legacy` is the toilet's movableData, so a toilet this mod's
-- earlier versions marked as needing a flush starts out unflushed.
function R.newState(legacy)
	local m = legacy or {}
	return {
		version = 1,
		dirt = 0,
		visits = m.needFlush and 1 or 0,
		load = m.needFlush and 1 or 0,
		clogged = false,
		unclogProgress = 0,
		chemicalLoad = 0,
	}
end

-- Why the toilet can't be used, as a ContextMenu_BF_ key suffix, or nil.
-- `load` is the toilet's unflushed contents (see BF_Toilets.load). hasWater is
-- true when the toilet may be used as far as water goes; canFlush is false when
-- it has no water to flush with and doesn't need any (Toilets Need Water off),
-- so it can still be used when it can't be flushed.
function R.blockReason(kind, state, load, hasWater, canFlush)
	if kind == "chemical" and state.chemicalLoad >= R.CHEMICAL_CAPACITY then return "ChemicalFull" end
	if state.clogged then return "Clogged" end
	if kind == "flush" and canFlush and load > 0 and state.visits >= R.options().maxVisits then return "NeedFlush" end
	if kind == "flush" and not hasWater then return "NoWater" end
	return nil
end

-- Liters of waste one relief leaves, by the share of it completed.
function R.waste(amount, isPoop)
	return R.clamp(amount, 0, 1) * (isPoop and R.POOP_LOAD or R.PEE_LOAD)
end

-- How much of a dose is left in a chemical toilet, 0 to 1. A toilet that
-- hasn't been used yet starts with a full dose.
function R.dose(state)
	return state.chemicalDose or 1
end

-- Adds the waste of one relief to a chemical toilet's tank and uses up the dose.
function R.fillChemical(state, amount, isPoop)
	local put = math.min(math.max(0, R.CHEMICAL_CAPACITY - state.chemicalLoad), R.waste(amount, isPoop))
	local field = isPoop and "chemicalFeces" or "chemicalUrine"
	state.chemicalDose = math.max(0, R.dose(state) - put / R.DOSE_LITRES)
	state.chemicalLoad = state.chemicalLoad + put
	state[field] = (state[field] or 0) + put
end

-- One visit. amount is the share of the relief completed (0 to 1). load is the
-- toilet's contents before this visit. addLoad is false when the waste went
-- into the toilet's storage as an item instead. roll is 0-99 for the clog check.
function R.use(state, kind, amount, isPoop, load, addLoad, roll)
	amount = R.clamp(amount, 0, 1)
	if amount <= 0 then return false end
	if isPoop then state.dirt = math.min(100, state.dirt + amount * R.POOP_DIRT) end
	if kind == "wooden" then return true end

	-- A toilet with nothing in it was flushed or emptied by hand since the last visit.
	if load <= 0 then state.visits = 0 end
	state.visits = state.visits + 1
	if addLoad then state.load = state.load + R.waste(amount, isPoop) end
	if kind == "chemical" then R.fillChemical(state, amount, isPoop) end

	local opts = R.options()
	local chance = load > 0 and opts.dirtyClogChance or opts.clogChance
	if (roll or 100) < chance * amount then
		state.clogged = true
		state.unclogProgress = 0
	end
	return true
end

-- Takes up to capacity liters out of a chemical toilet; returns the liters of urine and feces taken.
function R.scoop(state, capacity)
	local load = state.chemicalLoad
	local taken = math.min(capacity, load)
	if taken <= 0 then return 0, 0 end
	local urine, feces = state.chemicalUrine or 0, state.chemicalFeces or 0
	local known = urine + feces
	local urineShare = known > 0 and urine / known or 0.6
	local share = taken / load
	local takeUrine, takeFeces = taken * urineShare, taken * (1 - urineShare)
	state.chemicalDose = R.dose(state) * (1 - share)
	state.chemicalLoad = load - taken
	state.chemicalUrine = math.max(0, urine - takeUrine)
	state.chemicalFeces = math.max(0, feces - takeFeces)
	if state.chemicalLoad <= 0.001 then
		state.chemicalLoad, state.chemicalUrine, state.chemicalFeces, state.chemicalDose = 0, 0, 0, 0
	end
	return takeUrine, takeFeces
end

-- Returns false when the toilet was clogged: the flush fails, unclogging
-- progress is reset and some dirt is added.
function R.flush(state)
	if state.clogged then
		state.unclogProgress = 0
		state.dirt = math.min(100, state.dirt + R.CLOGGED_FLUSH_DIRT)
		return false
	end
	state.visits, state.load = 0, 0
	return true
end

function R.maintain(state, operation, progress)
	if operation == "clean" then state.dirt = math.max(0, state.dirt - progress * 100) end
	if operation == "unclog" then
		state.unclogProgress = math.min(1, state.unclogProgress + progress)
		if state.unclogProgress >= 0.999 then
			state.clogged, state.unclogProgress = false, 0
		end
	end
end

return R