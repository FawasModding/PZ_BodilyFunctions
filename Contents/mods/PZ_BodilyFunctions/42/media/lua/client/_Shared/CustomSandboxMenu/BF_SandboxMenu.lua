-- BF_SandboxMenu.lua

-- Caching
local SandboxUIEnhancer = require "_Shared/CustomSandboxMenu/Sandbox_Customize"
local OnCreateSandboxOptions = require "_Shared/CustomSandboxMenu/Sandbox_OnCreate"

-- UI constants
local UI_BORDER_SPACING = 10

-- Panel configurations
local panels = {
    {
        name = "Sandbox_Bathroom",
        panelColor = {r=1, g=1, b=1, a=0.5}, -- White tint
        borderColor = {r=0.1, g=0.1, b=0.1, a=0.5},
        buttonColor = { r = 0, g = 0, b = 0, a = 0.8 }, -- black button
        buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=1}, -- Light gray border on button
        headerText1 = "Sandbox_BF_UNIMPLEMENTEDHeader",
        headerText1Tooltip = "Sandbox_BF_UNIMPLEMENTEDHeader_tooltip",
    },
    {
        name = "Sandbox_Defecation",
        panelColor = {r=0.3, g=0.15, b=0.05, a=0.5}, -- Dark brown
        borderColor = {r=0.15, g=0.07, b=0.02, a=0.5}, -- Very dark brown border
        buttonColor = { r = 0, g = 0, b = 0, a = 0.8 }, -- black button
        buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=1}, -- Light gray border on button
        headerText1 = "Sandbox_BF_POOPREQUIREMENTSHeader",
        headerText1Tooltip = "Sandbox_BF_POOPREQUIREMENTSHeader_tooltip",
        headerText2 = "Sandbox_BF_POOPSELFHeader",
        headerText2Tooltip = "Sandbox_BF_POOPSELFHeader_tooltip",
        headerText3 = "Sandbox_BF_POOPEXTRAHeader",
        headerText3Tooltip = "Sandbox_BF_POOPEXTRAHeader_tooltip"
    },
    {
        name = "Sandbox_Urination",
        panelColor = {r=0.6, g=0.5, b=0.15, a=0.5}, -- Mustard yellow
        borderColor = {r=0.25, g=0.2, b=0.05, a=0.5}, -- Darker mustard border
        buttonColor = { r = 0, g = 0, b = 0, a = 0.8 }, -- black button
        buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=1}, -- Light gray border on button
        headerText1 = "Sandbox_BF_PEEREQUIREMENTSHeader",
        headerText1Tooltip = "Sandbox_BF_PEEREQUIREMENTSHeader_tooltip",
        headerText2 = "Sandbox_BF_PEESELFHeader",
        headerText2Tooltip = "Sandbox_BF_PEESELFHeader_tooltip",
        headerText3 = "Sandbox_BF_PEEEXTRAHeader",
        headerText3Tooltip = "Sandbox_BF_PEEEXTRAHeader_tooltip"
    }
}

-- Util function for adding buttons / headers
local function AddButtonBetweenOptions(panel, optionKeyTop, optionKeyBottom, buttonHeight, buttonIDSuffix, buttonTextKey, buttonTooltipKey, buttonColor, borderColor, onClick)
    local x, _, width = SandboxUIEnhancer.CalculateLayoutMetrics(panel)
    SandboxUIEnhancer.InsertElementBetweenOptions(
        panel,
        optionKeyTop,
        optionKeyBottom,
        buttonHeight,
        function(_, y)
            local _, button = ISDebugUtils.addButton(
                panel,
                "customButton_" .. buttonIDSuffix,
                x, y,
                width, buttonHeight,
                getText(buttonTextKey),
                onClick
            )
            button.backgroundColor = buttonColor
            button.borderColor = borderColor
            button.tooltip = getText(buttonTooltipKey)
            return button
        end
    )
end

local function AddMultipleButtons(panel, buttonConfigs, baseName, buttonColor, borderColor)
    local buttonHeight = 40
    for i, cfg in ipairs(buttonConfigs) do
        AddButtonBetweenOptions(
            panel,
            cfg.optionKeyTop,
            cfg.optionKeyBottom,
            buttonHeight,
            ("header%d_%s"):format(i, baseName),
            cfg.headerText,
            cfg.headerTooltip,
            buttonColor,
            borderColor,
            function() print(baseName .. " button clicked!") end
        )
    end
end


local function CreatePanel(panel, config)
    SandboxUIEnhancer.SetPanelColor(panel, config.panelColor, config.borderColor)

    if config.name == "Sandbox_Bathroom" then
        AddMultipleButtons(panel, {
            {
                optionKeyTop = "BF.EnableDefecation",
                optionKeyBottom = "BF.EnableVomiting",
                headerText = config.headerText1,
                headerTooltip = config.headerText1Tooltip,
            },
        }, config.name, config.buttonColor, config.buttonBorderColor)

    elseif config.name == "Sandbox_Defecation" then
        AddMultipleButtons(panel, {
            {
                optionKeyTop = "BF.EnableDiarrhea",
                optionKeyBottom = "BF.PoopInToiletRequirement",
                headerText = config.headerText1,
                headerTooltip = config.headerText1Tooltip,
            },
            {
                optionKeyTop = "BF.PoopOnSelfRequirement",
                optionKeyBottom = "BF.CanHavePoopAccident",
                headerText = config.headerText2,
                headerTooltip = config.headerText2Tooltip,
            },
            {
                optionKeyTop = "BF.VisiblePoopStain",
                optionKeyBottom = "BF.CreatePoopObject",
                headerText = config.headerText3,
                headerTooltip = config.headerText3Tooltip,
            },
        }, config.name, config.buttonColor, config.buttonBorderColor)

    elseif config.name == "Sandbox_Urination" then
        AddMultipleButtons(panel, {
            {
                optionKeyTop = "BF.UrinateSpeedMultiplier",
                optionKeyBottom = "BF.PeeInToiletRequirement",
                headerText = config.headerText1,
                headerTooltip = config.headerText1Tooltip,
            },
            {
                optionKeyTop = "BF.PeeOnSelfRequirement",
                optionKeyBottom = "BF.CanHavePeeAccident",
                headerText = config.headerText2,
                headerTooltip = config.headerText2Tooltip,
            },
            {
                optionKeyTop = "BF.VisiblePeeStain",
                optionKeyBottom = "BF.CreatePeeObject",
                headerText = config.headerText3,
                headerTooltip = config.headerText3Tooltip,
            },
        }, config.name, config.buttonColor, config.buttonBorderColor)
    end
end

-- Register listeners
for _, config in ipairs(panels) do
    OnCreateSandboxOptions.addListener(getText(config.name), function(panel)
        CreatePanel(panel, config)
    end)
end