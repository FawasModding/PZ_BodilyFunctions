local BF_WasteProducts = {}

BF_WasteProducts.wasteProductSquares = {}

BF_WasteProducts.ScanNearbyForWaste = function()
    local wasteAmount = 0
    local lastWasteSquare = nil
    local insertedInTable = false
    local player = getPlayer()  -- using getPlayer() for singleplayer

    for x = -2, 2 do
        for y = -2, 2 do
            local sq = getCell():getGridSquare(player:getX() + x, player:getY() + y, player:getZ())
            insertedInTable = false

            if sq then
                for i = 0, sq:getObjects():size() - 1 do
                    local object = sq:getObjects():get(i)
                    local objectContainer = object:getContainer()

                    if object ~= nil and object:getObjectName() == "WorldInventoryItem" then
                        local item = object:getItem()
                        if item:hasTag("BFHumanFeces") or item:hasTag("BFHumanUrine") then
                            wasteAmount = wasteAmount + 1
                            lastWasteSquare = sq
                            if item:hasTag("BFHumanFeces") and sq == player:getSquare() then
                                BF_FecalFootprints.fecesSteps = 5
                            end
                        end
                    elseif object ~= nil and objectContainer ~= nil then
                        wasteAmount = wasteAmount + objectContainer:getCountTagRecurse("BFHumanFeces")
                        wasteAmount = wasteAmount + objectContainer:getCountTagRecurse("BFHumanUrine")
                        lastWasteSquare = sq
                        if objectContainer:getCountTagRecurse("BFHumanFeces") > 0 and sq == player:getSquare() then
                            BF_FecalFootprints.fecesSteps = 5
                        end
                    end

                    if wasteAmount > 0 then
                        BF_WasteProducts.ApplyWasteExposureEffects(lastWasteSquare, wasteAmount)
                        wasteAmount = 0
                        insertedInTable = true
                    end
                end
            end
        end
    end

    local playerInventory = player:getInventory()
    if not insertedInTable and (playerInventory:getCountTag("BFHumanFeces") > 0 or playerInventory:getCountTag("BFHumanUrine") > 0) then
        wasteAmount = wasteAmount + playerInventory:getCountTag("BFHumanFeces") + playerInventory:getCountTag("BFHumanUrine")
        BF_WasteProducts.ApplyWasteExposureEffects(player:getSquare(), wasteAmount)
    end
end

BF_WasteProducts.ApplyWasteExposureEffects = function(lastWasteSquare, wasteAmount)
    local player = getPlayer()   -- using getPlayer() for singleplayer

    local foodSicknessLevel = player:getBodyDamage():getFoodSicknessLevel()
    if foodSicknessLevel < 50 then -- cap at 50 (Nauseous)
        local foodSicknessToAdd = foodSicknessLevel + (0.1 * wasteAmount)
        player:getBodyDamage():setFoodSicknessLevel(foodSicknessToAdd)
    end

    player:getBodyDamage():setUnhappynessLevel(player:getBodyDamage():getUnhappynessLevel() + (0.05 * wasteAmount))

    -- Determine bodily fumes value based on waste types present
    local hasFeces = false
    local hasUrine = false
    if lastWasteSquare then
        for i = 0, lastWasteSquare:getObjects():size() - 1 do
            local object = lastWasteSquare:getObjects():get(i)
            local objectContainer = object:getContainer()
            if object ~= nil and object:getObjectName() == "WorldInventoryItem" then
                local item = object:getItem()
                if item:hasTag("BFHumanFeces") then
                    hasFeces = true
                elseif item:hasTag("BFHumanUrine") then
                    hasUrine = true
                end
            elseif object ~= nil and objectContainer ~= nil then
                if objectContainer:getCountTagRecurse("BFHumanFeces") > 0 then
                    hasFeces = true
                end
                if objectContainer:getCountTagRecurse("BFHumanUrine") > 0 then
                    hasUrine = true
                end
            end
        end
    end

    -- Check player inventory if no waste was found in the square
    if lastWasteSquare == player:getSquare() then
        local playerInventory = player:getInventory()
        if playerInventory:getCountTag("BFHumanFeces") > 0 then
            hasFeces = true
        end
        if playerInventory:getCountTag("BFHumanUrine") > 0 then
            hasUrine = true
        end
    end

    -- Set bodily fumes value: 75 for feces (or both), 40 for urine only
    if hasFeces then
        BF.SetBodilyFumesValue(75) -- Feces or both feces and urine
    elseif hasUrine then
        BF.SetBodilyFumesValue(40) -- Urine only
    end

    -- Only track HumanFeces for flies
    if lastWasteSquare and hasFeces and not lastWasteSquare:hasFlies() then
        lastWasteSquare:setHasFlies(true)
        table.insert(BF_WasteProducts.wasteProductSquares, lastWasteSquare)
    end

    if #BF_WasteProducts.wasteProductSquares > 50 then
        BF_WasteProducts.wasteProductSquares[1]:setHasFlies(false)
        table.remove(BF_WasteProducts.wasteProductSquares, 1)
    end
end

BF_WasteProducts.UpdateWasteFlies = function()
    BF_WasteProducts.ScanNearbyForWaste()
    local player = getPlayer()   -- using getPlayer() for singleplayer

    for i = #BF_WasteProducts.wasteProductSquares, 1, -1 do
        local fecesSquare = BF_WasteProducts.wasteProductSquares[i]
        local worldObjects = fecesSquare:getObjects()
        local fecesFound = false

        for j = 0, worldObjects:size() - 1 do
            local object = worldObjects:get(j)
            local objectContainer = object:getContainer()
            if object ~= nil and object:getObjectName() == "WorldInventoryItem" and object:getItem():hasTag("BFHumanFeces") then
                fecesFound = true
                break
            elseif object ~= nil and objectContainer ~= nil and objectContainer:getCountTagRecurse("BFHumanFeces") > 0 then
                fecesFound = true
                break
            end
        end

        if not fecesFound and player:getInventory():getCountTag("BFHumanFeces") > 0 and fecesSquare:DistToProper(player:getSquare()) < 1 then
            fecesFound = true
        end

        if fecesFound then
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