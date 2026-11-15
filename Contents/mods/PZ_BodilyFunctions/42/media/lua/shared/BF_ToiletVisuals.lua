-- =====================================================
--
-- BF_ToiletVisuals
--
-- Drawn stains on dirty toilets, in three stages as dirt reaches 30, 60 and 90.
-- Vanilla toilets and chemical toilets use the bfp_stains_01 sheet, wooden
-- seats their own masks from bfp_sanitation_01. Any other toilet gets a brown
-- tint of its own sprite.
--
-- The depth textures for these overlays are listed in
-- common/media/tileDepthTextureAssignments.txt and assigned on game start.
--
-- =====================================================

BF_ToiletVisuals = {}
local V = BF_ToiletVisuals

V.wooden = { "fixtures_bathroom_02_24", "fixtures_bathroom_02_25", "fixtures_bathroom_02_26", "fixtures_bathroom_02_27" }
V.chemical = { "fixtures_bathroom_02_4", "fixtures_bathroom_02_5", "fixtures_bathroom_02_14", "fixtures_bathroom_02_15" }
-- Toilet sprites with drawn stains, by their place in the bfp_stains_01 sheet.
V.stained = {}
for i = 0, 11 do V.stained["fixtures_bathroom_01_" .. i] = i end
for n, name in ipairs(V.chemical) do V.stained[name] = 11 + n end

function V.stage(dirt)
	return dirt >= 90 and 3 or (dirt >= 60 and 2 or (dirt >= 30 and 1 or 0))
end

-- Wooden seat stain, by the seat's place in V.wooden (0-3).
function V.dirt(facing, stage)
	return "bfp_sanitation_01_" .. (facing * 3 + stage + 1)
end

function V.stain(index, stage)
	return "bfp_stains_01_" .. (index * 3 + stage - 1)
end

-- This mod's ID as registered in the game, for the depth texture assignments.
local function modId()
	local mods = getActivatedMods()
	for i = 0, mods:size() - 1 do
		local id = mods:get(i)
		local info = getModInfoByID(id)
		local dir = info and info:getDir()
		if dir and string.find(dir, "PZ_BodilyFunctions", 1, true) then return id end
	end
	return "bodilyfunctionsdev"
end

function V.bindDepth()
	local manager = TileDepthTextureAssignmentManager.getInstance()
	local id = modId()
	for facing = 0, 3 do
		for stage = 1, 3 do
			manager:assignDepthTextureToSprite(id, V.dirt(facing, stage))
		end
	end
	for _, index in pairs(V.stained) do
		for stage = 1, 3 do
			manager:assignDepthTextureToSprite(id, V.stain(index, stage))
		end
	end
end

-- Shows the stain for a dirt stage (0 = clean). transmit sends it to clients.
function V.apply(obj, stage, transmit)
	local sprite = obj:getSprite()
	if not sprite then return end
	local md = obj:getModData()
	if stage == 0 then
		if md.bfpDirtOverlay then
			obj:setOverlaySprite(nil, 1, 1, 1, 1, transmit)
			md.bfpDirtOverlay = nil
		end
		return
	end
	local name = sprite:getName()
	for facing, original in ipairs(V.wooden) do
		if name == original then
			obj:setOverlaySprite(V.dirt(facing - 1, stage), 1, 1, 1, 1, transmit)
			md.bfpDirtOverlay = true
			return
		end
	end
	local index = V.stained[name]
	if index then
		obj:setOverlaySprite(V.stain(index, stage), 1, 1, 1, 1, transmit)
		md.bfpDirtOverlay = true
		return
	end
	obj:setOverlaySprite(name, 0.4, 0.27, 0.1, stage * 0.19, transmit)
	md.bfpDirtOverlay = true
end

Events.OnGameStart.Add(V.bindDepth)

return V