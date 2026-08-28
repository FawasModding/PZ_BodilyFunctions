-- =====================================================
--
-- BF_ScanUtils
--
-- Shared helpers for finding items across the player's reachable space:
--   1. main inventory
--   2. equipped bags (worn items that have their own inventory)
--   3. tiles within radius 1 (containers + loose floor items), but only tiles
--      in the SAME room when the player is indoors
--
-- The core primitive is BF.GatherReachableItems, which returns a flat array of
-- {item=, source=} records so callers can consume items from the exact place
-- they were found (no double-spending across containers).
--
-- =====================================================

BF = BF or {}

-- Returns an array of records: { item = InventoryItem, container = ItemContainer or nil, worldItem = IsoWorldInventoryObject or nil }
-- Each physical item appears exactly once, tied to where it lives.
function BF.GatherReachableItemRecords(player)
    local result = {}
    if not player then return result end

    local seen = {}

    local function addContainer(container)
        if not container then return end
        local items = container:getItems()
        if not items then return end
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and not seen[item] then
                seen[item] = true
                table.insert(result, { item = item, container = container, worldItem = nil })
            end
        end
    end

    -- 1. Main inventory
    local mainInv = player:getInventory()
    addContainer(mainInv)

    -- 2. Equipped bags (worn items that expose their own inventory).
    local worn = player:getWornItems()
    if worn then
        for i = 0, worn:size() - 1 do
            local wornItem = worn:getItemByIndex(i)
            if wornItem and wornItem.getInventory then
                local bagInv = wornItem:getInventory()
                if bagInv and bagInv ~= mainInv then
                    addContainer(bagInv)
                end
            end
        end
    end

    -- 3. Tiles within radius 1. When indoors, restrict to the player's room so
    -- containers in adjacent rooms (through a wall) aren't reachable.
    local sq = player:getSquare()
    if sq then
        local cell = getCell()
        local px, py, pz = sq:getX(), sq:getY(), sq:getZ()
        local playerRoom = sq:getRoom()
        local playerIndoors = playerRoom ~= nil

        for dx = -1, 1 do
            for dy = -1, 1 do
                local nearby = cell and cell:getGridSquare(px + dx, py + dy, pz)
                if nearby then
                    local sameSpace = true
                    if playerIndoors then
                        -- Only same-room tiles count when indoors.
                        sameSpace = (nearby:getRoom() == playerRoom)
                    else
                        -- Outdoors: don't reach into enclosed rooms.
                        sameSpace = (nearby:getRoom() == nil)
                    end

                    if sameSpace then
                        local objects = nearby:getObjects()
                        for i = 0, objects:size() - 1 do
                            local object = objects:get(i)
                            if object then
                                addContainer(object:getContainer())
                                if object.getItem and object:getObjectName() == "WorldInventoryItem" then
                                    local floorItem = object:getItem()
                                    if floorItem and not seen[floorItem] then
                                        seen[floorItem] = true
                                        table.insert(result, { item = floorItem, container = nil, worldItem = object })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return result
end

-- Convenience: flat array of just the items (no source info).
function BF.GatherReachableItems(player)
    local items = {}
    for _, rec in ipairs(BF.GatherReachableItemRecords(player)) do
        table.insert(items, rec.item)
    end
    return items
end

-- Counts reachable items of a given type.
function BF.CountReachableItemType(player, itemType)
    local total = 0
    for _, rec in ipairs(BF.GatherReachableItemRecords(player)) do
        if rec.item:getType() == itemType then
            total = total + 1
        end
    end
    return total
end

-- Returns the first reachable item matching predicate(item) -> bool, or nil.
function BF.FindReachableItem(player, predicate)
    for _, rec in ipairs(BF.GatherReachableItemRecords(player)) do
        if predicate(rec.item) then
            return rec.item
        end
    end
    return nil
end

-- Removes up to `count` reachable items of the given type, each from the exact
-- place it lives (so an item is never removed twice). Returns count removed.
function BF.RemoveReachableItemType(player, itemType, count)
    local removed = 0
    for _, rec in ipairs(BF.GatherReachableItemRecords(player)) do
        if removed >= count then break end
        if rec.item:getType() == itemType then
            if rec.container then
                rec.container:Remove(rec.item)
            elseif rec.worldItem then
                local wsq = rec.worldItem:getSquare()
                if wsq then
                    wsq:transmitRemoveItemFromSquare(rec.worldItem)
                end
            end
            removed = removed + 1
        end
    end
    return removed
end
