require "BodilyFunctions"

BF_Defecation = BF_Defecation or {}

-- Function to apply effects when the player has defecated (no clothing logic)
function BF_Defecation.DefecateBottoms(leakTriggered)
    local player = getPlayer()
    local modOptions = PZAPI.ModOptions:getOptions("BF")

    -- Sound and dialogue
    player:playerVoiceSound("JumpLow")
    if leakTriggered then
        player:Say(getText("IGUI_announce_SilentOops"))
    else
        getSoundManager():PlayWorldSound("BF_Poop_Self_Light", player:getCurrentSquare(), 0, 10, 0.05, false)
        local playerSayStatus = modOptions:getOption("6")
        if playerSayStatus:getValue(1) then
            player:Say(getText("IGUI_announce_IPoopedMyself"))
        end
    end
end

-- =====================================================
-- EVENT REGISTRATION
-- =====================================================

function BF_Defecation.TriggerSelfDefecate(isLeak)
    local isLeak = isLeak or false
    local player = getPlayer()
    local defecateValue = BF.GetDefecateValue()
    local poopTime = defecateValue / 4

    -- Just trigger bottoms effect (no clothing checks)
    BF_Defecation.DefecateBottoms(isLeak)

    -- Timed action
    ISTimedActionQueue.add(SelfDefecate:new(player, poopTime, false, false, true, false, nil, isLeak))

    print("Updated Pooped Self Value: " .. BF.GetPoopedSelfValue())
    if isLeak then
        print("Leak triggered: Updated Pooped Self Value: " .. BF.GetPoopedSelfValue())
    end
end