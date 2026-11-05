-- Collects every wipeable option the player can reach (main inventory,
-- equipped bags, same-room tiles within radius 1).
--
-- Menu structure:
--   * Toilet paper (drainable)         -> individual entry
--   * Newspapers/magazines/comics      -> individual entry each (category paper_single)
--   * Medium sheets + small scraps     -> pooled into one "Paper scraps" entry
--   * Grass                            -> individual entry, capped efficiency
--   * Cloth tools (dishcloth/towel/rag)-> individual entry each
--   * Books & multi-page paper         -> individual entry each
--
-- Returns option tables:
--   { wipeType, item, efficiency, pooledTypes?, label? }
--   wipeType in: usingDrainable, usingOneTime, usingBook, usingClothTool
function BF.CollectWipeables(player)
    local options = {}
    if not player then return options end

    local records = BF.GatherReachableItemRecords(player)

    local countByType = {}
    -- Drainables are counted in charges, not items, and pooled across every
    -- reachable roll/box. Picking the first record found meant a nearly spent
    -- roll on the bathroom floor was offered at 25% while a full one sat in the
    -- player's bag. The best item is kept so the menu entry points somewhere
    -- sensible; WipeSelf spends the pool best-first.
    local drainCharges = {}
    local drainBestItem = {}
    for _, rec in ipairs(records) do
        local t = rec.item:getType()
        countByType[t] = (countByType[t] or 0) + 1

        if BF_WipingConfig.drainableWipeables[t] and BF.IsChargeBasedWipeable(rec.item) then
            local uses = rec.item:getCurrentUses()
            if uses >= 1 then
                drainCharges[t] = (drainCharges[t] or 0) + uses
                local best = drainBestItem[t]
                if not best or uses > best:getCurrentUses() then
                    drainBestItem[t] = rec.item
                end
            end
        end
    end

    local emittedType = {}
    local paperPool = nil  -- single pool for category "paper" (tier 2 + 4)

    for _, rec in ipairs(records) do
        local item = rec.item
        local itemType = item:getType()

        -- Charge-based (toilet paper, tissues)
        local drainCfg = BF_WipingConfig.drainableWipeables[itemType]
        if drainCfg and BF.IsChargeBasedWipeable(item) and item:getCurrentUses() >= 1 then
            if not emittedType[itemType] then
                local eff = math.min((drainCharges[itemType] or 0) / drainCfg.usesRequired, 1.0)
                table.insert(options, {
                    wipeType = "usingDrainable",
                    item = drainBestItem[itemType] or item,
                    efficiency = eff
                })
                emittedType[itemType] = true
            end

        else
            local oneCfg = BF_WipingConfig.oneTimeWipeables[itemType]
            local toolCfg = BF_WipingConfig.clothToolWipeables[itemType]
            local bookCfg = BF_WipingConfig.bookWipeables[itemType]

            if oneCfg then
                local category = oneCfg.category or "paper"

                if category == "grass" then
                    if not emittedType[itemType] then
                        local available = countByType[itemType] or 0
                        local cap = oneCfg.maxEfficiency or 1.0
                        local eff = math.min(available / oneCfg.usesRequired, cap)
                        table.insert(options, {
                            wipeType = "usingOneTime", item = item, efficiency = eff,
                            pooledTypes = { itemType }
                        })
                        emittedType[itemType] = true
                    end

                elseif category == "paper_single" then
                    -- Individual entry per type (like books).
                    if not emittedType[itemType] then
                        local available = countByType[itemType] or 0
                        local eff = math.min(available / oneCfg.usesRequired, 1.0)
                        table.insert(options, {
                            wipeType = "usingOneTime", item = item, efficiency = eff,
                            pooledTypes = { itemType }
                        })
                        emittedType[itemType] = true
                    end

                else
                    -- category "paper": pool tier-2 and tier-4 together.
                    if not paperPool then
                        paperPool = { types = {}, typeSet = {}, weighted = 0, sample = item }
                    end
                    if not paperPool.typeSet[itemType] then
                        paperPool.typeSet[itemType] = true
                        table.insert(paperPool.types, itemType)
                    end
                    -- Each item contributes 1/usesRequired toward a full wipe.
                    paperPool.weighted = paperPool.weighted + (1 / oneCfg.usesRequired)
                end

            elseif toolCfg then
                -- Cloth tool: individual entry.
                if not emittedType[itemType] then
                    local available = countByType[itemType] or 0
                    local eff = math.min(available / toolCfg.usesRequired, 1.0)
                    table.insert(options, {
                        wipeType = "usingClothTool", item = item, efficiency = eff,
                        pooledTypes = { itemType }
                    })
                    emittedType[itemType] = true
                end

            elseif bookCfg then
                if not emittedType[itemType] then
                    table.insert(options, { wipeType = "usingBook", item = item, efficiency = 1.0 })
                    emittedType[itemType] = true
                end
            end
        end
    end

    -- Emit the single pooled "Paper scraps" entry.
    if paperPool then
        local eff = math.min(paperPool.weighted, 1.0)
        local label = getText("ContextMenu_WipeWith") .. " " .. getText("ContextMenu_PaperScraps")
        table.insert(options, {
            wipeType = "usingOneTime",
            item = paperPool.sample,
            efficiency = eff,
            pooledTypes = paperPool.types,
            label = label
        })
    end

    return options
end