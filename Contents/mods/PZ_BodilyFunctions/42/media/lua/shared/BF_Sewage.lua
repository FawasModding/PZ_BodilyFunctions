-- =====================================================
--
-- BF_Sewage
--
-- Puddles of sewage, urine and vomit on the floor.
--
-- A puddle is an IsoObject with its volume in liters in its modData. Puddles on
-- neighboring squares of the same room are drawn as one stain: the sprite is picked
-- from an autotile sheet of 47 shapes x 3 sizes. The puddle also keeps how many
-- of its liters are urine and vomit; whichever is at least half decides the sheet.
--
-- On soil a puddle soaks in over time (faster in rain). On a hard floor urine
-- dries; sewage and vomit stay until cleaned (BF_CleanPuddle).
--
-- Puddles are only created or changed on the server, or in single player.
--
-- =====================================================

require "TimedActions/ISDumpWaterAction"
require "Fluids/ISFluidEmptyAction"

BF_Sewage = {}
local W = BF_Sewage

-- Liters one square holds before the rest spreads; how far a spill can spread (squares).
W.SQUARE_MAX = 3
W.SPREAD = 3
-- Liters soil takes in per game hour, times this in rain on an open square.
W.SOAK = 0.5
W.RAIN_SOAK = 3
-- Liters of urine a puddle on a hard floor loses to drying per game hour.
W.URINE_DRY = 0.1
-- Liters at which a puddle looks bigger, and its sprite sheets.
W.SIZES = { 1, 2.5 }
W.SHEET = "bfp_puddles_01"
W.VOMIT_SHEET = "bfp_vomit_01"
W.URINE_SHEET = "bfp_urine_01"
-- Mod data field holding the liters of each kind of puddle that is not plain sewage.
W.KINDS = { vomit = "bfVomit", urine = "bfUrine" }
W.WASTE = { "HumanUrine", "HumanFeces", "HumanVomit" }

-- Cleaning: minimum share of cleaner in the mix, liters needed to start, liters of mix per liter of puddle.
W.MIX_SHARE = 0.1
W.WASH_START = 0.05
W.SPILL_MIX = 0.05

function W.authority()
	return not isClient()
end

function W.key(square)
	return square:getX() .. ":" .. square:getY() .. ":" .. square:getZ()
end

function W.isPuddle(obj)
	return obj ~= nil and obj:hasModData() and obj:getModData().bfSpill == true
end

-- True for bare soil floors, where puddles soak in and can be buried.
function W.natural(name)
	return name and (string.find(name, "floors_exterior_natural", 1, true) == 1
		or string.find(name, "blends_natural_01", 1, true) == 1)
end

function W.onSoil(square)
	local floor = square and square:getFloor()
	return floor ~= nil and W.natural(floor:getTextureName()) or false
end

-- Within one square of the player on the same level, with nothing in between.
function W.near(player, square)
	local here = player and player:getSquare()
	return here and square and here:getZ() == square:getZ()
		and math.abs(here:getX() - square:getX()) <= 1 and math.abs(here:getY() - square:getY()) <= 1
		and (here == square or not here:isBlockedTo(square))
end

local function setSprite(obj, name)
	obj:setSprite(name)
	obj:setSpriteFromName(name)
end

function W.fluid(name)
	return Fluid.Get(name) or Fluid.Get("BF." .. name)
end

-- Liters of urine, feces and vomit in a fluid container.
function W.sewage(fc)
	if not fc then return 0 end
	local total = 0
	for _, name in ipairs(W.WASTE) do
		local f = W.fluid(name)
		if f then total = total + fc:getSpecificFluidAmount(f) end
	end
	return total
end

-- -----------------------------------------------------
-- Cleaning tools
-- -----------------------------------------------------

-- Share of the given agents in a container holding only them and water; nil when anything else is in it.
function W.agentShare(fc, agents)
	if not fc or fc:getAmount() <= 0 then return nil end
	local agent = 0
	for _, fluid in ipairs(agents) do agent = agent + fc:getSpecificFluidAmount(fluid) end
	local water = fc:getSpecificFluidAmount(Fluid.Water) + fc:getSpecificFluidAmount(Fluid.TaintedWater)
	if agent + water < fc:getAmount() - 0.001 then return nil end
	return agent / fc:getAmount()
end

function W.isMix(fc, agents, least)
	local share = W.agentShare(fc, agents)
	return share ~= nil and share >= W.MIX_SHARE - 0.001 and fc:getAmount() >= least
