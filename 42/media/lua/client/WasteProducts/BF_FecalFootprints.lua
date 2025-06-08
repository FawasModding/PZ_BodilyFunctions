if not SnowFootprints then
    SnowFootprints = {}
end

SnowFootprints.FOOTPRINT_TILES = {
    [0] = {left = "fecal_footsteps_8", right = "fecal_footsteps_0"},
    [1] = {left = "fecal_footsteps_1", right = "fecal_footsteps_9"},
    [2] = {left = "fecal_footsteps_24", right = "fecal_footsteps_16"},
    [3] = {left = "fecal_footsteps_9", right = "fecal_footsteps_1"},
    [4] = {left = "fecal_footsteps_10", right = "fecal_footsteps_2"},
    [5] = {left = "fecal_footsteps_2", right = "fecal_footsteps_10"},
    [6] = {left = "fecal_footsteps_11", right = "fecal_footsteps_3"},
    [7] = {left = "fecal_footsteps_3", right = "fecal_footsteps_11"},
}

SnowFootprints.CreateFootprint = function(character, direction, isLeftStep)
    if character:getVehicle() then return end

    local square = getCell():getGridSquare(character:getX(), character:getY(), character:getZ())
    if not square then return end

    local side = isLeftStep and "left" or "right"
    local tile = SnowFootprints.FOOTPRINT_TILES[direction] and SnowFootprints.FOOTPRINT_TILES[direction][side]
    if not tile then return end

    local isAlready = false
    for _, v in pairs(square:getLuaTileObjectList()) do
        if v:getName() == "footprint" then
            isAlready = true
            break
        end
    end

    if isAlready then return end

    local footprint = IsoObject.new(square, tile, "footprint", false)
    if getWorld():getGameMode() == "Multiplayer" then
        square:transmitAddObjectToSquare(footprint, 1)
    else
        square:AddTileObject(footprint)
    end
end

SnowFootprints.OnPlayerMove = function()
    local player = getSpecificPlayer(0)
    if not player or not SnowFootprints.lastSquare then
        SnowFootprints.lastSquare = player and player:getSquare()
        return
    end

    local square = player:getSquare()
    if square == SnowFootprints.lastSquare then return end

    local direction = SnowFootprints.GetMovementDirection(SnowFootprints.lastSquare, square)
    if direction then
        SnowFootprints.CreateFootprint(player, direction, SnowFootprints.isLeftStep)
        SnowFootprints.isLeftStep = not SnowFootprints.isLeftStep
    end

    SnowFootprints.lastSquare = square
end

SnowFootprints.GetMovementDirection = function(lastSquare, square)
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

SnowFootprints.OnGameStart = function()
    SnowFootprints.lastSquare = nil
    SnowFootprints.isLeftStep = true
end

Events.OnGameStart.Add(SnowFootprints.OnGameStart)
Events.OnPlayerMove.Add(SnowFootprints.OnPlayerMove)

print("[SnowFootprints] Mod initialized")