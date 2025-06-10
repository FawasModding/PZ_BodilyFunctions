if not BF_FecalFootprints then
    BF_FecalFootprints = {}
end

-- Configuration
BF_FecalFootprints.Config = {
    enablePlayerFootsteps = true,  -- Toggle for player footprints
    enableZombieFootsteps = true,  -- Toggle for zombie footprints
    maxFootprints = 200,          -- Max footprints displayed
    footprintLifespan = 4500,     -- Footprint duration (seconds)
    zombieMaxDistance = 25,       -- Max distance for zombie footprints
    zombieCheckInterval = 120,    -- Zombie footprint check interval (ms)
    zombieBatchSize = 12,         -- Zombies processed per cycle
    zombieProcessFrequency = 2,   -- Process zombies every X ticks
    fecesSteps = 5                -- Steps after stepping in feces
}

-- Footprint tile sprites
BF_FecalFootprints.FOOTPRINT_TILES = {
    [0] = {left = "fecal_footsteps_8", right = "fecal_footsteps_0"},
    [1] = {left = "fecal_footsteps_1", right = "fecal_footsteps_9"},
    [2] = {left = "fecal_footsteps_24", right = "fecal_footsteps_16"},
    [3] = {left = "fecal_footsteps_9", right = "fecal_footsteps_1"},
    [4] = {left = "fecal_footsteps_10", right = "fecal_footsteps_2"},
    [5] = {left = "fecal_footsteps_2", right = "fecal_footsteps_10"},
    [6] = {left = "fecal_footsteps_11", right = "fecal_footsteps_3"},
    [7] = {left = "fecal_footsteps_3", right = "fecal_footsteps_11"},
}

-- State management
BF_FecalFootprints.State = {
    placedFootprints = {},      -- Track active footprints
    footprintQueue = {},        -- Queue for footprint management
    zombieLastPositions = {},   -- Last known zombie positions
    lastSquare = nil,           -- Last player square
    isLeftStep = true,          -- Alternates left/right for player
    playerTimer = 0,            -- Player footprint timer
    zombieTimer = 0,            -- Zombie footprint timer
    cleanupTimer = 0,           -- Cleanup timer
    cleanupIndex = 1,           -- Cleanup queue index
    lastCleanupTime = 0,        -- Last cleanup timestamp
    zombieIndex = 0,            -- Current zombie processing index
    lastTickProcessed = 0,      -- Last zombie processing tick
    playerFecesSteps = 0,       -- Player feces steps
    zombieFecesSteps = {}       -- Zombie feces steps (by zombie ID)
}

-- Utility functions
BF_FecalFootprints.GetMovementDirection = function(lastSquare, square)
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

BF_FecalFootprints.GetZombieID = function(zombie)
    local id = zombie:getID() or zombie:getOnlineID() or -1
    if id > 0 then return tostring(id) end
    return tostring(zombie:getX()) .. "_" .. tostring(zombie:getY())
end

BF_FecalFootprints.HasFecesOnSquare = function(square)
    if not square then return false end
    for i = 0, square:getObjects():size() - 1 do
        local object = square:getObjects():get(i)
        local objectContainer = object:getContainer()
        if object and object:getObjectName() == "WorldInventoryItem" then
            local item = object:getItem()
            if item and item:hasTag("BFHumanFeces") then return true end
        elseif objectContainer and objectContainer:getCountTagRecurse("BFHumanFeces") > 0 then
            return true
        end
    end
    return false
end

-- Footprint management
BF_FecalFootprints.CreateFootprint = function(square, direction, isLeftStep, isZombie, entityID)
    if not square or not BF_FecalFootprints.FOOTPRINT_TILES[direction] then return end
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local key = x * 10000 + y * 10 + z
    if BF_FecalFootprints.State.placedFootprints[key] then return end

    local side = isLeftStep and "left" or "right"
    local tile = BF_FecalFootprints.FOOTPRINT_TILES[direction][side]
    if not tile then return end

    local footprint = IsoObject.new(square, tile, "footprint", false)
    if getWorld():getGameMode() == "Multiplayer" then
        square:transmitAddObjectToSquare(footprint, 1)
    else
        square:AddTileObject(footprint)
    end

    BF_FecalFootprints.State.placedFootprints[key] = { footprint = footprint, square = square, time = getGameTime():getWorldAgeHours() * 3600 }
    table.insert(BF_FecalFootprints.State.footprintQueue, key)

    if #BF_FecalFootprints.State.footprintQueue > BF_FecalFootprints.Config.maxFootprints then
        BF_FecalFootprints.RemoveFootprint(table.remove(BF_FecalFootprints.State.footprintQueue, 1))
    end

    if not isZombie then
        BF_FecalFootprints.State.isLeftStep = not BF_FecalFootprints.State.isLeftStep
    end
