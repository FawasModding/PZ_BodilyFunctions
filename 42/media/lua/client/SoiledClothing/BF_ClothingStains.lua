BathroomClothOverlays = {}

BathroomClothOverlays.peedModelsSuitTrousersMesh = {}
BathroomClothOverlays.peedModelsMaleBoxers = {}
BathroomClothOverlays.peedModelsFemalePanties = {}

function BathroomClothOverlays.PopulatePeedModels()
    local peedModelsSuitTrousersMesh = {
        "Trousers_Suit", "Trousers_SuitTEXTURE", "Trousers_Scrubs",
        "Trousers", "Trousers_Jeans", "Trousers_Camo", "Trousers_Army", "Trousers_Denim",
        "Shorts_LongDenim", "Shorts_ShortDenim", "Shorts_ShortFormal",
        "Shorts_LongSport", "Shorts_LongSport_Red", "Shorts_BoxingRed", "Shorts_BoxingBlue",
        "Shorts_ShortSport", "Shorts_FootballPants", "Shorts_FootballPants_Black",
        "Shorts_FootballPants_Gold", "Shorts_FootballPants_White", "Shorts_HockeyPants",
        "Shorts_HockeyPants_Black", "Shorts_HockeyPants_Red", "Shorts_HockeyPants_UniBlue",
        "Shorts_HockeyPants_White"
    }
    local peedModelsMaleBoxers = {
        "Boxers_White", "Male_Boxers_Pants_2", "Male_Boxers_Pants_3", "Boxers_Hearts",
        "Boxers_Silk_Black", "Boxers_Silk_Red", "Boxers_RedStripes", "Briefs_SmallTrunks_Black",
        "Briefs_SmallTrunks_Blue", "Briefs_SmallTrunks_Red", "Briefs_SmallTrunks_WhiteTINT"
    }
    local peedModelsFemalePanties = {
        "Underpants_White", "Bikini_TINT", "Underpants_Black", "Underpants_RedSpots",
        "Underpants_AnimalPrint", "Underpants_Hide", "FrillyUnderpants_Black",
        "FrillyUnderpants_Pink", "FrillyUnderpants_Red", "Briefs_White", "Briefs_AnimalPrints"
    }

    for i = 1, #peedModelsSuitTrousersMesh do
        table.insert(BathroomClothOverlays.peedModelsSuitTrousersMesh, peedModelsSuitTrousersMesh[i])
    end
    for i = 1, #peedModelsMaleBoxers do
        table.insert(BathroomClothOverlays.peedModelsMaleBoxers, peedModelsMaleBoxers[i])
    end
    for i = 1, #peedModelsFemalePanties do
        table.insert(BathroomClothOverlays.peedModelsFemalePanties, peedModelsFemalePanties[i])
    end
end

Events.OnLoad.Add(function()
    BathroomClothOverlays.PopulatePeedModels()
    BathroomClothOverlays.removeAllPeedOverlays(getPlayer())
    BathroomClothOverlays.equipAllPeedOverlays(getPlayer())
    BathroomClothOverlays.removeAllPoopedOverlays(getPlayer())
    BathroomClothOverlays.equipAllPoopedOverlays(getPlayer())
end)

function table.contains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function BathroomClothOverlays.getCurrentWornItems(player)
    local currentWornItems = {}
    for i = 0, player:getWornItems():size() - 1 do
        local item = player:getWornItems():getItemByIndex(i)
        if item then
            currentWornItems[item:getType()] = item
        end
    end
    return currentWornItems
end

function BathroomClothOverlays.getPeedOverlayItem(item)
    local itemType = item:getType()
    if table.contains(BathroomClothOverlays.peedModelsSuitTrousersMesh, itemType) or
       itemType:match("Pants") then
        return "BathroomFunctions.SuitTrousersMesh_Peed"
    elseif itemType:match("Shorts") then
        return "BathroomFunctions.Trousers_Short_Peed"
    elseif table.contains(BathroomClothOverlays.peedModelsMaleBoxers, itemType) then
        return "BathroomFunctions.Male_Boxers_Peed"
    elseif table.contains(BathroomClothOverlays.peedModelsFemalePanties, itemType) then
        return "BathroomFunctions.Female_Underpants_Peed"
    end
    return nil
end

