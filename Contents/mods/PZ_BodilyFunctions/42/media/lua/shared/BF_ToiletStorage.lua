-- =====================================================
--
-- BF_ToiletStorage
--
-- With the ToiletStorage sandbox option on, each seated flush toilet gets a
-- real item container of type "bf_toilet" that shows in the loot window.
-- What goes into it and how flushing treats it is in BF_Toilets.
--
-- The container is added at runtime because a new container type can't be set
-- through a tile property from Lua. Toilet sprites are not changed.
--
-- The container is saved with the object, so each toilet only gets one once.
-- A toilet that already has a container is left alone.
--
-- Runs on singleplayer, server and client, like vanilla tile containers.

require "BF_Shared"

BF.ToiletContainerType = "bf_toilet"
BF.ToiletContainerCapacity = 10

-- The container's button icon in the loot window. A dedicated server draws no UI.
if not isServer() then
    require "Definitions/ContainerButtonIcons"
    ContainerButtonIcons[BF.ToiletContainerType] = getTexture("media/textures/ContextMenuToilet.png")
end

local function enabled()
    return SandboxVars.BF ~= nil and SandboxVars.BF.ToiletStorage == true
end

function BF.IsToilet(object)
    local sprite = object and object:getSprite()
    local props = sprite and sprite:getProperties()
    return props ~= nil and props:has("CustomName") and props:get("CustomName") == "Toilet"
end

-- Only seated flush toilets store items: not urinals ("Hanging"), chemical
-- toilets (they have a tank instead) or outhouse seats ("Wooden").
function BF.CanToiletStore(object)
    if not BF.IsToilet(object) then return false end
    local props = object:getSprite():getProperties()
    local group = props:has("GroupName") and props:get("GroupName") or "Low"
    return group == "Fancy" or group == "Low"
end

-- Returns true if a container was added.
function BF.AddToiletContainer(object)
    if not object or object:getContainer() or not BF.CanToiletStore(object) then return false end
    local square = object:getSquare()
    if not square then return false end

    local container = ItemContainer.new(BF.ToiletContainerType, square, object)
    container:setCapacity(BF.ToiletContainerCapacity)
    -- Marked as explored so vanilla loot spawning never fills it.
    container:setExplored(true)
    object:setContainer(container)
    return true
end

local function onLoadGridsquare(square)
    if not enabled() then return end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        BF.AddToiletContainer(objects:get(i))
    end
end

-- A toilet placed with the furniture pickup/place system. Vanilla triggers this
-- after the object is placed, on the side that placed it. On a server the
-- object has already been sent to clients by then and it is not sent again, so
-- clients see the container after the area reloads.
local function onObjectAdded(object)
    if not enabled() or isClient() then return end
    BF.AddToiletContainer(object)
end

Events.LoadGridsquare.Add(onLoadGridsquare)
Events.OnObjectAdded.Add(onObjectAdded)