end

-- Fluids that count as cleaner. Looked up when needed rather than at load.
function W.cleaningAgents()
	return { Fluid.CleaningLiquid, Fluid.Bleach }
end

-- Tools by kind: what qualifies as each.
W.tests = {
	shovel = function(v) return v:hasTag(ItemTag.DIG_GRAVE) and not v:isBroken() end,
	brush = function(v)
		local t = v:getFullType()
		return (t == "Base.Sponge" or t == "Base.ToiletBrush") and not v:isBroken()
	end,
	cleaner = function(v)
		return W.isMix(v:getFluidContainer(), W.cleaningAgents(), W.WASH_START)
	end,
	-- Toilet care (BF_ServiceToilet).
	plunger = function(v) return v:getFullType() == "Base.Plunger" and not v:isBroken() end,
	bleach = function(v)
		return W.isMix(v:getFluidContainer(), { Fluid.Bleach }, 1)
	end,
	bucket = function(v)
		local f = v:getFluidContainer()
		return v:hasTag(ItemTag.BUCKET) and f ~= nil and f:isEmpty() and f:getCapacity() >= 5
	end,
}

function W.items(player)
	local inv = player:getInventory()
	local tools = {}
	for kind, test in pairs(W.tests) do tools[kind] = inv:getFirstEvalRecurse(test) end
	return tools
end

-- -----------------------------------------------------
-- Puddles
-- -----------------------------------------------------

function W.registry()
	local data = ModData.getOrCreate("BF_Puddles")
	data.puddles = data.puddles or {}
	return data.puddles
end

function W.puddle(square)
	local objects = square and square:getObjects()
	if not objects then return nil end
	for i = 0, objects:size() - 1 do
		if W.isPuddle(objects:get(i)) then return objects:get(i) end
	end
end

function W.volume(obj)
	return obj and (obj:getModData().bfVolume or 2) or 0
end

-- Neighbors as dx, dy, bit; corners also list the two sides they require.
local SIDES = { { 0, -1, 1 }, { 1, 0, 2 }, { 0, 1, 4 }, { -1, 0, 8 } }
local CORNERS = { { 1, -1, 16, 1, 2 }, { 1, 1, 32, 4, 2 }, { -1, 1, 64, 4, 8 }, { -1, -1, 128, 1, 8 } }

local function has(bits, bit)
	return math.floor(bits / bit) % 2 == 1
end

-- Position of each valid neighbor pattern in the sprite sheet.
W.PATTERN = {}
do
	local position = 0
	for bits = 0, 255 do
		local valid = true
		for _, c in ipairs(CORNERS) do
			if has(bits, c[3]) and not (has(bits, c[4]) and has(bits, c[5])) then valid = false end
		end
		if valid then
			W.PATTERN[bits] = position
			position = position + 1
		end
	end
end

local function joined(square, dx, dy)
	local near = getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
	return near ~= nil and near ~= square and near:getRoom() == square:getRoom()
		and not square:isBlockedTo(near) and W.puddle(near) ~= nil
end

-- Sprite of a puddle on a square, based on the neighboring puddles it connects to, its volume and how much of it is vomit or urine.
function W.spriteFor(square, volume, vomit, urine)
	local bits = 0
	for _, s in ipairs(SIDES) do
		if joined(square, s[1], s[2]) then bits = bits + s[3] end
	end
	local sides = bits
	for _, c in ipairs(CORNERS) do
		if has(sides, c[4]) and has(sides, c[5]) and joined(square, c[1], c[2]) then bits = bits + c[3] end
	end
	local size = 0
	for i, limit in ipairs(W.SIZES) do
		if volume >= limit then size = i end
	end
	local sheet = W.SHEET
	if volume > 0 and (vomit or 0) * 2 >= volume then sheet = W.VOMIT_SHEET
	elseif volume > 0 and (urine or 0) * 2 >= volume then sheet = W.URINE_SHEET end
	return sheet .. "_" .. (W.PATTERN[bits] * 3 + size)
end

-- "urine", "vomit" or "sewage": the kind that decides the puddle's sprite.
function W.kindOf(obj)
	local md, volume = obj:getModData(), W.volume(obj)
	if volume > 0 and (md.bfVomit or 0) * 2 >= volume then return "vomit" end
	if volume > 0 and (md.bfUrine or 0) * 2 >= volume then return "urine" end
	return "sewage"
end

