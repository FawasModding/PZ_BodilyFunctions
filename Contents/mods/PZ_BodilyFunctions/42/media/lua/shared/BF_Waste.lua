-- =====================================================
--
-- BF_Waste
--
-- Urine puddles and feces piles where relief happens. Called on the server (or in single player) by
-- BF_ServerCommands' spawnWaste; the client only sends the location.
--
-- =====================================================

require "BF_Sewage"

BF_Waste = {}
local X = BF_Waste

-- Liters of urine per unit of bladder value, and the least and most one relief leaves.
X.LITERS_PER_UNIT, X.MIN_LITERS, X.MAX_LITERS = 0.001, 0.1, 1.5
-- Number of floors below a window to check for ground.
X.FALL = 8

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, tonumber(v) or lo))
end

-- Liters of urine from a bladder value.
function X.liters(value)
    return clamp((tonumber(value) or 0) * X.LITERS_PER_UNIT, X.MIN_LITERS, X.MAX_LITERS)
end

-- A urine puddle on a square, while the pee-object option is on.
function X.pee(square, liters)
    if not square or SandboxVars.BF.CreatePeeObject == false then return end
    BF_Sewage.spread(square, liters, "urine")
end

-- A feces pile at a point inside a square (0-1 on each axis), while the poop-object option is on.
function X.poop(square, fx, fy)
    if not square or SandboxVars.BF.CreatePoopObject == false then return end
    -- The four-argument form transmits to clients itself.
    square:AddWorldInventoryItem(instanceItem("BF.HumanFeces"), clamp(fx, 0.05, 0.95), clamp(fy, 0.05, 0.95), 0)
end

-- The first square with a floor at or below x, y, z.
function X.ground(x, y, z)
    for level = z, math.max(0, z - X.FALL), -1 do
        local square = getCell():getGridSquare(x, y, level)
        if square and square:getFloor() then return square end
    end
    return nil
end

-- An open, smashed or empty window that is not barricaded.
function X.isOpenWindow(obj)
    if instanceof(obj, "IsoWindow") then
        return (obj:IsOpen() or obj:isSmashed() or obj:isGlassRemoved()) and not obj:isBarricaded()
    end
    return instanceof(obj, "IsoWindowFrame") and not obj:hasWindow() and not obj:isBarricaded()
end

-- The ground under the far side of a window from the character.
function X.outside(window, player)
    local square = window:getSquare()
    local near = window:getAddSheetSquare(player)
    local x, y = square:getX(), square:getY()
    if near == square then
        if window:getNorth() then y = y - 1 else x = x - 1 end
    end
    return X.ground(x, y, square:getZ())
end

return X