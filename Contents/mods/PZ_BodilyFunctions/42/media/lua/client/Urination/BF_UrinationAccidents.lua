require "BodilyFunctions"
BF_Urination = BF_Urination or {}

-- Function to apply effects when the player has urinated (no clothing logic)
function BF_Urination.UrinateBottoms(leakTriggered)
    local player = getPlayer()
    local severity = leakTriggered and 50 or 100

    BF_Urination.SpawnPuddle(player) -- handles world object if SandboxVar allows
    BF_Soiling.MarkClothing(player, "pee", severity, leakTriggered)
    BF_Urination.PlayUrinationSounds(player, leakTriggered)
    BF_Urination.ShowUrinationDialogue(player, leakTriggered)
end

-- =====================================================
-- EVENT REGISTRATION
-- =====================================================

function BF_Urination.SpawnPuddle(player)
    if SandboxVars.BF.CreatePeeObject and not player:isAsleep() then
        local urineItem = instanceItem("BF.Urine_Hydrated_0")
        player:getCurrentSquare():AddWorldInventoryItem(urineItem, 0, 0, 0)
    end
end
function BF_Urination.PlayUrinationSounds(player, leakTriggered)
    if not leakTriggered then
        getSoundManager():PlayWorldSound("BF_Pee_Self", player:getCurrentSquare(), 0, 10, 0.2, false)
    end
    player:playerVoiceSound("SighBored")
end
function BF_Urination.ShowUrinationDialogue(player, leakTriggered)
    if leakTriggered then
        player:Say(getText("IGUI_announce_SilentOops"))
    else
        local modOptions = PZAPI.ModOptions:getOptions("BF")
        local playerSayStatus = modOptions:getOption("6")
        if playerSayStatus:getValue(1) then
            player:Say(getText("IGUI_announce_IPeedMyself"))
        end
    end
end

function BF_Urination.TriggerSelfUrinate(isLeak)
    local isLeak = isLeak or false
    local player = getPlayer()
    local urinateValue = BF.GetUrinateValue()
    local peeTime = urinateValue / 4

    -- Just apply bottoms effect (no clothing checks)
    BF_Urination.UrinateBottoms(isLeak)

    -- Timed action
    ISTimedActionQueue.add(SelfUrinate:new(player, peeTime, false, false, true, false, nil, isLeak))

    if isLeak then
        print("Leak triggered: Updated Peed Self Value: " .. BF.GetPeedSelfValue())
    else
        print("Updated Peed Self Value: " .. BF.GetPeedSelfValue())
    end
end