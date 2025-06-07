local FOOTPRINT_TILES = {
    [0] = {left = "fecal_footsteps_8", right = "fecal_footsteps_0"},
    [1] = {left = "fecal_footsteps_1", right = "fecal_footsteps_9"},
    [2] = {left = "fecal_footsteps_24", right = "fecal_footsteps_16"},
    [3] = {left = "fecal_footsteps_9", right = "fecal_footsteps_1"},
    [4] = {left = "fecal_footsteps_10", right = "fecal_footsteps_2"},
    [5] = {left = "fecal_footsteps_2", right = "fecal_footsteps_10"},
    [6] = {left = "fecal_footsteps_11", right = "fecal_footsteps_3"},
    [7] = {left = "fecal_footsteps_3", right = "fecal_footsteps_11"},
}

local DIRECTION_OFFSETS = {
    [0] = {x = 0,  y = 1},
    [1] = {x = -1, y = 0},
    [2] = {x = 0,  y = -1},
    [3] = {x = 1,  y = 0},
    [4] = {x = -1, y = 1},
    [5] = {x = 1,  y = -1},
    [6] = {x = 1,  y = 1},
    [7] = {x = -1, y = -1},
}

local placedFootprints = {}
local footprintQueue = {}
local MAX_FOOTPRINTS = 250
local footprintLifespan = 7200
local isLeftStep = true
local player = nil
local lastSquare = nil
local cell = nil

-- Timer-based approach from the first file
local FOOTPRINT_INTERVAL = 350  -- Time in milliseconds for footprint creation interval
local footprintTimer = 0
local cleanupTimer = 0
local CLEANUP_INTERVAL = 5000  -- Cleanup interval in milliseconds

-- Get current game time in ticks
local function getCurrentGameTime()
    return getGameTime():getWorldAgeHours() * 3600
end

local function getMovementDirection(lastSquare, square)
    if not lastSquare or not square then return nil end

    local dx = square:getX() - lastSquare:getX()
    local dy = square:getY() - lastSquare:getY()

    if dx == 0 and dy < 0 then return 0
    elseif dx > 0 and dy == 0 then return 1
    elseif dx == 0 and dy > 0 then return 2
    elseif dx < 0 and dy == 0 then return 3
    elseif dx > 0 and dy < 0 then return 4
    elseif dx < 0 and dy > 0 then return 5
    elseif dx > 0 and dy > 0 then return 6
    elseif dx < 0 and dy < 0 then return 7
    end
    return nil
end

-- Helper function to remove a footprint by key
local function removeFootprint(key)
    local data = placedFootprints[key]
    if data and data.square and data.square:getChunk() and data.footprint then
        data.square:RemoveTileObject(data.footprint)
    end
    placedFootprints[key] = nil
end

local function createFootprint(square, direction)
    if not square or not direction then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local key = x * 10000 + y * 10 + z

    if placedFootprints[key] then return end

    local side = isLeftStep and "left" or "right"
    local tile = FOOTPRINT_TILES[direction] and FOOTPRINT_TILES[direction][side]
    if not tile then return end

    local footprintSquare = cell:getGridSquare(x, y, z)
    if not footprintSquare then return end

    local footprint = IsoObject.new(footprintSquare, tile)
    if footprint then
        footprintSquare:AddTileObject(footprint)
        placedFootprints[key] = { 
            footprint = footprint, 
            square = footprintSquare, 
            time = getCurrentGameTime() 
        }
        footprintQueue[#footprintQueue + 1] = key  -- Use length to insert
        isLeftStep = not isLeftStep

        if #footprintQueue > MAX_FOOTPRINTS then
            local oldestKey = footprintQueue[1]
            table.remove(footprintQueue, 1)  -- Remove the first element
            removeFootprint(oldestKey)
        end
    end
end

-- Function to add footprints for the player with timer-based approach
local function addFootprint()
    footprintTimer = footprintTimer + getGameTime():getTimeDelta() * 1000  -- Convert to milliseconds
    if footprintTimer < FOOTPRINT_INTERVAL then return end
    footprintTimer = 0

    if not player then
        player = getSpecificPlayer(0)
        if not player then return end
    end

    if not cell then
        cell = getCell()
        if not cell then return end
    end

    local square = player:getSquare()
    if not square or square == lastSquare then return end

    if not lastSquare then
        lastSquare = square
        return
    end

    local direction = getMovementDirection(lastSquare, square)
    if not direction then
        lastSquare = square
        return
    end

    -- FIX: Instead of using predefined offsets, calculate exact movement vector
    -- Get the movement vector
    local dx = square:getX() - lastSquare:getX()
    local dy = square:getY() - lastSquare:getY()
    
    -- Calculate the position directly on player based on movement direction
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    
    local squareBehind = cell:getGridSquare(x, y, z)
    if squareBehind then
        createFootprint(squareBehind, direction)
    end

    lastSquare = square
end

-- Function to handle cleanup of expired footprints with timer-based approach
local function incrementalCleanup()
    cleanupTimer = cleanupTimer + getGameTime():getTimeDelta() * 1000  -- Convert to milliseconds
    if cleanupTimer < CLEANUP_INTERVAL then return end
    cleanupTimer = 0
    
    local now = getCurrentGameTime()

    for key, data in pairs(placedFootprints) do
        if data and data.square and data.square:getChunk() and data.footprint then
            if now - data.time > footprintLifespan then
                removeFootprint(key)
            end
        end
    end
end

-- Function to start the game
local function onGameStart()
    player = getSpecificPlayer(0)
    cell = getCell()
    placedFootprints = {}
    footprintQueue = {}
    lastSquare = nil
    isLeftStep = true
    footprintTimer = 0
    cleanupTimer = 0
end

-- Register events
Events.OnGameStart.Add(onGameStart)
Events.OnPlayerMove.Add(addFootprint)
Events.OnTick.Add(incrementalCleanup)

print("[FootprintMod] Snow Footprints Mod initialized")