function BathroomClothOverlays.getPoopedOverlayItem(item)
    local itemType = item:getType()
    if table.contains(BathroomClothOverlays.peedModelsSuitTrousersMesh, itemType) or
       itemType:match("Pants") then
        return "BathroomFunctions.BoxingShorts_Pooped"
    elseif itemType:match("Shorts") then
        return "BathroomFunctions.BoxingShorts_Pooped"
    elseif table.contains(BathroomClothOverlays.peedModelsMaleBoxers, itemType) then
        return "BathroomFunctions.Male_Boxers_Pooped"
    elseif table.contains(BathroomClothOverlays.peedModelsFemalePanties, itemType) then
        return "BathroomFunctions.Female_Underpants_Pooped"
    end
    return nil
end

function BathroomClothOverlays.equipPeedOverlay(player, wornItem, location)
    local modData = wornItem:getModData()
    if modData.peed == true and (modData.peedSeverity == nil or modData.peedSeverity >= 25) then
        local currentWornItems = BathroomClothOverlays.getCurrentWornItems(player)
        local overlayItemType = BathroomClothOverlays.getPeedOverlayItem(wornItem)
        if overlayItemType and not currentWornItems[overlayItemType] then
            local itemToWear = player:getInventory():AddItem(overlayItemType)
            if itemToWear then
                player:setWornItem(location, itemToWear)
                modData.peeOverlayItemType = overlayItemType
                print("Equipped peed overlay: " .. overlayItemType .. " for " .. wornItem:getType() .. " at " .. location)
            else
                print("Failed to add peed overlay item: " .. overlayItemType)
            end
        end
    end
end

function BathroomClothOverlays.equipPoopedOverlay(player, wornItem, location)
    local modData = wornItem:getModData()
    if modData.pooped == true and (modData.poopedSeverity == nil or modData.poopedSeverity >= 25) then
        local currentWornItems = BathroomClothOverlays.getCurrentWornItems(player)
        local overlayItemType = BathroomClothOverlays.getPoopedOverlayItem(wornItem)
        if overlayItemType and not currentWornItems[overlayItemType] then
            local itemToWear = player:getInventory():AddItem(overlayItemType)
            if itemToWear then
                player:setWornItem(location, itemToWear)
                modData.pooOverlayItemType = overlayItemType
                print("Equipped pooped overlay: " .. overlayItemType .. " for " .. wornItem:getType() .. " at " .. location)
            else
                print("Failed to add pooped overlay item: " .. overlayItemType)
            end
        end
    end
end

function BathroomClothOverlays.removePeedOverlay(player, wornItem)
    if wornItem:getModData().peed then
        local inventory = player:getInventory()
        local overlayItemType = wornItem:getModData().peeOverlayItemType
        if overlayItemType then
            local overlayItem = inventory:getItemFromType(overlayItemType)
            if overlayItem then
                inventory:Remove(overlayItem)
                player:removeWornItem(overlayItem)
                print("Removed peed overlay: " .. overlayItemType)
            end
            wornItem:getModData().peeOverlayItemType = nil
        end
    end
end

function BathroomClothOverlays.removePoopedOverlay(player, wornItem)
    if wornItem:getModData().pooped then
        local inventory = player:getInventory()
        local overlayItemType = wornItem:getModData().pooOverlayItemType
        if overlayItemType then
            local overlayItem = inventory:getItemFromType(overlayItemType)
            if overlayItem then
                inventory:Remove(overlayItem)
                player:removeWornItem(overlayItem)
                print("Removed pooped overlay: " .. overlayItemType)
            end
            wornItem:getModData().pooOverlayItemType = nil
        end
    end
end

function BathroomClothOverlays.removeAllPeedOverlays(player)
    local inventory = player:getInventory()
    local itemsToRemove = {}
    for i = 0, inventory:getItems():size() - 1 do
        local item = inventory:getItems():get(i)
        if item and item:hasTag("BathroomOverlay") and not item:hasTag("PoopedOverlay") then
            table.insert(itemsToRemove, item)
        end
    end
    for _, item in ipairs(itemsToRemove) do
        inventory:Remove(item)
        player:removeWornItem(item)
        print("Removed peed overlay item: " .. tostring(item:getType()))
    end
end

function BathroomClothOverlays.removeAllPoopedOverlays(player)
    local inventory = player:getInventory()
    local itemsToRemove = {}
    for i = 0, inventory:getItems():size() - 1 do
        local item = inventory:getItems():get(i)
        if item and item:hasTag("PoopedOverlay") then
            table.insert(itemsToRemove, item)
        end
    end
    for _, item in ipairs(itemsToRemove) do
        inventory:Remove(item)
        player:removeWornItem(item)
        print("Removed pooped overlay item: " .. tostring(item:getType()))
    end
