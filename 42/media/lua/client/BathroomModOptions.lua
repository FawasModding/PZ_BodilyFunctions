-- Storage array for all of our options
local config = {
    peeInContainersOption   = nil,
    peeSelfOption  = nil,
    poopSelfOption = nil,
    showMoodles  = nil,
    moodleType  = nil,
    showSoiledMoodles = nil,
}

local function BathroomFunctionsConfig()

    -- ID, Display name
    local options = PZAPI.ModOptions:create("BathroomFunctions", "Bathroom Functions")

    options:addTitle("Context Menu")

    config.peeInContainersOption = options:addTickBox("1", getText("UI_BathroomFunctions_options_PeeInContainersOption"), true, getText("UI_BathroomFunctions_options_PeeInContainersOption_tooltip"))
    config.peeSelfOption = options:addTickBox("2", getText("UI_BathroomFunctions_options_PeeSelfOption"), false, getText("UI_BathroomFunctions_options_PeeSelfOption_tooltip"))
    config.poopSelfOption = options:addTickBox("3", getText("UI_BathroomFunctions_options_PoopSelfOption"), false, getText("UI_BathroomFunctions_options_PoopSelfOption_tooltip"))

    options:addSeparator()

    options:addTitle("Moodles")

    config.showMoodles = options:addTickBox("4", getText("UI_BathroomFunctions_options_ShowMoodles"), true, getText("UI_BathroomFunctions_options_ShowMoodles_tooltip"))

    config.moodleType = options:addComboBox("5", getText("UI_BathroomFunctions_options_MoodleType"), getText("UI_BathroomFunctions_options_MoodleType_tooltip"))
    -- Create entries:
    --- addItem(name, selected)
    ---- whichever is set to "true" will be the initially selected box.
    --- NOTE: calling getValue on the option will return the number of the entry. 
    config.moodleType:addItem(getText("UI_BathroomFunctions_options_MoodleType_1"), true) -- getValue(): 1
    config.moodleType:addItem(getText("UI_BathroomFunctions_options_MoodleType_2"), false) -- getValue(): 2

    config.showSoiledMoodles = options:addTickBox("6", getText("UI_BathroomFunctions_options_ShowSoiledMoodles"), true, getText("UI_BathroomFunctions_options_ShowSoiledMoodles_tooltip"))

end

BathroomFunctionsConfig()