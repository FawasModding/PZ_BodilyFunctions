require "ISUI/ISPanelJoypad"

BathroomCharacterInfo_GUIHandler = ISPanelJoypad:derive("BathroomCharacterInfo_GUIHandler")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local WINDOW_WIDTH = 500
local WINDOW_HEIGHT = 200
local UI_BORDER_SPACING = 10
local BAR_HEIGHT = 10

local x = UI_BORDER_SPACING
local y = UI_BORDER_SPACING

function BathroomCharacterInfo_GUIHandler:initialise()
    ISPanelJoypad.initialise(self);
end

function BathroomCharacterInfo_GUIHandler:createChildren()
    -- Clear existing children to prevent duplicates
    self:clearChildren()

    if not SandboxVars.BF then return end

    self:setScrollChildren(true)
    self:addScrollBars()

    local barStartPosition = UI_BORDER_SPACING
    local barEndPosition = WINDOW_WIDTH - UI_BORDER_SPACING
    local barLength = barEndPosition - barStartPosition
    local highlightRadius = 20

    local minLabelX = UI_BORDER_SPACING

    local urinationBarGradient = getTexture("media/ui/GradientBars/UrinationBar.png")
    if not urinationBarGradient then
        urinationBarGradient = getTexture("media/ui/default.png") -- fallback texture
    end
    local defecationBarGradient = getTexture("media/ui/GradientBars/DefecationBar.png")
    if not defecationBarGradient then
        defecationBarGradient = getTexture("media/ui/default.png") -- fallback texture
    end

    self.TextColor = { r = 1, g = 1, b = 1, a = 1 }
    self.DimmedTextColor = { r = 0.7, g = 0.7, b = 0.7, a = 1 }

    local textManager = getTextManager()
    local font = UIFont.Small
    if not textManager:getFontHeight(font) then
        print("Warning: UIFont.Small not found, using fallback font")
        font = UIFont.Medium
    end

    -- Bladder Section
    local str = getText("Bladder Fullness")
    self.labelBladder = ISLabel:new(barStartPosition + barLength / 2 - textManager:MeasureStringX(font, str) / 2, y, FONT_HGT_SMALL, str, self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, font, true)
    self:addChild(self.labelBladder)
    y = y + FONT_HGT_SMALL + 5

    -- Add "Empty" and "Full" labels for bladder bar
    local bladderEmptyStr = "Empty"
    local bladderEmptyWidth = textManager:MeasureStringX(font, bladderEmptyStr)
    local bladderEmptyX = math.max(minLabelX, barStartPosition) -- Ensure not off-screen
    self.labelBladderEmpty = ISLabel:new(bladderEmptyX, y - FONT_HGT_SMALL, FONT_HGT_SMALL, bladderEmptyStr, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, font, false)
    self:addChild(self.labelBladderEmpty)

    local bladderFullStr = "Full"
    local bladderFullX = barEndPosition - textManager:MeasureStringX(font, bladderFullStr)
    self.labelBladderFull = ISLabel:new(bladderFullX, y - FONT_HGT_SMALL, FONT_HGT_SMALL, bladderFullStr, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, font, false)
    self:addChild(self.labelBladderFull)

    self.bladderBar = ISGradientBar:new(barStartPosition, y, barLength, BAR_HEIGHT)
    self.bladderBar:setGradientTexture(urinationBarGradient)
    self.bladderBar:setHighlightRadius(highlightRadius)
    self.bladderBar:setDoKnob(false)
    self:addChild(self.bladderBar)
    y = y + BAR_HEIGHT + UI_BORDER_SPACING

    self.labelBladderValue = ISLabel:new(barStartPosition + barLength / 2, y, FONT_HGT_SMALL, "0%", self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, font, true)
    self.labelBladderValue.center = true
    self:addChild(self.labelBladderValue)
    y = y + FONT_HGT_SMALL + UI_BORDER_SPACING

    -- Bowel Section
    str = getText("Bowels Fullness")
    self.labelBowel = ISLabel:new(barStartPosition + barLength / 2 - textManager:MeasureStringX(font, str) / 2, y, FONT_HGT_SMALL, str, self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, font, true)
    self:addChild(self.labelBowel)
    y = y + FONT_HGT_SMALL + 5

    -- Add "Empty" and "Full" labels for bowel bar
    local bowelEmptyStr = "Empty"
    local bowelEmptyWidth = textManager:MeasureStringX(font, bowelEmptyStr)
    local bowelEmptyX = math.max(minLabelX, barStartPosition)
    self.labelBowelEmpty = ISLabel:new(bowelEmptyX, y - FONT_HGT_SMALL, FONT_HGT_SMALL, bowelEmptyStr, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, font, false)
    self:addChild(self.labelBowelEmpty)

    local bowelFullStr = "Full"
    local bowelFullX = barEndPosition - textManager:MeasureStringX(font, bowelFullStr)
    self.labelBowelFull = ISLabel:new(bowelFullX, y - FONT_HGT_SMALL, FONT_HGT_SMALL, bowelFullStr, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, font, false)
    self:addChild(self.labelBowelFull)

    self.bowelBar = ISGradientBar:new(barStartPosition, y, barLength, BAR_HEIGHT)
    self.bowelBar:setGradientTexture(defecationBarGradient)
    self.bowelBar:setHighlightRadius(highlightRadius)
    self.bowelBar:setDoKnob(false)
    self:addChild(self.bowelBar)
    y = y + BAR_HEIGHT + UI_BORDER_SPACING

    self.labelBowelValue = ISLabel:new(barStartPosition + barLength / 2, y, FONT_HGT_SMALL, "0%", self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, font, true)
    self.labelBowelValue.center = true
    self:addChild(self.labelBowelValue)
    y = y + FONT_HGT_SMALL + UI_BORDER_SPACING

    -- Icons
    self.iconBladder = getTexture("media/ui/Urination.png")
    if not self.iconBladder then
        print("Warning: Bladder icon 'media/ui/Urination.png' not found")
    end
    self.iconBowel = getTexture("media/ui/Defecation.png")
    if not self.iconBowel then
        print("Warning: Bowel icon 'media/ui/Defecation.png' not found")
    end
    self.iconSize = 24 -- Reduced size to fit beside headers
    local bladderHeaderX = barStartPosition + barLength / 2 - textManager:MeasureStringX(font, getText("Bladder Fullness")) / 2
    local bowelHeaderX = barStartPosition + barLength / 2 - textManager:MeasureStringX(font, getText("Bowels Fullness")) / 2
    self.iconBladderX = bladderHeaderX - self.iconSize - UI_BORDER_SPACING -- Left of Bladder Fullness
    self.iconBladderY = UI_BORDER_SPACING -- Align with Bladder Fullness header
    self.iconBowelX = bowelHeaderX - self.iconSize - UI_BORDER_SPACING -- Left of Bowels Fullness
    self.iconBowelY = self.iconBladderY + FONT_HGT_SMALL + 5 + BAR_HEIGHT + UI_BORDER_SPACING + FONT_HGT_SMALL + 5 -- Align with Bowels Fullness header

    WINDOW_HEIGHT = y + FONT_HGT_SMALL * 2
