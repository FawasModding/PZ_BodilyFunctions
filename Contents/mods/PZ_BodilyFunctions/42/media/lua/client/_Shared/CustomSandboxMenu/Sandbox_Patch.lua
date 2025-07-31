-- Sandbox_Patch.lua

--- DEFINITIONS
--- @class CustomSandboxOptionsScreenPanel : SandboxOptionsScreenPanel
--- @field titles table
--- @field controls table
--- @field labels table
--- @field customUI table -- Custom UI elements (e.g., headers)
--- @class OptionPanels
--- @field OPTION_PANELS table<string, CustomSandboxOptionsScreenPanel> -- list of option panels
--- @field OPTIONS table<string, table> -- list of options by name
local OptionPanels = {
    OPTION_PANELS = {},
    OPTIONS = {}
}

--- FOR CACHING
local OnCreateSandboxOptions = require "_Shared/CustomSandboxMenu/Sandbox_OnCreate"

--- get SandboxOptionsScreenPanel ---
local SandboxOptionsScreen_createPanel = SandboxOptionsScreen.createPanel

--- Intercept the creation of the panel to store each option and initialize custom UI.
--- @param page table
--- @return CustomSandboxOptionsScreenPanel
function SandboxOptionsScreen:createPanel(page)
    local panel = SandboxOptionsScreen_createPanel(self, page)

    OptionPanels.OPTION_PANELS[page.name] = panel

    -- Initialize customUI table
    panel.customUI = {}

    -- Store references to individual options
    for name, control in pairs(panel.controls) do
        OptionPanels.OPTIONS[name] = {
            label = panel.labels[name],
            control = control,
            panel = panel
        }
    end

    local event = OnCreateSandboxOptions.events[page.name]
    if event then
        event:trigger(panel)
    end

    return panel
end

--- Gets option panel based on its name.
--- @param name string
--- @return CustomSandboxOptionsScreenPanel|nil
function OptionPanels.GetOptionPanel(name)
    local panel = OptionPanels.OPTION_PANELS[name]
    if panel then return panel end
    error("Option panel not found for name: " .. tostring(name))
end

--- Gets option by its name.
--- @param name string
--- @return table|nil
function OptionPanels.GetOption(name)
    local option = OptionPanels.OPTIONS[name]
    if option then return option end
    error("Option not found for name: " .. tostring(name))
end

return OptionPanels