-- Author:OpenAI + flynhigh20
-- Name:ADT Place Plugin
-- Namespace: global
-- Description:Hidden plugin module for Apiary Development Toolkit.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTPlace = {}
local ADTPlace_mt = Class(ADTPlace)

local function formatVector(x, y, z)
    return string.format("%.4f, %.4f, %.4f", x or 0, y or 0, z or 0)
end

function ADTPlace.new(toolkit)
    local self = setmetatable({}, ADTPlace_mt)
    self.toolkit = toolkit
    self.tabName = "Place"

    if self.toolkit.activeTarget ~= nil and not entityExists(self.toolkit.activeTarget) then
        self.toolkit.activeTarget = nil
    end

    return self
end

function ADTPlace:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local selectionSizer = UIRowLayoutSizer.new()
    fold:addPanel("Current GIANTS Editor selection", selectionSizer)
    self.selectionLabel = UILabel.new(selectionSizer, "No node selected.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 55, BorderDirection.BOTTOM, 5)
    UIButton.new(selectionSizer, "Use current selection as active target",
        function() self:captureSelection() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)

    local targetSizer = UIRowLayoutSizer.new()
    fold:addPanel("Shared active target", targetSizer)
    self.targetLabel = UILabel.new(targetSizer, "Active target: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 55, BorderDirection.BOTTOM, 5)
    UIButton.new(targetSizer, "Refresh target details",
        function() self:updateLabels() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(targetSizer, "Clear active target",
        function() self:clearTarget() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)

    local detailsSizer = UIRowLayoutSizer.new()
    fold:addPanel("Target details", detailsSizer)
    self.detailsLabel = UILabel.new(detailsSizer,
        "Capture a node to view its parent, child count and local transform.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 155)

    local noteSizer = UIRowLayoutSizer.new()
    fold:addPanel("Workflow", noteSizer)
    UILabel.new(noteSizer,
        "The active target is shared through the toolkit. Later Configure, Validate, Debug and automatic emitter replacement tools can use the same captured node without requiring you to reselect it.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 70)

    self:updateLabels()
end

function ADTPlace:getValidTarget()
    local target = self.toolkit.activeTarget
    if target == nil or not entityExists(target) then
        self.toolkit.activeTarget = nil
        return nil
    end
    return target
end

function ADTPlace:captureSelection()
    local selected = self.toolkit:getPrimarySelection()
    if selected == nil or not entityExists(selected) then
        self.toolkit:logWarning("Select a node before capturing an active target.")
        self:updateLabels()
        return
    end

    self.toolkit.activeTarget = selected
    self.toolkit:logInfo("Active target captured: " .. getName(selected), selected)
    self:updateLabels()
end

function ADTPlace:clearTarget()
    local previous = self:getValidTarget()
    self.toolkit.activeTarget = nil

    if previous ~= nil then
        self.toolkit:logInfo("Active target cleared: " .. getName(previous), previous)
    else
        self.toolkit:setStatus("Active target cleared.")
    end

    self:updateLabels()
end

function ADTPlace:updateLabels()
    if self.selectionLabel == nil or self.targetLabel == nil or self.detailsLabel == nil then
        return
    end

    local selected = self.toolkit:getPrimarySelection()
    if selected == nil or not entityExists(selected) then
        self.selectionLabel:setText("No node selected.")
    else
        self.selectionLabel:setText(string.format("Selected: %s  |  node %s  |  %s",
            getName(selected), tostring(selected), self.toolkit:getNodeTypeLabel(selected)))
    end

    local target = self:getValidTarget()
    if target == nil then
        self.targetLabel:setText("Active target: none")
        self.detailsLabel:setText("Capture a node to view its parent, child count and local transform.")
        return
    end

    self.targetLabel:setText(string.format("Active target: %s  |  node %s  |  %s",
        getName(target), tostring(target), self.toolkit:getNodeTypeLabel(target)))

    local parent = getParent(target)
    local parentName = "scene root"
    local parentId = "none"
    if parent ~= nil and parent ~= 0 and entityExists(parent) then
        parentName = getName(parent)
        parentId = tostring(parent)
    end

    local tx, ty, tz = getTranslation(target)
    local rx, ry, rz = getRotation(target)
    local sx, sy, sz = getScale(target)

    self.detailsLabel:setText(string.format(
        "Parent: %s  |  node %s\nChildren: %d\nTranslation: %s\nRotation: %s\nScale: %s",
        parentName,
        parentId,
        getNumOfChildren(target),
        formatVector(tx, ty, tz),
        formatVector(rx, ry, rz),
        formatVector(sx, sy, sz)))
end

function ADTPlace:onSelectionChanged(nodeId, isSelected)
    self:updateLabels()
end

function ADTPlace:onTabOpen(previous)
    self:updateLabels()
end