end

BF_FecalFootprints.RemoveFootprint = function(key)
    local data = BF_FecalFootprints.State.placedFootprints[key]
    if not data or not data.square or not data.footprint then return end
    data.square:RemoveTileObject(data.footprint)
    BF_FecalFootprints.State.placedFootprints[key] = nil
end

-- Player footprint handling
BF_FecalFootprints.AddPlayerFootprints = function()
    if not BF_FecalFootprints.Config.enablePlayerFootsteps then return end

    local player = getSpecificPlayer(0)
    if not player or player:getVehicle() then
        BF_FecalFootprints.State.lastSquare = player and player:getSquare()
        return
    end

    local square = player:getSquare()
    if not square or square == BF_FecalFootprints.State.lastSquare then return end

    -- Check for feces on player's current square
    if BF_FecalFootprints.HasFecesOnSquare(square) then
        BF_FecalFootprints.State.playerFecesSteps = BF_FecalFootprints.Config.fecesSteps
    end

    if BF_FecalFootprints.State.playerFecesSteps > 0 then
        local direction = BF_FecalFootprints.GetMovementDirection(BF_FecalFootprints.State.lastSquare, square)
        if direction then
            BF_FecalFootprints.CreateFootprint(square, direction, BF_FecalFootprints.State.isLeftStep, false, nil)
            BF_FecalFootprints.State.playerFecesSteps = BF_FecalFootprints.State.playerFecesSteps - 1
        end
    end

    BF_FecalFootprints.State.lastSquare = square
end

-- Zombie footprint handling
BF_FecalFootprints.AddZombieFootprints = function()
    if not BF_FecalFootprints.Config.enableZombieFootsteps then return end

    local gameTime = getGameTime()
    BF_FecalFootprints.State.zombieTimer = BF_FecalFootprints.State.zombieTimer + gameTime:getTimeDelta() * 1000
    if BF_FecalFootprints.State.zombieTimer < BF_FecalFootprints.Config.zombieCheckInterval then return end
    BF_FecalFootprints.State.zombieTimer = 0

    local player = getSpecificPlayer(0)
    local cell = getCell()
    if not player or not cell then return end

    local zombieList = cell:getZombieList()
    if not zombieList or zombieList:size() == 0 then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local playerX, playerY = playerSquare:getX(), playerSquare:getY()
    local tick = gameTime:getWorldAgeHours() * 3600
    if tick - BF_FecalFootprints.State.lastTickProcessed < BF_FecalFootprints.Config.zombieProcessFrequency then return end
    BF_FecalFootprints.State.lastTickProcessed = tick

    local zombieCount = zombieList:size()
    local zombiesProcessed = 0
    local startIndex = BF_FecalFootprints.State.zombieIndex

    while zombiesProcessed < BF_FecalFootprints.Config.zombieBatchSize do
        if BF_FecalFootprints.State.zombieIndex >= zombieCount then
            BF_FecalFootprints.State.zombieIndex = 0
            if startIndex == 0 then break end
        end

        local zombie = zombieList:get(BF_FecalFootprints.State.zombieIndex)
        BF_FecalFootprints.State.zombieIndex = BF_FecalFootprints.State.zombieIndex + 1

        if zombie and not zombie:isDead() then
            local zombieSquare = zombie:getSquare()
            if zombieSquare then
                local zombieX, zombieY = zombieSquare:getX(), zombieSquare:getY()
                local distanceSquared = (playerX - zombieX)^2 + (playerY - zombieY)^2
                if distanceSquared <= BF_FecalFootprints.Config.zombieMaxDistance^2 then
                    local zombieID = BF_FecalFootprints.GetZombieID(zombie)
                    local lastPos = BF_FecalFootprints.State.zombieLastPositions[zombieID]
                    BF_FecalFootprints.State.zombieLastPositions[zombieID] = zombieSquare

                    -- Check for feces on zombie's current square
                    if BF_FecalFootprints.HasFecesOnSquare(zombieSquare) then
                        BF_FecalFootprints.State.zombieFecesSteps[zombieID] = BF_FecalFootprints.Config.fecesSteps
                    end

                    if BF_FecalFootprints.State.zombieFecesSteps[zombieID] and BF_FecalFootprints.State.zombieFecesSteps[zombieID] > 0 then
                        if lastPos and (lastPos:getX() ~= zombieX or lastPos:getY() ~= zombieY) then
                            local direction = BF_FecalFootprints.GetMovementDirection(lastPos, zombieSquare)
                            if direction then
                                BF_FecalFootprints.CreateFootprint(zombieSquare, direction, ZombRand(2) == 0, true, zombieID)
                                BF_FecalFootprints.State.zombieFecesSteps[zombieID] = BF_FecalFootprints.State.zombieFecesSteps[zombieID] - 1
                            end
                        end
                    else
                        BF_FecalFootprints.State.zombieFecesSteps[zombieID] = nil
                    end
                else
                    BF_FecalFootprints.State.zombieLastPositions[zombieID] = nil
                    BF_FecalFootprints.State.zombieFecesSteps[zombieID] = nil
                end
            end
        end

        zombiesProcessed = zombiesProcessed + 1
        if BF_FecalFootprints.State.zombieIndex == startIndex then break end
    end
