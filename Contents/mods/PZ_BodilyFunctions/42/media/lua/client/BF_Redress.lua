-- Undressing and re-dressing around relief.
--
-- Garments taken off are remembered by item id in modData.bfRedress until they
-- are worn again, so an interrupted action or a reload can't strand the
-- character undressed: the "Get Dressed" option picks the list back up.
--
-- modData.removedClothing is separate and short-lived. It holds the item objects
-- for the wiping penalty and doesn't survive a save.
require "TimedActions/ISBaseTimedAction"

BF = BF or {}

local COLOR_WORN = " <RGB:0.6,0.6,0.6> "
local COLOR_READY = " <RGB:0.5,1,0.5> "
local COLOR_MISSING = " <RGB:1,1,0.5> "

local function getPending(player)
	local list = player:getModData().bfRedress
	if type(list) ~= "table" or #list == 0 then return nil end
	return list
end

local function setPending(player, list)
	if list and #list == 0 then list = nil end
	player:getModData().bfRedress = list
	if isClient() then
		player:transmitModData()
	end
end

local function isWorn(player, item)
	return item ~= nil and player:isEquippedClothing(item)
end

function BF.RemoveBottomClothing(player)
	-- Every worn garment that gets in the way, tights and modded legwear included
	local removedClothing = BF.GetExcreteObstructiveWornItems(player)

	-- Take the outermost layers off first
	for i = #removedClothing, 1, -1 do
		ISTimedActionQueue.add(ISUnequipAction:new(player, removedClothing[i], 50))
	end

	player:getModData().removedClothing = removedClothing

	-- Merged with anything still pending from an earlier interrupted action.
	local list = getPending(player) or {}
	local known = {}
	for _, entry in ipairs(list) do
		known[entry.itemId] = true
	end
	for _, item in ipairs(removedClothing) do
		local id = item:getID()
		if not known[id] then
			list[#list + 1] = { itemId = id, fullType = item:getFullType(), displayName = item:getDisplayName() }
			known[id] = true
		end
	end
	setPending(player, list)
end

function BF.ResetRemovedClothing(player)
	player:getModData().removedClothing = nil
end

-- Clears the pending list once every garment on it is worn again.
BF_RedressComplete = ISBaseTimedAction:derive("BF_RedressComplete")

function BF_RedressComplete:isValid()
	return true
end

function BF_RedressComplete:perform()
	local list = getPending(self.character)
	if list then
		local inv = self.character:getInventory()
		local rest = {}
		for _, entry in ipairs(list) do
			local item = inv:getItemWithID(entry.itemId)
			if not isWorn(self.character, item) and not (item and item:isBroken()) then
				rest[#rest + 1] = entry
			end
		end
		setPending(self.character, rest)
	end
	ISBaseTimedAction.perform(self)
end

function BF_RedressComplete:new(character)
	local o = ISBaseTimedAction.new(self, character)
	o.maxTime = 0
	o.stopOnWalk = false
	o.stopOnRun = false
	return o
end

local function isRedressQueued(player)
	local queue = ISTimedActionQueue.getTimedActionQueue(player).queue
	for _, action in ipairs(queue) do
		if action.Type == "BF_RedressComplete" then return true end
	end
	return false
end

-- Queues wearing every pending garment in the inventory, then the completion
-- check. Safe to call repeatedly: a relief action calls this when it ends, and
-- wearing something already worn would replay the whole animation.
function BF.ReequipBottomClothing(player)
	local list = getPending(player)
	if not list or isRedressQueued(player) then return end

	local inv = player:getInventory()
	for _, entry in ipairs(list) do
		local item = inv:getItemWithID(entry.itemId)
		if item and not item:isBroken() and not isWorn(player, item) then
			ISTimedActionQueue.add(ISWearClothing:new(player, item))
		end
	end
	ISTimedActionQueue.add(BF_RedressComplete:new(player))
end

local function onRedress(player)
	BF.ReequipBottomClothing(player)
end

local function onForget(player)
	setPending(player, nil)
end

-- "Get Dressed" option while a pending list remains and nothing is queued.
local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
	if test then return end
	local player = getSpecificPlayer(playerNum)
	if not player or player:isDead() then return end

	local list = getPending(player)
	if not list or ISTimedActionQueue.isPlayerDoingAction(player) then return end

	local inv = player:getInventory()
	local lines = {}
	local anyToWear = false
	local allPresent = true
	for _, entry in ipairs(list) do
		local item = inv:getItemWithID(entry.itemId)
		local color = COLOR_READY
		if not item then
			color = COLOR_MISSING
			allPresent = false
		elseif isWorn(player, item) then
			color = COLOR_WORN
		else
			anyToWear = true
		end
		lines[#lines + 1] = color .. tostring(entry.displayName)
	end

	-- Everything was put back on some other way.
	if not anyToWear and allPresent then
		setPending(player, nil)
		return
	end

	local option = context:addOption(getText("ContextMenu_BF_Redress"), player, onRedress)
	local tooltip = ISWorldObjectContextMenu.addToolTip()
	tooltip.description = getText("ContextMenu_BF_Redress_tooltip") .. " <LINE> <LINE> " .. table.concat(lines, " <LINE> ")
	option.toolTip = tooltip

	local subMenu = ISContextMenu:getNew(context)
	context:addSubMenu(option, subMenu)
	subMenu:addOption(getText("ContextMenu_BF_RedressForget"), player, onForget)
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
