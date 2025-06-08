-- BF_SandboxMenu.lua

-- Caching
local CustomizeSandboxOptionPanel = require "CustomSandboxMenu/Sandbox_Customize"
local OnCreateSandboxOptions = require "CustomSandboxMenu/Sandbox_OnCreate"

-- UI constants
local UI_BORDER_SPACING = 10

-- Panel configurations
local panels = {
    {
        name = "Sandbox_Bathroom",
        panelColor = {r=1, g=1, b=1, a=0.5}, -- White tint
        borderColor = {r=0.1, g=0.1, b=0.1, a=0.5},
        buttonColor = {r=1, g=1, b=1, a=0.8},
        buttonText = "Sandbox_Bathroom_CustomButton",
        buttonTooltip = "Sandbox_Bathroom_CustomButton_tooltip"
    },
    {
        name = "Sandbox_Defecation",
        panelColor = {r=0.3, g=0.15, b=0.05, a=0.5}, -- Dark brown
        borderColor = {r=0.15, g=0.07, b=0.02, a=0.5}, -- Very dark brown border
        buttonColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.8 }, -- Near-black button
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
        buttonColor = {r=0.7, g=0.6, b=0.2, a=0.8}, -- Slightly brighter mustard button
        buttonText = "Sandbox_Urination_CustomButton",
        buttonTooltip = "Sandbox_Urination_CustomButton_tooltip"
    }
}

-- Util function for adding buttons / headers
local function AddButtonBetweenOptions(panel, optionKeyTop, optionKeyBottom, buttonHeight, buttonIDSuffix, buttonTextKey, buttonTooltipKey, buttonColor, borderColor, onClick)
    local x, _, width = CustomizeSandboxOptionPanel.GetTotalOptionDimensions(panel)
    CustomizeSandboxOptionPanel.InsertElementBetweenOptions(
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

local function CreatePanel(panel, config)
    CustomizeSandboxOptionPanel.SetPanelColor(panel, config.panelColor, config.borderColor)

    if config.name == "Sandbox_Defecation" then
        local buttonHeight = 40

        local x, _, width = CustomizeSandboxOptionPanel.GetTotalOptionDimensions(panel)


        AddButtonBetweenOptions(
            panel,
            "BF.EnableDiarrhea",
            "BF.PoopInToiletRequirement",
            buttonHeight,
            "poopHeader1_" .. config.name,
            config.headerText1,
            config.headerText1Tooltip,
            config.buttonColor,
            config.buttonBorderColor,
            function() print(config.name .. " button clicked!") end
        )

        AddButtonBetweenOptions(
            panel,
            "BF.PoopOnSelfRequirement",
            "BF.CanHavePoopAccident",
            buttonHeight,
            "poopHeader2_" .. config.name,
            config.headerText2,
            config.headerText2Tooltip,
            config.buttonColor,
            config.buttonBorderColor,
            function() print(config.name .. " button clicked!") end
        )

        AddButtonBetweenOptions(
            panel,
            "BF.VisiblePoopStain",
            "BF.CreatePoopObject",
            buttonHeight,
            "poopHeader3_" .. config.name,
            config.headerText3,
            config.headerText3Tooltip,
            config.buttonColor,
            config.buttonBorderColor,
            function() print(config.name .. " button clicked!") end
        )

    end
end



-- Register listeners
for _, config in ipairs(panels) do
    OnCreateSandboxOptions.addListener(getText(config.name), function(panel)
        CreatePanel(panel, config)
    end)
end