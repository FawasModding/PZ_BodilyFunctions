require "ISUI/ISPanelJoypad"

BathroomCharacterInfo_GUIHandler = ISPanelJoypad:derive("BathroomCharacterInfo_GUIHandler");

function BathroomCharacterInfo_GUIHandler:initialise()
    ISPanelJoypad.initialise(self);
end

function BathroomCharacterInfo_GUIHandler:createChildren()
    self:setScrollChildren(true)
    self:addScrollBars()
end

function BathroomCharacterInfo_GUIHandler:setVisible(visible)
    self.javaObject:setVisible(visible);
end

function BathroomCharacterInfo_GUIHandler:prerender()
    ISPanelJoypad.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)
end

function BathroomCharacterInfo_GUIHandler:render()
    ISPanelJoypad.render(self)

    local textManager = getTextManager()
    local smallFont = UIFont.Small

    local bladderMaxValue = SandboxVars.BathroomFunctions.BladderMaxValue or 100 -- Get the max bladder value, default to 100 if not set
    local bowelsMaxValue = SandboxVars.BathroomFunctions.BowelsMaxValue or 100 -- Get the max bowels value, default to 100 if not set

    local maxTextWidth = 0

    -- Initial Y position
    local textX = 20
    local iconX = 20
    local iconY = 20
    local textY = iconY + 64 + 5 -- Add 5 pixels of padding below the icon

    -- Urination Icon and Text
    local urinationIcon = getTexture("media/ui/Urination.png")
    if urinationIcon then
        -- Scale the image
        local scaledWidth = 64
        local scaledHeight = 64

        -- Draw the scaled image
        self:drawTextureScaled(urinationIcon, iconX, iconY, scaledWidth, scaledHeight, 1, 1, 1, 1)
    end

    -- Display the urination text
    local urinationValue = (BathroomFunctions.GetUrinateValue() / bladderMaxValue) * 100
    local urinationText = "Bladder Contents: " .. string.format("%.1f", urinationValue) .. "%"  -- Round to one decimal place
    self:drawText(urinationText, textX, textY, 1, 1, 1, 1, smallFont)

    -- Update maxTextWidth with the width of the urination text
    local urinationTextWidth = textManager:MeasureStringX(smallFont, urinationText)
    if urinationTextWidth > maxTextWidth then
        maxTextWidth = urinationTextWidth
    end

    -- Update iconY and textY
    iconY = textY + 20 + 10 -- Add spacing between urination text and def icon (10 pixels padding)
    textY = iconY + 64 + 5 -- Reset textY for def section

    -- Defecation Icon and Text
    local defecationIcon = getTexture("media/ui/Defecation.png")
    if defecationIcon then
        -- Scale the image
        local scaledWidth = 64
        local scaledHeight = 64

        -- Draw the scaled image
        self:drawTextureScaled(defecationIcon, iconX, iconY, scaledWidth, scaledHeight, 1, 1, 1, 1)
    end

    -- Display the defecation text
    local defecationValue = (BathroomFunctions.GetDefecateValue() / bowelsMaxValue) * 100
    local defecationText = "Bowel Contents: " .. string.format("%.1f", defecationValue) .. "%"  -- Round to one decimal place
    self:drawText(defecationText, textX, textY, 1, 1, 1, 1, smallFont)

    -- Update maxTextWidth with the width of the defecation text
    local defecationTextWidth = textManager:MeasureStringX(smallFont, defecationText)
    if defecationTextWidth > maxTextWidth then
        maxTextWidth = defecationTextWidth
    end

    local widthRequired = textX * 2 + maxTextWidth
    if widthRequired > self:getWidth() then
        self:setWidthAndParentWidth(widthRequired)
    end

    local tabHeight = self.y
    local maxHeight = getCore():getScreenHeight() - tabHeight - 30
    if ISWindow and ISWindow.TitleBarHeight then 
        maxHeight = maxHeight - ISWindow.TitleBarHeight 
    end

    -- Increase the height by 20 pixels, kind of a fucked up way to do it but y'know, I'm a fucked up person
    textY = textY + 40

    self:setHeightAndParentHeight(math.min(textY, maxHeight))
    self:setScrollHeight(textY)

    self:clearStencilRect()
end


function BathroomCharacterInfo_GUIHandler:onMouseWheel(del)
    self:setYScroll(self:getYScroll() - del * 30)
    return true
end

function BathroomCharacterInfo_GUIHandler:new(x, y, width, height, playerNum)
    local o = {}
    o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum
    o.char = getSpecificPlayer(playerNum)
    o:noBackground()

    BathroomCharacterInfo_GUIHandler.instance = o
    return o
end

addCharacterPageTab("BodilyFunctions", BathroomCharacterInfo_GUIHandler)