local function refreshSprite(square)
	local obj = W.puddle(square)
	if not obj then return end
	local md = obj:getModData()
	local sprite = W.spriteFor(square, W.volume(obj), md.bfVomit, md.bfUrine)
	if obj:getTextureName() ~= sprite then
		setSprite(obj, sprite)
		obj:transmitUpdatedSpriteToClients()
	end
end

local function refreshAround(square)
	refreshSprite(square)
	for _, list in ipairs({ SIDES, CORNERS }) do
		for _, n in ipairs(list) do
			local near = getCell():getGridSquare(square:getX() + n[1], square:getY() + n[2], square:getZ())
			if near and near ~= square then refreshSprite(near) end
		end
	end
end

-- Removes a puddle from its square and updates the sprites of the puddles around it.
function W.remove(obj)
	local square = obj:getSquare()
	W.registry()[W.key(square)] = nil
	square:transmitRemoveItemFromSquare(obj)
	refreshAround(square)
end

function W.setVolume(obj, volume)
	if volume <= 0.05 then
		W.remove(obj)
		return
	end
	local md = obj:getModData()
	local old = md.bfVolume or volume
	for _, field in pairs(W.KINDS) do
		if md[field] and old > 0 then md[field] = md[field] * math.min(1, volume / old) end
	end
	md.bfVolume = volume
	md.bfUpdated = getGameTime():getWorldAgeHours()
	refreshSprite(obj:getSquare())
	obj:transmitModData()
end

-- Adds liters to the puddle on a square, making one when there is none; kind "vomit" or "urine" marks them.
function W.add(square, liters, kind)
	if liters <= 0 or not square then return end
	local field = W.KINDS[kind]
	local obj = W.puddle(square)
	if obj and field then obj:getModData()[field] = (obj:getModData()[field] or 0) + liters end
	if not obj then
		obj = IsoObject.new(getCell(), square, W.spriteFor(square, liters, kind == "vomit" and liters or 0, kind == "urine" and liters or 0))
		obj:setName("BF_Spill")
		obj:getModData().bfSpill = true
		obj:getModData().bfVolume = 0
		if field then obj:getModData()[field] = liters end
		square:AddTileObject(obj)
		obj:transmitCompleteItemToClients()
		W.registry()[W.key(square)] = { x = square:getX(), y = square:getY(), z = square:getZ() }
		W.setVolume(obj, liters)
		refreshAround(square)
		return
	end
	W.setVolume(obj, W.volume(obj) + liters)
end

local function open(from, to)
	return to and to:getFloor() and not to:getProperties():has(IsoFlagType.water)
		and from:getRoom() == to:getRoom() and not from:isBlockedTo(to)
end

