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
        buttonColor = { r = 0, g = 0, b = 0, a = 0.8 },
        --buttonText = "Sandbox_Defecation_CustomButton",
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

    if config.name == "Sandbox_Defecation" then
        local buttonHeight = 40

        local x, _, width = CustomizeSandboxOptionPanel.GetTotalOptionDimensions(panel)

        local optionKeyTop1 = "BF.EnableDiarrhea"
        local optionKeyBottom1 = "BF.PoopInToiletRequirement"
        CustomizeSandboxOptionPanel.InsertElementBetweenOptions(
            panel,
            optionKeyTop1,
            optionKeyBottom1,
            buttonHeight,
            function(_, y)
                local _, button = ISDebugUtils.addButton(
                    panel,
                    "customButton_poopHeader1_" .. config.name,
                    x, y,
                    width, buttonHeight,
                    getText(config.buttonText),
                    function() print(config.name .. " button clicked!") end
                )
                button.backgroundColor = config.buttonColor
                button.borderColor = {r=1, g=1, b=1, a=1}
                button.tooltip = getText(config.buttonTooltip)
                return button
            end
        )

        local optionKeyTop2 = "BF.PoopOnSelfRequirement"
        local optionKeyBottom2 = "BF.CanHavePoopAccident"
        CustomizeSandboxOptionPanel.InsertElementBetweenOptions(
            panel,
            optionKeyTop2,
            optionKeyBottom2,
            buttonHeight,
            function(_, y)
                local _, button = ISDebugUtils.addButton(
                    panel,
                    "customButton_poopHeader2_" .. config.name,
                    x, y,
                    width, buttonHeight,
                    getText(config.buttonText),
                    function() print(config.name .. " button clicked!") end
                )
                button.backgroundColor = config.buttonColor
                button.borderColor = {r=1, g=1, b=1, a=1}
                button.tooltip = getText(config.buttonTooltip)
                return button
            end
        )

        local optionKeyTop3 = "BF.VisiblePoopStain"
        local optionKeyBottom3 = "BF.CreatePoopObject"
        CustomizeSandboxOptionPanel.InsertElementBetweenOptions(
            panel,
            optionKeyTop3,
            optionKeyBottom3,
            buttonHeight,
            function(_, y)
                local _, button = ISDebugUtils.addButton(
                    panel,
                    "customButton_poopHeader3_" .. config.name,
                    x, y,
                    width, buttonHeight,
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