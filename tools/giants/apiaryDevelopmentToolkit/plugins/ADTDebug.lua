-- Author:OpenAI + flynhigh20
-- Name:ADT Debug Plugin
-- Namespace: global
-- Description:Hidden plugin module for Apiary Development Toolkit.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTDebug = {}
local ADTDebug_mt = Class(ADTDebug)

local function formatVector(x, y, z)
    return string.format("%.4f, %.4f, %.4f", x or 0, y or 0, z or 0)
end

function ADTDebug.new(toolkit)
    local self = setmetatable({}, ADTDebug_mt)
    self.toolkit = toolkit
    self.tabName = "Debug"
    return self
end

function ADTDebug:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local contextSizer = UIRowLayoutSizer.new()
    fold:addPanel("Diagnostic context", contextSizer)
    self.selectionLabel = UILabel.new(contextSizer, "Current selection: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 42, BorderDirection.BOTTOM, 5)
    self.targetLabel = UILabel.new(contextSizer, "Active target: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 42, BorderDirection.BOTTOM, 5)
    UIButton.new(contextSizer, "Refresh diagnostic panel", function() self:updateLabels() end,
        nil, -1, -1, -1, 28)

    local summarySizer = UIRowLayoutSizer.new()
    fold:addPanel("Live node summary", summarySizer)
    self.summaryLabel = UILabel.new(summarySizer,
        "Select a node or capture an active target to inspect it.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 170)

    local printSizer = UIRowLayoutSizer.new()
    fold:addPanel("Console and log output", printSizer)
    UIButton.new(printSizer, "Print current selection details",
        function() self:printSelection() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(printSizer, "Print active target details",
        function() self:printActiveTarget() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(printSizer, "Print current selection hierarchy",
        function() self:printHierarchy(self.toolkit:getPrimarySelection(), "selection") end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(printSizer, "Print active target hierarchy",
        function() self:printHierarchy(self:getActiveTarget(), "active target") end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(printSizer, "Print recursive material summary",
        function() self:printMaterialSummary() end,
        nil, -1, -1, -1, 28)

    local checksSizer = UIRowLayoutSizer.new()
    fold:addPanel("Quick checks", checksSizer)
    UIButton.new(checksSizer, "Check duplicate direct-child names",
        function() self:checkDuplicateChildNames() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(checksSizer, "Check invalid transforms recursively",
        function() self:checkInvalidTransforms() end,
        nil, -1, -1, -1, 28)

    self:updateLabels()
end

function ADTDebug:getActiveTarget()
    local target = self.toolkit.activeTarget
    if target == nil or not entityExists(target) then
        self.toolkit.activeTarget = nil
        return nil
    end
    return target
end

function ADTDebug:getContextNode()
    return self.toolkit:getPrimarySelection() or self:getActiveTarget()
end

function ADTDebug:getNodeSummary(node)
    if node == nil or not entityExists(node) then
        return "No valid diagnostic node."
    end

    local parent = getParent(node)
    local parentName = "scene root"
    local parentId = "none"
    if parent ~= nil and parent ~= 0 and entityExists(parent) then
        parentName = getName(parent)
        parentId = tostring(parent)
    end

    local tx, ty, tz = getTranslation(node)
    local rx, ry, rz = getRotation(node)
    local sx, sy, sz = getScale(node)
    local wx, wy, wz = getWorldTranslation(node)
    local shapes = self.toolkit:collectShapes(node)
    local materialSlots = 0
    local uniqueMaterials = {}
    for _, shape in ipairs(shapes) do
        local count = getNumOfMaterials(shape)
        materialSlots = materialSlots + count
        for slot=0, count-1 do
            uniqueMaterials[getMaterial(shape, slot)] = true
        end
    end
    local uniqueCount = 0
    for _ in pairs(uniqueMaterials) do
        uniqueCount = uniqueCount + 1
    end

    return string.format(
        "Node: %s  |  id %s  |  %s\nParent: %s  |  id %s\nDirect children: %d\nRecursive shapes: %d\nMaterial slots: %d  |  unique materials: %d\nLocal translation: %s\nLocal rotation: %s\nLocal scale: %s\nWorld translation: %s",
        getName(node), tostring(node), self.toolkit:getNodeTypeLabel(node),
        parentName, parentId, getNumOfChildren(node), #shapes, materialSlots, uniqueCount,
        formatVector(tx, ty, tz), formatVector(rx, ry, rz), formatVector(sx, sy, sz),
        formatVector(wx, wy, wz))
end

function ADTDebug:updateLabels()
    if self.selectionLabel == nil or self.targetLabel == nil or self.summaryLabel == nil then
        return
    end

    local selected = self.toolkit:getPrimarySelection()
    if selected == nil or not entityExists(selected) then
        self.selectionLabel:setText("Current selection: none")
    else
        self.selectionLabel:setText(string.format("Current selection: %s  |  id %s  |  %s",
            getName(selected), tostring(selected), self.toolkit:getNodeTypeLabel(selected)))
    end

    local target = self:getActiveTarget()
    if target == nil then
        self.targetLabel:setText("Active target: none")
    else
        self.targetLabel:setText(string.format("Active target: %s  |  id %s  |  %s",
            getName(target), tostring(target), self.toolkit:getNodeTypeLabel(target)))
    end

    self.summaryLabel:setText(self:getNodeSummary(selected or target))
end

function ADTDebug:printNode(node, label)
    if node == nil or not entityExists(node) then
        self.toolkit:logWarning("No valid " .. label .. " is available for debugging.")
        return
    end
    print("ADT DEBUG " .. string.upper(label))
    print(self:getNodeSummary(node))
    self.toolkit:setStatus(label .. " details printed to console/log.")
end

function ADTDebug:printSelection()
    self:printNode(self.toolkit:getPrimarySelection(), "current selection")
end

function ADTDebug:printActiveTarget()
    self:printNode(self:getActiveTarget(), "active target")
end

function ADTDebug:printHierarchy(root, label)
    if root == nil or not entityExists(root) then
        self.toolkit:logWarning("No valid " .. label .. " is available for hierarchy output.")
        return
    end

    local count = 0
    local function visit(node, depth)
        count = count + 1
        print(string.rep("  ", depth) .. string.format("%s [%s] {%s}",
            getName(node), tostring(node), self.toolkit:getNodeTypeLabel(node)))
        for i=0, getNumOfChildren(node)-1 do
            visit(getChildAt(node, i), depth+1)
        end
    end
    visit(root, 0)
    self.toolkit:setStatus(string.format("Printed %d node(s) from %s hierarchy.", count, label))
end

function ADTDebug:printMaterialSummary()
    local root = self:getContextNode()
    if root == nil then
        self.toolkit:logWarning("Select a node or capture an active target first.")
        return
    end

    local shapes = self.toolkit:collectShapes(root)
    local slots = 0
    local unique = {}
    for _, shape in ipairs(shapes) do
        local count = getNumOfMaterials(shape)
        slots = slots + count
        print(string.format("ADT MATERIAL SHAPE %s [%s] slots=%d", getName(shape), tostring(shape), count))
        for slot=0, count-1 do
            local materialId = getMaterial(shape, slot)
            unique[materialId] = true
            print(string.format("  slot=%d material=%s", slot, self.toolkit:getMaterialDisplayName(materialId)))
        end
    end
    local uniqueCount = 0
    for _ in pairs(unique) do uniqueCount = uniqueCount + 1 end
    self.toolkit:setStatus(string.format("%s contains %d shape(s), %d slot(s), and %d unique material(s).",
        getName(root), #shapes, slots, uniqueCount))
end

function ADTDebug:checkDuplicateChildNames()
    local root = self:getContextNode()
    if root == nil then
        self.toolkit:logWarning("Select a node or capture an active target first.")
        return
    end

    local names = {}
    local duplicates = 0
    for i=0, getNumOfChildren(root)-1 do
        local child = getChildAt(root, i)
        local name = getName(child)
        if names[name] ~= nil then
            duplicates = duplicates + 1
            print(string.format("ADT DUPLICATE CHILD NAME: %s nodes=%s,%s parent=%s",
                name, tostring(names[name]), tostring(child), getName(root)))
        else
            names[name] = child
        end
    end
    self.toolkit:setStatus(string.format("Duplicate-name check complete: %d duplicate direct-child name(s) under %s.",
        duplicates, getName(root)))
end

function ADTDebug:checkInvalidTransforms()
    local root = self:getContextNode()
    if root == nil then
        self.toolkit:logWarning("Select a node or capture an active target first.")
        return
    end

    local checked = 0
    local invalid = 0
    local function isBad(value)
        return value ~= value or value == math.huge or value == -math.huge
    end
    local function visit(node)
        checked = checked + 1
        local tx, ty, tz = getTranslation(node)
        local rx, ry, rz = getRotation(node)
        local sx, sy, sz = getScale(node)
        if isBad(tx) or isBad(ty) or isBad(tz) or isBad(rx) or isBad(ry) or isBad(rz)
            or isBad(sx) or isBad(sy) or isBad(sz) or sx == 0 or sy == 0 or sz == 0 then
            invalid = invalid + 1
            print(string.format("ADT INVALID TRANSFORM: %s [%s] T=(%s) R=(%s) S=(%s)",
                getName(node), tostring(node), formatVector(tx, ty, tz), formatVector(rx, ry, rz), formatVector(sx, sy, sz)))
        end
        for i=0, getNumOfChildren(node)-1 do
            visit(getChildAt(node, i))
        end
    end
    visit(root)
    self.toolkit:setStatus(string.format("Transform check complete: %d node(s) checked, %d suspicious transform(s).",
        checked, invalid))
end

function ADTDebug:onSelectionChanged(nodeId, isSelected)
    self:updateLabels()
end

function ADTDebug:onTabOpen(previous)
    self:updateLabels()
end
