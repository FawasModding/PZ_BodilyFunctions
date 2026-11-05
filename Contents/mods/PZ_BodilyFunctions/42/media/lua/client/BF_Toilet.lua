-- Toilet water and flushing: water check, "needs flush" flag after use, flush
-- action and menu option. The server owns the water and the flag.
require "TimedActions/ISBaseTimedAction"

BF_Toilet = {}

local function isLifestyleActive()
	local mods = getActivatedMods()
	return mods:contains("LifestyleHobbies") or mods:contains("\\LifestyleHobbies")
end

function BF_Toilet.hasFlushWater(obj)
	local use = BF.GetToiletWaterUse(obj)
	if not use then return true end
	return obj:hasWater() and obj:getFluidAmount() >= use
end

function BF_Toilet.isBlocked(obj)
	return SandboxVars.BF.ToiletRequiresWater ~= false and not BF_Toilet.hasFlushWater(obj)
end

function BF_Toilet.needsFlush(obj)
	local md = obj and obj:hasModData() and obj:getModData()
	return md and md.movableData and md.movableData.needFlush == true or false
end

local function send(player, command, obj)
	sendClientCommand(player, "BF", command, {
		x = obj:getX(), y = obj:getY(), z = obj:getZ(), sprite = obj:getTextureName(),
	})
end

-- Called when a toilet relief action completes.
function BF_Toilet.markUsed(player, obj)
	if obj and BF.GetToiletWaterUse(obj) then
		send(player, "markFlush", obj)
	end
end

BF_FlushToilet = ISBaseTimedAction:derive("BF_FlushToilet")

function BF_FlushToilet:isValid()
	return self.toilet ~= nil and self.toilet:getSquare() ~= nil and BF_Toilet.hasFlushWater(self.toilet)
end

function BF_FlushToilet:waitToStart()
	self.character:faceThisObject(self.toilet)
	return self.character:shouldBeTurning()
end

function BF_FlushToilet:update()
	self.character:faceThisObject(self.toilet)
end

function BF_FlushToilet:start()
	self:setActionAnim("Loot")
	self:setAnimVariable("LootPosition", "Mid")
end

function BF_FlushToilet:stop()
	ISBaseTimedAction.stop(self)
end

function BF_FlushToilet:perform()
	self.character:getEmitter():playSound("BF_Toilet_Flush")
	send(self.character, "flush", self.toilet)
	ISBaseTimedAction.perform(self)
end

function BF_FlushToilet:new(character, toilet)
	local o = ISBaseTimedAction.new(self, character)
	o.toilet = toilet
	o.maxTime = 40
	return o
end

local function onFlush(player, toilet)
	if luautils.walkAdj(player, toilet:getSquare(), true) then
		ISTimedActionQueue.add(BF_FlushToilet:new(player, toilet))
	end
end

-- "Flush toilet" option; left to Lifestyle's own menu when Lifestyle is active.
local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
	if test or isLifestyleActive() then return end
	local player = getSpecificPlayer(playerNum)
	local first = worldObjects and worldObjects[1]
	local square = first and first:getSquare()
	if not player or not square then return end

	local objects = square:getObjects()
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		if BF.GetToiletWaterUse(obj) and BF_Toilet.needsFlush(obj) then
			local menu = BF.FindToiletSubMenu(context) or context
			local option = menu:addOption(getText("ContextMenu_FlushToilet"), player, onFlush, obj)
			option.iconTexture = getTexture("media/textures/ContextMenuToilet.png")
			if not BF_Toilet.hasFlushWater(obj) then
				option.notAvailable = true
				BF.AddTooltip(option, getText("ContextMenu_BF_NoWater"))
			end
			return
		end
	end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