end

function BathroomCharacterInfo_GUIHandler:setVisible(visible)
    self.javaObject:setVisible(visible)
end

function BathroomCharacterInfo_GUIHandler:prerender()
    ISPanelJoypad.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)
end

local function updateBar(bar, value)
    if bar then
        bar:setValue(value)
    end
end

local function updateLabel(label, value)
    if label then
        label:setName(value)
    end
end

function BathroomCharacterInfo_GUIHandler:render()
    self:setWidthAndParentWidth(WINDOW_WIDTH)
    self:setHeightAndParentHeight(WINDOW_HEIGHT)

    if SandboxVars.BF then
        local bladderMax = SandboxVars.BF.BladderMaxValue or 100
        local bowelsMax = SandboxVars.BF.BowelsMaxValue or 100

        local bladderValue = BF.GetUrinateValue() or 0
        local bladderPercent = bladderValue / bladderMax
        updateBar(self.bladderBar, bladderPercent)
        updateLabel(self.labelBladderValue, string.format("%.1f%%", bladderPercent * 100))

        local bowelValue = BF.GetDefecateValue() or 0
        local bowelPercent = bowelValue / bowelsMax
        updateBar(self.bowelBar, bowelPercent)
        updateLabel(self.labelBowelValue, string.format("%.1f%%", bowelPercent * 100))

        if self.iconBladder then
            self:drawTextureScaled(self.iconBladder, self.iconBladderX, self.iconBladderY, self.iconSize, self.iconSize, 1, 1, 1, 1)
        end
        if self.iconBowel then
            self:drawTextureScaled(self.iconBowel, self.iconBowelX, self.iconBowelY, self.iconSize, self.iconSize, 1, 1, 1, 1)
        end
    else
        self:drawText(getText("UI_Bathroom_Disabled"), UI_BORDER_SPACING, UI_BORDER_SPACING, 1, 1, 1, 1)
    end

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