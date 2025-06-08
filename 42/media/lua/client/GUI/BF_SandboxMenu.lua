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
        panelColor = {r=0.55, g=0.27, b=0.07, a=0.5}, -- Brown tint
        borderColor = {r=0.11, g=0.05, b=0.01, a=0.5},
        buttonColor = {r=0.55, g=0.27, b=0.07, a=0.8},
        buttonText = "Sandbox_Defecation_CustomButton",
        buttonTooltip = "Sandbox_Defecation_CustomButton_tooltip"
    },
    {
        name = "Sandbox_Urination",
        panelColor = {r=1, g=1, b=0.2, a=0.5}, -- Yellow tint
        borderColor = {r=0.2, g=0.2, b=0.04, a=0.5},
        buttonColor = {r=1, g=1, b=0.2, a=0.8},
        buttonText = "Sandbox_Urination_CustomButton",
        buttonTooltip = "Sandbox_Urination_CustomButton_tooltip"
    }
}

local function CreatePanel(panel, config)
    CustomizeSandboxOptionPanel.SetPanelColor(panel, config.panelColor, config.borderColor)

    if config.name == "Sandbox_Bathroom" then
        local optionKeyTop = "BF.EnableVomiting"
        local optionKeyBottom = "BF.EnableFarting"
        local buttonHeight = 40

        CustomizeSandboxOptionPanel.InsertElementBetweenOptions(
            panel,
            optionKeyTop,
            optionKeyBottom,
            buttonHeight,
            function(x, y)
                local _, button = ISDebugUtils.addButton(
                    panel,
                    "customButton_farting_" .. config.name,
                    x, y,
                    300, buttonHeight,
                    getText(config.buttonText),
                    function() print(config.name .. " button clicked!") end
                )
                button.backgroundColor = config.buttonColor
                button.borderColor = {r=1, g=1, b=1, a=1}
                button.tooltip = getText(config.buttonTooltip)
                return button
            end
        )
    end
end



-- Register listeners
for _, config in ipairs(panels) do
    OnCreateSandboxOptions.addListener(getText(config.name), function(panel)
        CreatePanel(panel, config)
    end)
end