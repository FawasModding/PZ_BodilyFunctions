-- Storage array for all of our options
local config = {
    peeInContainersOption   = nil,
    peeSelfOption  = nil,
    poopSelfOption = nil,
    showMoodles  = nil,
    moodleType  = nil,
    showSoiledMoodles = nil,
    playerSayStatus = nil,
}

local function BFConfig()

    -- ID, Display name
    local options = PZAPI.ModOptions:create("BF", "Bodily Functions")

    options:addTitle("Context Menu")

    config.peeInContainersOption = options:addTickBox("1", getText("UI_BF_options_PeeInContainersOption"), true, getText("UI_BF_options_PeeInContainersOption_tooltip"))
    config.peeSelfOption = options:addTickBox("2", getText("UI_BF_options_PeeSelfOption"), false, getText("UI_BF_options_PeeSelfOption_tooltip"))
    config.poopSelfOption = options:addTickBox("3", getText("UI_BF_options_PoopSelfOption"), false, getText("UI_BF_options_PoopSelfOption_tooltip"))

    options:addSeparator()

    options:addTitle("Moodles")

    config.showMoodles = options:addTickBox("4", getText("UI_BF_options_ShowMoodles"), true, getText("UI_BF_options_ShowMoodles_tooltip"))
    config.showSoiledMoodles = options:addTickBox("5", getText("UI_BF_options_ShowSoiledMoodles"), true, getText("UI_BF_options_ShowSoiledMoodles_tooltip"))

    config.playerSayStatus = options:addTickBox("6", getText("UI_BF_options_PlayerSayStatus"), false, getText("UI_BF_options_PlayerSayStatus_tooltip"))

end

BFConfig()