---@diagnostic disable: duplicate-set-field

local modInfoTCH = getModInfoByID("TchernoLib")
if modInfoTCH and isModActive(modInfoTCH) then
    --use the version from TchernoLib instead
    require 'UI/CharacterInfoAddTab'
    return
end

function addCharacterPageTab(tabName,pageType)

    local viewName = tabName.."View"

local upperLayer_ISCharacterInfoWindow_createChildren = ISCharacterInfoWindow.createChildren
function ISCharacterInfoWindow:createChildren()
    upperLayer_ISCharacterInfoWindow_createChildren(self)
    
    self[viewName] = pageType:new(0, 8, self.width, self.height-8, self.playerNum)
    self[viewName]:initialise()
    self[viewName].infoText = getText("UI_"..tabName.."Panel");--UI_<tabName>Panel is full text of tooltip
    self.panel:addView(getText("UI_"..tabName), self[viewName])--UI_<tabName> is short text of tab
end

local upperLayer_ISCharacterInfoWindow_onTabTornOff = ISCharacterInfoWindow.onTabTornOff
function ISCharacterInfoWindow:onTabTornOff(view, window)
    if self.playerNum == 0 and view == self[viewName] then
        ISLayoutManager.RegisterWindow('charinfowindow.'..tabName, ISCollapsableWindow, window)
    end
    upperLayer_ISCharacterInfoWindow_onTabTornOff(self, view, window)

end

--function ISCharacterInfoWindow:RestoreLayout(name, layout)
--end

local upperLayer_ISCharacterInfoWindow_SaveLayout = ISCharacterInfoWindow.SaveLayout
function ISCharacterInfoWindow:SaveLayout(name, layout)
    upperLayer_ISCharacterInfoWindow_SaveLayout(self,name,layout)
    
    local addTabName = false
    if self[viewName].parent == self.panel then
        addTabName = true
        if self[viewName] == self.panel:getActiveView() then
            layout.current = tabName
        end
    end
    if addTabName then
        if not layout.tabs then
            layout.tabs = tabName 
        else
            layout.tabs = layout.tabs .. ',' .. tabName
        end
    end
end

end