end

function BathroomClothOverlays.equipAllPeedOverlays(player)
    print("[DEBUG] Starting equipAllPeedOverlays...")
    local currentWornItems = BathroomClothOverlays.getCurrentWornItems(player)
    BathroomClothOverlays.removeAllPeedOverlays(player)

    local underwearLocations = {"UnderwearBottom", "Underwear"}
    local pantsLocations = {"Torso1Legs1", "Legs1", "Pants", "ShortPants", "ShortsShort"}

    for _, location in ipairs(underwearLocations) do
        local wornItem = player:getWornItem(location)
        if wornItem and wornItem:getModData().peed == true and (wornItem:getModData().peedSeverity == nil or wornItem:getModData().peedSeverity >= 25) then
            BathroomClothOverlays.equipPeedOverlay(player, wornItem, "PeedOverlay_Underwear")
        end
    end

    for _, location in ipairs(pantsLocations) do
        local wornItem = player:getWornItem(location)
        if wornItem and wornItem:getModData().peed == true and (wornItem:getModData().peedSeverity == nil or wornItem:getModData().peedSeverity >= 25) then
            BathroomClothOverlays.equipPeedOverlay(player, wornItem, "PeedOverlay_Pants")
        end
    end
    print("[DEBUG] Completed equipAllPeedOverlays.")
end

function BathroomClothOverlays.equipAllPoopedOverlays(player)
    print("[DEBUG] Starting equipAllPoopedOverlays...")
    local currentWornItems = BathroomClothOverlays.getCurrentWornItems(player)
    BathroomClothOverlays.removeAllPoopedOverlays(player)

    local underwearLocations = {"UnderwearBottom", "Underwear"}
    local pantsLocations = {"Torso1Legs1", "Legs1", "Pants", "ShortPants", "ShortsShort"}

    for _, location in ipairs(underwearLocations) do
        local wornItem = player:getWornItem(location)
        if wornItem and wornItem:getModData().pooped == true and (wornItem:getModData().poopedSeverity == nil or wornItem:getModData().poopedSeverity >= 25) then
            BathroomClothOverlays.equipPoopedOverlay(player, wornItem, "PoopedOverlay_Underwear")
        end
    end

    for _, location in ipairs(pantsLocations) do
        local wornItem = player:getWornItem(location)
        if wornItem and wornItem:getModData().pooped == true and (wornItem:getModData().poopedSeverity == nil or wornItem:getModData().poopedSeverity >= 25) then
            BathroomClothOverlays.equipPoopedOverlay(player, wornItem, "PoopedOverlay_Pants")
        end
    end
    print("[DEBUG] Completed equipAllPoopedOverlays.")
end

ISWearClothing.o_perform = ISWearClothing.perform
function ISWearClothing:perform()
    self:o_perform()
    BathroomClothOverlays.removeAllPeedOverlays(getPlayer())
    BathroomClothOverlays.removeAllPoopedOverlays(getPlayer())
    local delayTicks = 10
    local tickCount = 0
    local function delayedEquipOverlays()
        tickCount = tickCount + 1
        if tickCount >= delayTicks then
            Events.OnTick.Remove(delayedEquipOverlays)
            BathroomClothOverlays.equipAllPeedOverlays(getPlayer())
            BathroomClothOverlays.equipAllPoopedOverlays(getPlayer())
        end
    end
    Events.OnTick.Add(delayedEquipOverlays)
end

ISUnequipAction.o_perform = ISUnequipAction.perform
function ISUnequipAction:perform()
    self:o_perform()
    BathroomClothOverlays.removeAllPeedOverlays(getPlayer())
    BathroomClothOverlays.removeAllPoopedOverlays(getPlayer())
    local delayTicks = 10
    local tickCount = 0
    local function delayedEquipOverlays()
        tickCount = tickCount + 1
        if tickCount >= delayTicks then
            Events.OnTick.Remove(delayedEquipOverlays)
            BathroomClothOverlays.equipAllPeedOverlays(getPlayer())
            BathroomClothOverlays.equipAllPoopedOverlays(getPlayer())
        end
    end
    Events.OnTick.Add(delayedEquipOverlays)
end