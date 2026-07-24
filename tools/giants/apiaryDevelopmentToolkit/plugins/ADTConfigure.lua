-- Author:OpenAI + flynhigh20
-- Name:ADT Configure Plugin
-- Namespace: global
-- Description:Hidden plugin module for Apiary Development Toolkit.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTConfigure = {}
local ADTConfigure_mt = Class(ADTConfigure)

ADTConfigure.STANDARD_GROUPS = {
    "visuals",
    "collisions",
    "triggers",
    "particleEffects",
    "sounds",
    "interactionNodes"
}

function ADTConfigure.new(toolkit)
    local self = setmetatable({}, ADTConfigure_mt)
    self.toolkit = toolkit
    self.tabName = "Configure"
    return self
end

function ADTConfigure:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local targetSizer = UIRowLayoutSizer.new()
    fold:addPanel("Active target", targetSizer)
    self.targetLabel = UILabel.new(targetSizer, "Active target: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 50, BorderDirection.BOTTOM, 5)
    UIButton.new(targetSizer, "Refresh hierarchy status",
        function() self:updateStatus() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)

    local hierarchySizer = UIRowLayoutSizer.new()
    fold:addPanel("Standard child groups", hierarchySizer)
    UILabel.new(hierarchySizer,
        "Creates only missing direct child transform groups. Existing nodes are preserved and nothing is renamed, moved or deleted.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 55, BorderDirection.BOTTOM, 5)
    UIButton.new(hierarchySizer, "Create missing standard groups",
        function() self:createMissingGroups() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    self.statusLabel = UILabel.new(hierarchySizer, "Capture an active target on the Place tab first.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 145)

    local groupsSizer = UIRowLayoutSizer.new()
    fold:addPanel("Group layout", groupsSizer)
    UILabel.new(groupsSizer,
        "visuals - rendered meshes\ncollisions - collision shapes\ntriggers - interaction and fill triggers\nparticleEffects - smoke, bees, dust and other effects\nsounds - sound nodes\ninteractionNodes - wrench, hand, camera and activation nodes",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 130)

    self:updateStatus()
end

function ADTConfigure:getTarget()
    local target = self.toolkit.activeTarget
    if target == nil or not entityExists(target) then
        self.toolkit.activeTarget = nil
        return nil
    end
    return target
end

function ADTConfigure:findDirectChildByName(parent, name)
    for i=0, getNumOfChildren(parent)-1 do
        local child = getChildAt(parent, i)
        if entityExists(child) and getName(child) == name then
            return child
        end
    end
    return nil
end

function ADTConfigure:getHierarchyState(target)
    local present = {}
    local missing = {}

    for _, name in ipairs(ADTConfigure.STANDARD_GROUPS) do
        if self:findDirectChildByName(target, name) ~= nil then
            table.insert(present, name)
        else
            table.insert(missing, name)
        end
    end

    return present, missing
end

function ADTConfigure:updateStatus()
    if self.targetLabel == nil or self.statusLabel == nil then
        return
    end

    local target = self:getTarget()
    if target == nil then
        self.targetLabel:setText("Active target: none")
        self.statusLabel:setText("Capture an active target on the Place tab first.")
        return
    end

    self.targetLabel:setText(string.format("Active target: %s  |  node %s  |  %s",
        getName(target), tostring(target), self.toolkit:getNodeTypeLabel(target)))

    local present, missing = self:getHierarchyState(target)
    local presentText = #present > 0 and table.concat(present, ", ") or "none"
    local missingText = #missing > 0 and table.concat(missing, ", ") or "none"

    self.statusLabel:setText(string.format(
        "Present (%d): %s\nMissing (%d): %s\nDirect children currently under target: %d",
        #present, presentText, #missing, missingText, getNumOfChildren(target)))
end

function ADTConfigure:createMissingGroups()
    local target = self:getTarget()
    if target == nil then
        self.toolkit:logWarning("Capture an active target on the Place tab before configuring hierarchy.")
        self:updateStatus()
        return
    end

    local created = 0
    local preserved = 0

    for _, name in ipairs(ADTConfigure.STANDARD_GROUPS) do
        local existing = self:findDirectChildByName(target, name)
        if existing ~= nil then
            preserved = preserved + 1
        else
            local group = createTransformGroup(name)
            if group ~= nil and entityExists(group) then
                link(target, group)
                created = created + 1
            else
                self.toolkit:logError("Could not create transform group: " .. name, target)
            end
        end
    end

    refreshViewport(true)
    self:updateStatus()
    self.toolkit:logInfo(string.format(
        "Hierarchy configured under %s: created %d missing group(s), preserved %d existing group(s).",
        getName(target), created, preserved), target)
end

function ADTConfigure:onSelectionChanged(nodeId, isSelected)
    self:updateStatus()
end

function ADTConfigure:onTabOpen(previous)
    self:updateStatus()
end
