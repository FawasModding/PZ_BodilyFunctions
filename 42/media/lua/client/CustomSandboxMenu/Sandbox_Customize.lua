-- Sandbox_Customize.lua

--- DEFINITIONS
---@class CustomizeSandboxOptionPanel
local CustomizeSandboxOptionPanel = {}

---@class BaseColor
---@field r number
---@field g number
---@field b number
---@field a number

--- REQUIREMENTS
local OptionPanels = require "CustomSandboxMenu/Sandbox_Patch"
CustomizeSandboxOptionPanel.GetOptionPanel = OptionPanels.GetOptionPanel
CustomizeSandboxOptionPanel.GetOption = OptionPanels.GetOption


--- CACHING
-- ui size
local UI_BORDER_SPACING = 10


---Retrieves the total 
---@param panel SandboxOptionsScreenPanel
CustomizeSandboxOptionPanel.GetTotalOptionDimensions = function(panel)
    -- get y
    local titles = panel.titles
    local controls = panel.controls
    local labels = panel.labels
    local y = 11
    local i = 1

    -- intercept other coordinates
    local width = 0
    local x = 0

    for name,control in pairs(controls) do
        if titles[i] then
            y = titles[i].yShift -- it's not the one associated to control, but we don't really care here bcs we look for total y
        end
        local label = labels[name]
        y = y + math.max(label:getHeight(), control:getHeight()) + UI_BORDER_SPACING

        i = i + 1

        local control_rightSide = control.x + control.width
        local label_leftSide = label.x

        width = math.max(width, control_rightSide - label_leftSide)
        x = math.max(x, label_leftSide)

        -- pimp control
        control.backgroundColor = {r=1,g=0.80,b=0,a=0.5}
        control.borderColor = {r=1,g=0.80,b=0,a=1}
    end

    -- Account for custom UI elements (e.g., headers)
    if panel.customUI then
        for _, ui in ipairs(panel.customUI) do
            y = y + ui.element:getHeight() + UI_BORDER_SPACING
        end
    end

    return x,y,width
end


--[[ ================================================ ]]--
--- CUSTOMIZE SandboxOptionPanel ---
--[[ ================================================ ]]--

---Sets the color of the panel.
---@param panel SandboxOptionsScreenPanel
---@param borderColor BaseColor
---@param backgroundColor BaseColor
CustomizeSandboxOptionPanel.SetPanelColor = function(panel, borderColor, backgroundColor)
    if not panel then
        error("Panel cannot be nil.")
    end
    panel.borderColor = borderColor or panel.borderColor
    panel.backgroundColor = backgroundColor or panel.backgroundColor
end

---Sets the height of the scroll bar. Usually based on the lowest point reached by entries in the panel.
---@param panel SandboxOptionsScreenPanel
---@param height integer
CustomizeSandboxOptionPanel.SetScrollBarHeight = function(panel,height)
    panel:setScrollHeight(height)
end

--- Inserts a custom UI element between two existing options.
---@param panel SandboxOptionsScreenPanel
---@param optionKeyTop string  -- Option key above the element
---@param optionKeyBottom string  -- Option key below the element
---@param elementHeight number
---@param addElementCallback fun(x:number, y:number):UIElement  -- Function that adds your element and returns it
CustomizeSandboxOptionPanel.InsertElementBetweenOptions = function(panel, optionKeyTop, optionKeyBottom, elementHeight, addElementCallback)
    local top = CustomizeSandboxOptionPanel.GetOption(optionKeyTop)
    local bottom = CustomizeSandboxOptionPanel.GetOption(optionKeyBottom)

    if not top or not bottom or not top.label or not bottom.label then
        print("Error: Missing labels or options for insertion between " .. optionKeyTop .. " and " .. optionKeyBottom)
        return
    end

    local spacing = UI_BORDER_SPACING
    local insertY = top.label:getY() + top.label:getHeight() + spacing
    local x, _, width = CustomizeSandboxOptionPanel.GetTotalOptionDimensions(panel)

    -- Add your custom element
    local element = addElementCallback(x, insertY)
    table.insert(panel.customUI, {
        element = element,
        position = "between",
        optionTop = optionKeyTop,
        optionBottom = optionKeyBottom
    })

    -- Shift everything below the *bottom* option
    local shiftFromY = bottom.label:getY()
    local shiftY = elementHeight + spacing

    for name, control in pairs(panel.controls) do
        local label = panel.labels[name]
        if label and control and label:getY() >= shiftFromY then
            label:setY(label:getY() + shiftY)
            control:setY(control:getY() + shiftY)
        end
    end

    -- Resize scroll height
    local _, y = CustomizeSandboxOptionPanel.GetTotalOptionDimensions(panel)
    CustomizeSandboxOptionPanel.SetScrollBarHeight(panel, y + UI_BORDER_SPACING)
end



return CustomizeSandboxOptionPanel