-- =====================================================
--
-- BF_PuddleActions
--
-- One right-click entry per puddle, "Clean up urine/sewage/vomit", with the
-- cleaning methods in its submenu:
--   * scrub with a sponge or toilet brush and cleaner (any puddle)
--   * wipe with a wiping item and soap (urine puddles, BF_PuddleWipe)
--   * cover with soil using a shovel (puddles on soil)
-- A method that can't be used is disabled with a short reason.
--
-- =====================================================

require "BF_Sewage"
require "BF_PuddleWipe"
require "TimedActions/BF_CleanPuddle"
require "_Shared/Utils/BF_Supplies"
require "_Shared/Player/TimedActions/Wipe/BF_WipePuddle"

local W = BF_Sewage

local ICONS = {
	clean = "media/textures/BF_Icon_CleanSpill.png",
	bury = "media/textures/BF_Icon_Bury.png",
}

-- Tool kinds each operation needs.
local NEEDS = { clean = { "brush", "cleaner" }, bury = { "shovel" } }

local function queueJob(player, puddle, operation)
	local records = BF_Supplies.records(player, puddle:getSquare())
	local tools = BF_Supplies.tools(records)
	local borrowed = {}
	for _, kind in ipairs(NEEDS[operation]) do borrowed[#borrowed + 1] = tools[kind] end
	BF_Supplies.queue(player, borrowed, function(character)
		if luautils.walkAdj(character, puddle:getSquare(), true) then
			ISTimedActionQueue.add(BF_CleanPuddle:new(character, puddle, operation))
		end
	end)
end

local function wipePuddle(player, puddle, wipeType, itemType)
	if luautils.walkAdj(player, puddle:getSquare(), true) then
		ISTimedActionQueue.add(BF_WipePuddle:new(player, puddle, wipeType, itemType))
	end
end

-- Why scrubbing can't be done, as a translation key, or nil.
local function scrubProblem(records, tools)
	if not tools.brush then return "ContextMenu_BF_NoBrush" end
	if tools.cleaner then return nil end
	for _, record in ipairs(records) do
		local share = W.agentShare(record.item:getFluidContainer(), W.cleaningAgents())
		if share and share > 0 then
			return share < W.MIX_SHARE and "ContextMenu_BF_WeakMix" or "ContextMenu_BF_LittleCleaner"
		end
	end
	return "ContextMenu_BF_NoCleaner"
end

local function greyOut(option, key)
	option.notAvailable = true
	BF.AddTooltip(option, getText(key))
end

local function addWipeEntries(menu, player, puddle)
	local P = BF_PuddleWipe
	local liters = W.volume(puddle)
	local records = BF.BuildReachableItemRecords(player)
	local hasSoap = P.soapAvailable(records) > 0
	for _, opt in ipairs(BF.CollectWipeables(player)) do
		if opt.wipeType ~= "usingBook" then
			local itemType = opt.item:getType()
			local share = P.share(records, opt.wipeType, itemType, liters)
			local label = opt.label or (getText("ContextMenu_WipeWith") .. " " .. opt.item:getName())
			local entry = menu:addOption(label .. " (" .. math.floor(share * 100) .. "%)", player, wipePuddle,
				puddle, opt.wipeType, itemType)
			entry.itemForTexture = opt.item
			if not hasSoap then
				greyOut(entry, "ContextMenu_BF_NoSoap")
			elseif share <= 0 then
				entry.notAvailable = true
			end
		end
	end
end

local function addCleanUpMenu(context, player, puddle)
	local square = puddle:getSquare()
	local records = BF_Supplies.records(player, square)
	local tools = BF_Supplies.tools(records)

	local top = context:addOption(getText("ContextMenu_BF_CleanUp_" .. W.kindOf(puddle)))
	top.iconTexture = getTexture(ICONS.clean)
	local menu = ISContextMenu:getNew(context)
	context:addSubMenu(top, menu)

	local scrub = menu:addOption(getText("ContextMenu_BF_ScrubCleaner"), player, queueJob, puddle, "clean")
	scrub.iconTexture = getTexture(ICONS.clean)
	local problem = scrubProblem(records, tools)
	if problem then greyOut(scrub, problem) end

	if BF_PuddleWipe.canWipe(puddle) then addWipeEntries(menu, player, puddle) end

	if W.onSoil(square) then
		local bury = menu:addOption(getText("ContextMenu_BF_CoverSoil"), player, queueJob, puddle, "bury")
		bury.iconTexture = getTexture(ICONS.bury)
		if not tools.shovel then greyOut(bury, "ContextMenu_BF_NoShovel") end
	end
end

local function onMenu(playerNum, context, worldObjects, test)
	if test then return end
	local player = getSpecificPlayer(playerNum)
	if not player then return end
	local visited = {}
	for _, obj in ipairs(worldObjects or {}) do
		local square = obj:getSquare()
		if square and not visited[square] then
			visited[square] = true
			local puddle = W.puddle(square)
			if puddle then addCleanUpMenu(context, player, puddle) end
		end
	end
end

Events.OnFillWorldObjectContextMenu.Add(onMenu)