-- Spills liters from a square: fills it up to SQUARE_MAX, then spreads to open squares of the same room.
function W.spread(square, liters, kind)
	if not square or liters <= 0 then return end
	local queue, seen, head = { { square, 0 } }, { [square] = true }, 1
	local last = square
	while head <= #queue and liters > 0.05 do
		local sq, dist = queue[head][1], queue[head][2]
		head = head + 1
		last = sq
		local room = math.max(0, W.SQUARE_MAX - W.volume(W.puddle(sq)))
		local put = math.min(room, liters)
		if put > 0 then
			W.add(sq, put, kind)
			liters = liters - put
		end
		if dist < W.SPREAD then
			for _, d in ipairs({ IsoDirections.N, IsoDirections.E, IsoDirections.S, IsoDirections.W }) do
				local next = sq:getAdjacentSquare(d)
				if next and not seen[next] and open(sq, next) then
					seen[next] = true
					queue[#queue + 1] = { next, dist + 1 }
				end
			end
		end
	end
	if liters > 0.05 then W.add(last, liters, kind) end
end

-- -----------------------------------------------------
-- Soaking in and drying
-- -----------------------------------------------------

function W.update()
	if not W.authority() then return end
	local climate = getClimateManager()
	local rain = climate:getPrecipitationIntensity()
	if climate:getPrecipitationIsSnow() then rain = rain * 0.5 end
	local now = getGameTime():getWorldAgeHours()
	for key, p in pairs(W.registry()) do
		local square = getCell():getGridSquare(p.x, p.y, p.z)
		local obj = square and W.puddle(square)
		if square and not obj then
			W.registry()[key] = nil
		elseif obj then
			local hours = math.max(0, now - (obj:getModData().bfUpdated or now))
			local md = obj:getModData()
			if hours > 0 and W.onSoil(square) then
				local rate = W.SOAK * ((rain > 0 and square:isOutside()) and W.RAIN_SOAK or 1)
				W.setVolume(obj, W.volume(obj) - rate * hours)
			elseif hours > 0 and (md.bfUrine or 0) > 0 then
				local urine, vomit = md.bfUrine, md.bfVomit
				local dried = math.min(urine, W.URINE_DRY * hours)
				W.setVolume(obj, W.volume(obj) - dried)
				if W.puddle(square) == obj then
					-- setVolume scaled every kind down; only urine dries.
					md.bfUrine, md.bfVomit = urine - dried, vomit
					obj:transmitModData()
				end
			end
			refreshSprite(square)
		end
	end
end

Events.EveryTenMinutes.Add(W.update)

-- -----------------------------------------------------
-- Old saves
-- -----------------------------------------------------

-- Liters of urine an old urine item on the floor is converted to.
W.OLD_URINE = 0.3
local OLD_URINE = { ["BF.Urine_Hydrated_0"] = true, ["BF.Urine_Hydrated_1"] = true }

-- Old urine items on a square are converted to a urine puddle.
local function convertUrine(square)
	local objects, found = square:getObjects(), {}
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		local item = instanceof(obj, "IsoWorldInventoryObject") and obj:getItem()
		if item and OLD_URINE[item:getFullType()] then found[#found + 1] = obj end
	end
	for _, obj in ipairs(found) do
		square:transmitRemoveItemFromSquare(obj)
		W.add(square, W.OLD_URINE, "urine")
	end
end

-- When a square loads, its puddles get the current sprite and a registry entry.
Events.LoadGridsquare.Add(function(square)
	if not W.authority() then return end
	convertUrine(square)
	local obj = W.puddle(square)
	if not obj then return end
	local key = W.key(square)
	if not W.registry()[key] then W.registry()[key] = { x = square:getX(), y = square:getY(), z = square:getZ() } end
	refreshSprite(square)
end)

-- -----------------------------------------------------
-- Pouring waste out on the ground leaves a puddle of what was poured.
-- -----------------------------------------------------

local function startSewage(action)
	local fc = action.item and action.item:getFluidContainer()
	action.bfSewage = (fc and W.sewage(fc) > 0) and fc:getAmount() or 0
end

local dumpStart, dumpServerStart = ISDumpWaterAction.start, ISDumpWaterAction.serverStart
function ISDumpWaterAction:start()
	startSewage(self)
	dumpStart(self)
end
function ISDumpWaterAction:serverStart()
	startSewage(self)
	if dumpServerStart then dumpServerStart(self) end
end

local dumpComplete, dumpStop = ISDumpWaterAction.complete, ISDumpWaterAction.stop
function ISDumpWaterAction:complete()
	local liters = self.bfSewage or 0
	local done = dumpComplete(self)
	if liters > 0 then W.spread(self.character:getCurrentSquare(), liters) end
	return done
end
function ISDumpWaterAction:stop()
	if not isClient() and (self.bfSewage or 0) > 0 then
		W.spread(self.character:getCurrentSquare(), self.bfSewage * self:getJobDelta())
	end
	dumpStop(self)
end

-- Fluid menu Empty: an item is poured where the character stands, an object onto its own square.
local function emptySewage(action)
	local fc = action.container and action.container:getFluidContainer()
	action.bfSewage = (fc and W.sewage(fc) > 0) and fc:getAmount() or 0
end

local function emptySquare(action)
	local owner = action.container and action.container:getOwner()
	if owner and instanceof(owner, "IsoObject") then return owner:getSquare() end
	return action.character:getCurrentSquare()
end

local emptyStart, emptyServerStart = ISFluidEmptyAction.start, ISFluidEmptyAction.serverStart
local emptyComplete, emptyStop = ISFluidEmptyAction.complete, ISFluidEmptyAction.stop
function ISFluidEmptyAction:start()
	emptySewage(self)
	emptyStart(self)
end
function ISFluidEmptyAction:serverStart()
	emptySewage(self)
	if emptyServerStart then emptyServerStart(self) end
end
function ISFluidEmptyAction:complete()
	local liters = self.bfSewage or 0
	local done = emptyComplete(self)
	if liters > 0 then W.spread(emptySquare(self), liters) end
	return done
end
function ISFluidEmptyAction:stop()
	if not isClient() and (self.bfSewage or 0) > 0 then
		W.spread(emptySquare(self), self.bfSewage * self:getJobDelta())
	end
	emptyStop(self)
end

return W