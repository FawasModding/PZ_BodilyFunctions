-- Storage array for all of our options
local config = {
    keyBind   = nil,
    checkBox  = nil,
    textEntry = nil,
    multiBox  = nil,
    comboBox  = nil,
    colorPick = nil,
    slider    = nil,
    button    = nil
}

local function BathroomFunctionsConfig()

    -- ID, Display name
    local options = PZAPI.ModOptions:create("BathroomFunctions", "Bathroom Functions")

    options:addTitle("W.I.P")
    options:addDescription("Client-side options will be included here.")

    config.checkBox = options:addTickBox("1", getText("UI_options_UNIQUEID_checkBox"), true, getText("UI_options_UNIQUEID_checkBox_tooltip"))

end

BathroomFunctionsConfig()