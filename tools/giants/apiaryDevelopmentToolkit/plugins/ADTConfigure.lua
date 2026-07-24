-- Author:OpenAI + flynhigh20
-- Name:ADT Configure Plugin
-- Namespace: global
-- Description:Hidden plugin module for Apiary Development Toolkit.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTConfigure = {}
local ADTConfigure_mt = Class(ADTConfigure)
function ADTConfigure.new(toolkit)
    local self = setmetatable({}, ADTConfigure_mt)
    self.toolkit = toolkit
    self.tabName = "Configure"
    return self
end
function ADTConfigure:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
    local sizer = UIRowLayoutSizer.new()
    fold:addPanel("Apiary hierarchy", sizer)
    UILabel.new(sizer, "Next milestone: create standard groups for visuals, collisions, triggers, bee effects, sounds and interaction nodes.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 70)
end
