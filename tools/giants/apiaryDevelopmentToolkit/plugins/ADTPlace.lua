-- Author:OpenAI + flynhigh20
-- Name:ADT Place Plugin
-- Namespace: global
-- Description:Hidden plugin module for Apiary Development Toolkit.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTPlace = {}
local ADTPlace_mt = Class(ADTPlace)
function ADTPlace.new(toolkit)
    local self = setmetatable({}, ADTPlace_mt)
    self.toolkit = toolkit
    self.tabName = "Place"
    return self
end
function ADTPlace:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
    local sizer = UIRowLayoutSizer.new()
    fold:addPanel("Hive placement", sizer)
    UILabel.new(sizer, "Next milestone: clone selected hive into rows/columns with spacing, numbering and optional alternating rotation.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 70)
end
