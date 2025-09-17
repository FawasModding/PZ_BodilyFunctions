---@diagnostic disable: duplicate-set-field
BF_Soiling = BF_Soiling or {}

-- Affect mood over time
function BF_Soiling.MoodConsequences()
    
end

-- Show urinated and defecated garments moodles
function BF_Soiling.ShowSoiledMoodles()
    
end

-- Apply visual/effect changes to one item based on existing modData <---- TODO: Test
-- Scope: Single item
local function ApplySoilingEffects(item, isLeak)
    if not item or not item:getModData() then return end
    local modData = item:getModData()

    -- Urinated
    if modData.peed == true then
        if item:IsClothing() then
            local severity = (modData.peedSeverity or 0) / 100
            item:setWetness(math.min(500 * severity, 500))
            item:setDirtyness(math.min(100 * severity, 100))
        end
    end

    -- Defecated
    if modData.pooped == true then
        if item:IsClothing() then
            local severity = (modData.poopedSeverity or 0) / 100
            item:setDirtyness(math.min(100 * severity, 100))
        end
    end
end

-- Decide which clothing items should be soiled and set their modData, then call ApplySoilingEffects <---- TODO: Test
-- Scope: All worn items for the player
function BF_Soiling.MarkClothing(player, soilType, severity, isLeak)
    if not player then return end

    local soilable = BF_Soiling.GetSoilableClothing()
    local wornItems = player:getWornItems()

    for i = 0, wornItems:size() - 1 do
        local clothing = wornItems:getItemByIndex(i)
        if clothing and clothing:IsClothing() then
            local location = clothing:getBodyLocation()
            for _, validLoc in ipairs(soilable) do
                if location == validLoc then
                    local modData = clothing:getModData()

                    if soilType == "pee" then
                        modData.peed = true
                        modData.peedSeverity = severity or 100
                    elseif soilType == "poop" then
                        modData.pooped = true
                        modData.poopedSeverity = severity or 100
                        -- OPTIONAL: Solid/liquid distinction:
                        modData.containsSolidPoop = not isLeak
                    end

                    -- Apply effects immediately
                    ApplySoilingEffects(clothing, isLeak)  break -- no need to keep checking locations
                end
            end
        end
    end
end

