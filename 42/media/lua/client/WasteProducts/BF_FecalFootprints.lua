if not BF_FecalFootprints then
    BF_FecalFootprints = {}
end

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

BF_FecalFootprints.CreateFootprint = function(character, direction, isLeftStep)
    if character:getVehicle() then return end

    local square = getCell():getGridSquare(character:getX(), character:getY(), character:getZ())
    if not square then return end

    local side = isLeftStep and "left" or "right"
    local tile = BF_FecalFootprints.FOOTPRINT_TILES[direction] and BF_FecalFootprints.FOOTPRINT_TILES[direction][side]
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

BF_FecalFootprints.OnPlayerMove = function()
    local player = getSpecificPlayer(0)
    if not player or not BF_FecalFootprints.lastSquare then
        BF_FecalFootprints.lastSquare = player and player:getSquare()
        return
    end

    local square = player:getSquare()
    if square == BF_FecalFootprints.lastSquare then return end

    local direction = BF_FecalFootprints.GetMovementDirection(BF_FecalFootprints.lastSquare, square)
    if direction then
        BF_FecalFootprints.CreateFootprint(player, direction, BF_FecalFootprints.isLeftStep)
        BF_FecalFootprints.isLeftStep = not BF_FecalFootprints.isLeftStep
    end

    BF_FecalFootprints.lastSquare = square
end

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

BF_FecalFootprints.OnGameStart = function()
    BF_FecalFootprints.lastSquare = nil
    BF_FecalFootprints.isLeftStep = true
end

Events.OnGameStart.Add(BF_FecalFootprints.OnGameStart)
Events.OnPlayerMove.Add(BF_FecalFootprints.OnPlayerMove)

print("[SnowFootprints] Mod initialized")