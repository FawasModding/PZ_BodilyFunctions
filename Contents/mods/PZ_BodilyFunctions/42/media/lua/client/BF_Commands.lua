-- Client side of server/BF_ServerCommands.lua: sends requests and routes each
-- reply back to whatever "asked".

BF = BF or {}

local MODULE = "BF"

local pendingCallbacks = {}
local nextRequestId = 0

-- Sends a command that gets a reply. onResult(result) runs on the reply, one
-- round trip later, and only then is the item change visible on this client.
function BF.SendTrackedCommand(player, command, args, onResult)
    nextRequestId = nextRequestId + 1
    args.requestId = nextRequestId
    pendingCallbacks[nextRequestId] = onResult
    sendClientCommand(player, MODULE, command, args)
end

-- Called directly by the server file in single player, where sendServerCommand
-- does nothing, and through OnServerCommand in multiplayer.
function BF.OnCommandResult(result)
    BF.InvalidateReachableCache()

    if not result.ok and result.reason then
        local player = getPlayer()
        if player then
            HaloTextHelper.addBadText(player, getText(result.reason))
        end
    end

    local callback = pendingCallbacks[result.requestId]
    if callback then
        pendingCallbacks[result.requestId] = nil
        callback(result)
    end
end

-- kind is "pee" or "poop". The caller decides whether waste is due; the server
-- makes the item, because a world item a client adds is invisible to everyone else.
function BF.SpawnWaste(player, kind)
    sendClientCommand(player, MODULE, "spawnWaste", { kind = kind })
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
