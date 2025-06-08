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

    local x, y, width = CustomizeSandboxOptionPanel.GetTotalOptionDimensions(panel)

    if config.name == "Sandbox_Bathroom" then
        local targetOptionName = "BF.EnableFarting"
        local option = CustomizeSandboxOptionPanel.GetOption(targetOptionName)
        if not option or not option.label then
            print("Error: Target option '" .. targetOptionName .. "' not found or missing label")
            return
        end

        -- Find the option above the target (3rd option)
        local previousOption = CustomizeSandboxOptionPanel.GetOption("BF.EnableVomiting")
        if not previousOption or not previousOption.label then
            print("Error: Previous option 'BF.EnableVomiting' not found or missing label")
            return
        end

        local buttonHeight = 40
        local spacing = UI_BORDER_SPACING

        -- Place the button *below* the previous (3rd) option
        local buttonY = previousOption.label:getY() + previousOption.label:getHeight() + spacing

        -- Add button
        local _, button = ISDebugUtils.addButton(
            panel,
            "customButton_farting_" .. config.name,
            x, buttonY,
            width, buttonHeight,
            getText(config.buttonText),
            function() print(config.name .. " button clicked!") end
        )

        button.backgroundColor = config.buttonColor
        button.borderColor = {r=1, g=1, b=1, a=1}
        button.tooltip = getText(config.buttonTooltip)

        table.insert(panel.customUI, { element = button, position = "above", option = targetOptionName })

        -- Calculate how far to shift elements
        local shiftY = buttonHeight + spacing

        -- Shift all controls at or below the target option
        local targetY = option.label:getY()
        for name, control in pairs(panel.controls) do
            local label = panel.labels[name]
            if label and control and label:getY() >= targetY then
                label:setY(label:getY() + shiftY)
                control:setY(control:getY() + shiftY)
            end
        end

        -- Update scroll bar height based on new layout
        CustomizeSandboxOptionPanel.SetScrollBarHeight(panel, y + 40 + UI_BORDER_SPACING)
    end
end


-- Register listeners
for _, config in ipairs(panels) do
    OnCreateSandboxOptions.addListener(getText(config.name), function(panel)
        CreatePanel(panel, config)
    end)
end