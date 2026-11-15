-- =====================================================
--
-- BF_Supplies
--
-- Finds the tools for a job in the inventory, its bags, and containers and
-- floor items within one tile of the work square in the same room. The tools
-- are fetched before the work and put back where they came from afterward.
--
-- =====================================================

require "BF_Sewage"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISGrabItemAction"
require "ISUI/ISCraftingUI"

BF_Supplies = {}
local P = BF_Supplies

-- Runs a function when the queue reaches it, so walk paths start from the character's position at that time.
BF_SupplyStep = ISBaseTimedAction:derive("BF_SupplyStep")

function BF_SupplyStep:isValid()
	return true
end

function BF_SupplyStep:start()
	self:beginAddingActions()
	self.run(self.character)
	self:endAddingActions()
	self:forceComplete()
end

function BF_SupplyStep:perform()
	ISBaseTimedAction.perform(self)
end

function BF_SupplyStep:new(character, run)
	local o = ISBaseTimedAction.new(self, character)
	o.run = run
	o.stopOnWalk, o.stopOnRun, o.stopOnAim = false, false, false
	return o
end

local function reachable(from, to)
	return to and to:getRoom() == from:getRoom() and (to == from or not from:isBlockedTo(to))
end

-- Records { item, container, world, square } in order: main inventory, bags, then around the square.
function P.records(player, square)
	local out, seen = {}, {}
	local inv = player:getInventory()
	local function add(item, record)
		if not item or seen[item:getID()] then return end
		seen[item:getID()] = true
		record.item = item
		out[#out + 1] = record
	end
	local items, bags = inv:getItems(), {}
	for i = 0, items:size() - 1 do
		local item = items:get(i)
		add(item, { container = inv })
		if instanceof(item, "InventoryContainer") then bags[#bags + 1] = item:getInventory() end
	end
	for _, bag in ipairs(bags) do
		local inside = bag:getItems()
		for i = 0, inside:size() - 1 do add(inside:get(i), { container = bag }) end
	end
	if not square then return out end
	for dx = -1, 1 do
		for dy = -1, 1 do
			local sq = getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
			if reachable(square, sq) then
				local objects = sq:getObjects()
				for i = 0, objects:size() - 1 do
					local obj = objects:get(i)
					if instanceof(obj, "IsoWorldInventoryObject") then
						add(obj:getItem(), { world = obj, square = sq })
					elseif not (instanceof(obj, "IsoThumpable") and obj:isLockedToCharacter(player)) then
						for c = 0, obj:getContainerCount() - 1 do
							local container = obj:getContainerByIndex(c)
							local inside = container:getItems()
							for j = 0, inside:size() - 1 do add(inside:get(j), { container = container, square = sq }) end
						end
					end
				end
			end
		end
	end
	return out
end

function P.first(records, test)
	for _, record in ipairs(records) do
		if test(record.item) then return record end
	end
end

-- One record per tool kind (BF_Sewage.tests).
function P.tools(records)
	local tools = {}
	for kind, test in pairs(BF_Sewage.tests) do tools[kind] = P.first(records, test) end
	return tools
end

local function fetch(character, record)
	local inv, item = character:getInventory(), record.item
	if inv:contains(item) then return end
	if record.world then
		local world = item:getWorldItem()
		if world and world:getSquare() and luautils.walkAdj(character, world:getSquare(), true) then
			ISTimedActionQueue.add(ISGrabItemAction:new(character, world, ISWorldObjectContextMenu.grabItemTime(character, world)))
		end
	elseif record.container:contains(item) then
		if record.square and not luautils.walkAdj(character, record.square, true) then return end
		ISTimedActionQueue.add(ISInventoryTransferUtil.newInventoryTransferAction(character, item, record.container, inv))
	end
end

local function giveBack(player, record)
	if record.world then
		ISCraftingUI.ReturnItemToContainer(player, record.item, ISInventoryPage.GetFloorContainer(player:getPlayerNum()))
	elseif not record.square then
		ISCraftingUI.ReturnItemToContainer(player, record.item, record.container)
	else
		ISTimedActionQueue.add(BF_SupplyStep:new(player, function(character)
			if not character:getInventory():contains(record.item) then return end
			if luautils.walkAdj(character, record.square, true) then
				ISCraftingUI.ReturnItemToContainer(character, record.item, record.container)
			end
		end))
	end
end

-- Queues fetching the records that are not in the main inventory, then work(), then their return unless keep.
function P.queue(player, records, work, keep)
	local away = {}
	for _, record in ipairs(records) do
		if record.container ~= player:getInventory() then away[#away + 1] = record end
	end
	if #away == 0 then return work(player) end
	for _, record in ipairs(away) do
		ISTimedActionQueue.add(BF_SupplyStep:new(player, function(character) fetch(character, record) end))
	end
	ISTimedActionQueue.add(BF_SupplyStep:new(player, work))
	if keep then return end
	for _, record in ipairs(away) do giveBack(player, record) end
end

return P