end

-- Cleanup
BF_FecalFootprints.CleanupFootprints = function()
    if not BF_FecalFootprints.Config.enablePlayerFootsteps and not BF_FecalFootprints.Config.enableZombieFootsteps then return end

    local gameTime = getGameTime()
    BF_FecalFootprints.State.cleanupTimer = BF_FecalFootprints.State.cleanupTimer + gameTime:getTimeDelta() * 1000
    if BF_FecalFootprints.State.cleanupTimer < 5000 then return end
    BF_FecalFootprints.State.cleanupTimer = 0

    local now = gameTime:getWorldAgeHours() * 3600
    if now - BF_FecalFootprints.State.lastCleanupTime < 60 then return end
    BF_FecalFootprints.State.lastCleanupTime = now

    local processed = 0
    local queueLength = #BF_FecalFootprints.State.footprintQueue
    while processed < 40 and BF_FecalFootprints.State.cleanupIndex <= queueLength do
        local key = BF_FecalFootprints.State.footprintQueue[BF_FecalFootprints.State.cleanupIndex]
        local data = BF_FecalFootprints.State.placedFootprints[key]
        if data and now - data.time > BF_FecalFootprints.Config.footprintLifespan then
            BF_FecalFootprints.RemoveFootprint(key)
            table.remove(BF_FecalFootprints.State.footprintQueue, BF_FecalFootprints.State.cleanupIndex)
            queueLength = queueLength - 1
        else
            BF_FecalFootprints.State.cleanupIndex = BF_FecalFootprints.State.cleanupIndex + 1
        end
        processed = processed + 1
    end
    if BF_FecalFootprints.State.cleanupIndex > queueLength then
        BF_FecalFootprints.State.cleanupIndex = 1
    end
end

-- Initialization
BF_FecalFootprints.OnGameStart = function()
    BF_FecalFootprints.State.lastSquare = nil
    BF_FecalFootprints.State.isLeftStep = true
    BF_FecalFootprints.State.playerFecesSteps = 0
    BF_FecalFootprints.State.zombieFecesSteps = {}
    BF_FecalFootprints.State.placedFootprints = {}
    BF_FecalFootprints.State.footprintQueue = {}
    BF_FecalFootprints.State.zombieLastPositions = {}
    BF_FecalFootprints.State.playerTimer = 0
    BF_FecalFootprints.State.zombieTimer = 0
    BF_FecalFootprints.State.cleanupTimer = 0
    BF_FecalFootprints.State.cleanupIndex = 1
    BF_FecalFootprints.State.lastCleanupTime = 0
    BF_FecalFootprints.State.zombieIndex = 0
    BF_FecalFootprints.State.lastTickProcessed = 0
    print("[FecalFootprints] Mod initialized with feces-based player and zombie support")
end

-- Event registration with conditional checks
BF_FecalFootprints.RegisterEvents = function()
    Events.OnGameStart.Add(BF_FecalFootprints.OnGameStart)

    -- Set local config bools based on sandbox settings
    local fecalFootprintsEnum = SandboxVars.BF.EnableFecalFootprints or 1
    if fecalFootprintsEnum == 1 then
        BF_FecalFootprints.Config.enablePlayerFootsteps = false
        BF_FecalFootprints.Config.enableZombieFootsteps = false
    end
    if fecalFootprintsEnum == 2 then
        BF_FecalFootprints.Config.enablePlayerFootsteps = true
        BF_FecalFootprints.Config.enableZombieFootsteps = false
    end
    if fecalFootprintsEnum == 3 then
        BF_FecalFootprints.Config.enablePlayerFootsteps = true
        BF_FecalFootprints.Config.enableZombieFootsteps = true
    end

    -- Apply functionality based on config bools
    if BF_FecalFootprints.Config.enablePlayerFootsteps then
        Events.OnPlayerMove.Add(BF_FecalFootprints.AddPlayerFootprints)
    end
    if BF_FecalFootprints.Config.enableZombieFootsteps then
        Events.OnTick.Add(BF_FecalFootprints.AddZombieFootprints)
    end
    if BF_FecalFootprints.Config.enablePlayerFootsteps or BF_FecalFootprints.Config.enableZombieFootsteps then
        Events.OnTick.Add(BF_FecalFootprints.CleanupFootprints)
    end
end

BF_FecalFootprints.RegisterEvents()