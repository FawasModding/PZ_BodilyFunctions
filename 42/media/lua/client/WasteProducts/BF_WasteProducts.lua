local BF_WasteProducts = {}

BF_WasteProducts.wasteProductSquares = {}

BF_WasteProducts.ScanNearbyForWaste = function()
    local fecesAmount = 0
    local lastFecesSquare = nil
    local insertedInTable = false
    local player = getPlayer()  -- using getPlayer()  for singleplayer

    for x = -2, 2 do
        for y = -2, 2 do
            local sq = getCell():getGridSquare(player:getX() + x, player:getY() + y, player:getZ())
            insertedInTable = false

            if sq then
                for i = 0, sq:getObjects():size() - 1 do
                    local object = sq:getObjects():get(i)
                    local objectContainer = object:getContainer()

                    if (object ~= nil and object:getObjectName() == "WorldInventoryItem" and object:getItem():getType() == "HumanFeces") then
                        fecesAmount = fecesAmount + 1
                        lastFecesSquare = sq
                        if sq == player:getSquare() then
                            BF_FecalFootprints.fecesSteps = 5
                        end
                    elseif (object ~= nil and objectContainer ~= nil) then
                        fecesAmount = fecesAmount + objectContainer:getCountTypeRecurse("HumanFeces")
                        lastFecesSquare = sq
                        if sq == player:getSquare() then
                            BF_FecalFootprints.fecesSteps = 5
                        end
                    end

                    if (fecesAmount > 0) then
                        BF_WasteProducts.ApplyWasteExposureEffects(lastFecesSquare, fecesAmount)
                        fecesAmount = 0
                        insertedInTable = true
                    end
                end
            end
        end
    end

    local playerInventory = player:getInventory()
    if (not insertedInTable and playerInventory:getCountType("HumanFeces") > 0) then
        fecesAmount = fecesAmount + playerInventory:getCountType("HumanFeces")
        -- Apply exposure effects without setting lastFecesSquare to player's square
        BF_WasteProducts.ApplyWasteExposureEffects(player:getSquare(), fecesAmount)
    end
end

BF_WasteProducts.ApplyWasteExposureEffects = function(lastFecesSquare, fecesAmount)
    local player = getPlayer()   -- using getPlayer()  for singleplayer

    local foodSicknessLevel = player:getBodyDamage():getFoodSicknessLevel()
    if (foodSicknessLevel < 50) then -- cap at 50 (Nauseous)
        local foodSicknessToAdd = foodSicknessLevel + (0.1 * fecesAmount)
        player:getBodyDamage():setFoodSicknessLevel(foodSicknessToAdd)
    end

    -- 0.5 seems fine, most people could be in these conditions without becoming suicidal, but maybe it'll be raised eventually.
    player:getBodyDamage():setUnhappynessLevel(player:getBodyDamage():getUnhappynessLevel() + (0.05 * fecesAmount))

    -- Set bodily fumes moodle to 75 (stage 3 of 4)
    BF.SetBodilyFumesValue(75)

    if (not lastFecesSquare:hasFlies()) then
        lastFecesSquare:setHasFlies(true)
        table.insert(BF_WasteProducts.wasteProductSquares, lastFecesSquare)
    end

    if (#BF_WasteProducts.wasteProductSquares > 50) then
        BF_WasteProducts.wasteProductSquares[1]:setHasFlies(false)
        table.remove(BF_WasteProducts.wasteProductSquares, 1)
    end
end

BF_WasteProducts.UpdateWasteFlies = function()
    BF_WasteProducts.ScanNearbyForWaste()
    local player = getPlayer()   -- using getPlayer()  for singleplayer

    for i = #BF_WasteProducts.wasteProductSquares, 1, -1 do
        local fecesSquare = BF_WasteProducts.wasteProductSquares[i]
        local worldObjects = fecesSquare:getObjects()
        local fecesFound = false

        for j = 0, worldObjects:size() - 1 do
            local object = worldObjects:get(j)
            local objectContainer = object:getContainer()
            if (object ~= nil and object:getObjectName() == "WorldInventoryItem" and object:getItem():getType() == "HumanFeces") then
                fecesFound = true
                break
            elseif (object ~= nil and objectContainer ~= nil and objectContainer:getCountType("HumanFeces") > 0) then
                fecesFound = true
                break
            end
        end

        -- Only check inventory for flies if the square is the player's current square
        if (not fecesFound and player:getInventory():getCountType("HumanFeces") > 0 and fecesSquare:DistToProper(player:getSquare()) < 1) then
            fecesFound = true
        end

        if (fecesFound) then
            if ZombRand(6) == 0 and getGameTime():getTrueMultiplier() <= 5 then
                fecesSquare:playSound("BF_WasteFlies")
            end
        else
            table.remove(BF_WasteProducts.wasteProductSquares, i)
            fecesSquare:setHasFlies(false)
        end
    end
end

Events.EveryOneMinute.Add(BF_WasteProducts.UpdateWasteFlies)

print("[WasteProducts] Mod initialized")