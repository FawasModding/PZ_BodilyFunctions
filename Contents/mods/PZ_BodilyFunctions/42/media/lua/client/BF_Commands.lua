-- Client side of server/BF_ServerCommands.lua: sends requests and routes each
-- reply back to whatever "asked".

require "BF_Waste"

BF = BF or {}

local MODULE = "BF"

local pendingCallbacks = {}
-- Who sent each request, so an error shows over the right split-screen player.
local pendingPlayers = {}
local nextRequestId = 0

-- Sends a command that gets a reply. onResult(result) runs on the reply, one
-- round trip later, and only then is the item change visible on this client.
function BF.SendTrackedCommand(player, command, args, onResult)
    nextRequestId = nextRequestId + 1
    args.requestId = nextRequestId
    pendingCallbacks[nextRequestId] = onResult
    pendingPlayers[nextRequestId] = player
    sendClientCommand(player, MODULE, command, args)
end

-- Called directly by the server file in single player, where sendServerCommand
-- does nothing, and through OnServerCommand in multiplayer.
function BF.OnCommandResult(result)
    BF.InvalidateReachableCache()

    local player = pendingPlayers[result.requestId] or getPlayer()
    pendingPlayers[result.requestId] = nil

    if not result.ok and result.reason and player then
        HaloTextHelper.addBadText(player, getText(result.reason))
    end

    local callback = pendingCallbacks[result.requestId]
    if callback then
        pendingCallbacks[result.requestId] = nil
        callback(result)
    end
end

-- kind is "pee" or "poop". The caller decides whether waste is due; the server
-- makes the puddle or pile, because a world object a client adds is invisible to
-- everyone else.
--   pee:  a urine puddle on square (default: the character's), bladderValue / 1000
--         liters (0.1-1.5). bladderValue defaults to the current urinateValue, which
--         is near 0 once a relief action has run, so actions pass their start value.
--   poop: a feces pile exactly where the character stands.
function BF.SpawnWaste(player, kind, bladderValue, square)
    local args = { kind = kind }
    if kind == "pee" then
        square = square or player:getCurrentSquare()
        args.liters = BF_Waste.liters(bladderValue or player:getModData().urinateValue)
    else
        square = player:getCurrentSquare()
        if square then
            args.fx = player:getX() - square:getX()
            args.fy = player:getY() - square:getY()
        end
    end
    if not square then return end
    args.x, args.y, args.z = square:getX(), square:getY(), square:getZ()
    sendClientCommand(player, MODULE, "spawnWaste", args)
end

-- Whether this fixture is a dumpster or trash can, which keeps what goes in it.
function BF.IsWasteBin(object)
    local sprite = object and object:getTextureName()
    if not sprite then return false end
    return BF_ReliefTiles.GetDumpsterTiles()[sprite] == true
        or BF_ReliefTiles.GetTrashCanTiles()[sprite] == true
end

-- Puts a waste item into a dumpster or trash can. The server finds the container
-- and makes the item, for the same reason as SpawnWaste.
function BF.DepositWaste(player, fixture, kind)
    local square = fixture:getSquare()
    if not square then return end
    sendClientCommand(player, MODULE, "depositWaste", {
        kind = kind,
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        sprite = fixture:getTextureName(),
    })
end

-- Arguments shared by every wash request. The cleaner is left out for rags and
-- towels, which don't use one.
function BF.BuildWashArgs(item, cleaner, waterSource)
    local square = waterSource:getSquare()
    return {
        itemId = item:getID(),
        cleanerId = cleaner and cleaner:getID() or nil,
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        sprite = waterSource:getTextureName(),
    }
end

local function onServerCommand(module, command, args)
    if module == MODULE and command == "result" and type(args) == "table" then
        BF.OnCommandResult(args)
    end
end

Events.OnServerCommand.Add(onServerCommand)
