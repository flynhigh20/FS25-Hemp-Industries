-- Author:OpenAI + flynhigh20
-- Name:ADT Materials Plugin
-- Namespace: global
-- Description:Hidden plugin module for Apiary Development Toolkit.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTMaterials = {}
local ADTMaterials_mt = Class(ADTMaterials)

function ADTMaterials.new(toolkit)
    local self = setmetatable({}, ADTMaterials_mt)
    self.toolkit = toolkit
    self.tabName = "Materials"
    self.capturedMaterial = nil
    self.capturedSlot = 0
    self.capturedSource = nil
    return self
end

function ADTMaterials:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local contextSizer = UIRowLayoutSizer.new()
    fold:addPanel("Material source and destination", contextSizer)
    self.selectionLabel = UILabel.new(contextSizer,
        "Current selection: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 42, BorderDirection.BOTTOM, 5)
    self.targetLabel = UILabel.new(contextSizer,
        "Active target: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 42, BorderDirection.BOTTOM, 5)
    UIButton.new(contextSizer, "Inspect current selection recursively",
        function() self:inspectSelection() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(contextSizer, "Inspect active target recursively",
        function() self:inspectActiveTarget() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)

    local captureSizer = UIRowLayoutSizer.new()
    fold:addPanel("Capture material", captureSizer)
    local slotSizer = UIColumnLayoutSizer.new()
    UIPanel.new(captureSizer, slotSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    UILabel.new(slotSizer, "Material slot", false, TextAlignment.LEFT, VerticalAlignment.CENTER,
        -1, -1, 140, 25, BorderDirection.RIGHT, 5)
    self.slotInput = UITextArea.new(slotSizer, "0", TextAlignment.LEFT, false, false,
        -1, -1, 100, 25)

    UIButton.new(captureSizer, "Capture from current selection",
        function() self:captureMaterial() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(captureSizer, "Clear captured material",
        function() self:clearCapturedMaterial() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    self.captureLabel = UILabel.new(captureSizer, "Captured material: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 50)

    local applySizer = UIRowLayoutSizer.new()
    fold:addPanel("Preview and apply", applySizer)
    UIButton.new(applySizer, "Preview active target changes",
        function() self:previewActiveTarget() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    self.previewLabel = UILabel.new(applySizer,
        "Preview: capture a material and active target first.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 55, BorderDirection.BOTTOM, 5)
    UIButton.new(applySizer, "Apply captured material to active target",
        function() self:applyToActiveTarget() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(applySizer, "Apply captured material to current selection",
        function() self:applyToCurrentSelection() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)

    local noteSizer = UIRowLayoutSizer.new()
    fold:addPanel("Safety", noteSizer)
    UILabel.new(noteSizer,
        "Only the chosen material slot is changed. Groups are expanded recursively, shapes without that slot are skipped, and no nodes are renamed, moved or deleted. Save the I3D before applying bulk changes.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 70)

    self:updateContextLabels()
end

function ADTMaterials:getSlot()
    local slot = tonumber(self.slotInput:getValue()) or 0
    return math.max(0, math.floor(slot))
end

function ADTMaterials:getActiveTarget()
    local target = self.toolkit.activeTarget
    if target == nil or not entityExists(target) then
        self.toolkit.activeTarget = nil
        return nil
    end
    return target
end

function ADTMaterials:updateContextLabels()
    if self.selectionLabel == nil or self.targetLabel == nil then
        return
    end

    local primary = self.toolkit:getPrimarySelection()
    if primary == nil or not entityExists(primary) then
        self.selectionLabel:setText("Current selection: none")
    else
        local shapes = self.toolkit:collectShapes(primary)
        self.selectionLabel:setText(string.format("Current selection: %s  |  %s  |  %d shape(s)",
            getName(primary), self.toolkit:getNodeTypeLabel(primary), #shapes))
    end

    local target = self:getActiveTarget()
    if target == nil then
        self.targetLabel:setText("Active target: none - capture one on the Place tab")
    else
        local shapes = self.toolkit:collectShapes(target)
        self.targetLabel:setText(string.format("Active target: %s  |  %s  |  %d shape(s)",
            getName(target), self.toolkit:getNodeTypeLabel(target), #shapes))
    end
end

function ADTMaterials:inspectRoot(root, contextLabel)
    if root == nil or not entityExists(root) then
        self.toolkit:logWarning("No valid " .. contextLabel .. " is available for material inspection.")
        return
    end

    local shapes = self.toolkit:collectShapes(root)
    if #shapes == 0 then
        self.toolkit:logWarning("No shape nodes were found under " .. getName(root), root)
        return
    end

    local totalSlots = 0
    for _, shape in ipairs(shapes) do
        local count = getNumOfMaterials(shape)
        totalSlots = totalSlots + count
        print(string.format("ADT Materials: shape=%s node=%s slots=%d", getName(shape), tostring(shape), count))
        for slot=0, count-1 do
            local materialId = getMaterial(shape, slot)
            print(string.format("  slot=%d material=%s", slot, self.toolkit:getMaterialDisplayName(materialId)))
        end
    end

    self.toolkit:logInfo(string.format("%s contains %d shape(s) and %d total material slot(s).",
        getName(root), #shapes, totalSlots), root)
end

function ADTMaterials:inspectSelection()
    self:inspectRoot(self.toolkit:getPrimarySelection(), "current selection")
end

function ADTMaterials:inspectActiveTarget()
    self:inspectRoot(self:getActiveTarget(), "active target")
end

function ADTMaterials:captureMaterial()
    local root = self.toolkit:getPrimarySelection()
    if root == nil or not entityExists(root) then
        self.toolkit:logWarning("Select a source shape or group before capturing a material.")
        return
    end

    local slot = self:getSlot()
    local shape = self.toolkit:findFirstShapeWithMaterialSlot(root, slot)
    if shape == nil then
        self.toolkit:logError(string.format("No shape under %s has material slot %d.", getName(root), slot), root)
        return
    end

    self.capturedMaterial = getMaterial(shape, slot)
    self.capturedSlot = slot
    self.capturedSource = shape
    self.captureLabel:setText(string.format("Captured: %s\nSource: %s  |  slot %d",
        self.toolkit:getMaterialDisplayName(self.capturedMaterial), getName(shape), slot))
    self.toolkit:logInfo(string.format("Captured material slot %d from %s.", slot, getName(shape)), shape)
    self:previewActiveTarget()
end

function ADTMaterials:clearCapturedMaterial()
    self.capturedMaterial = nil
    self.capturedSlot = 0
    self.capturedSource = nil
    self.captureLabel:setText("Captured material: none")
    self.previewLabel:setText("Preview: capture a material and active target first.")
    self.toolkit:setStatus("Captured material cleared.")
end

function ADTMaterials:countApplicableShapes(root, slot)
    local applicable = 0
    local skipped = 0
    local shapes = self.toolkit:collectShapes(root)
    for _, shape in ipairs(shapes) do
        if getNumOfMaterials(shape) > slot then
            applicable = applicable + 1
        else
            skipped = skipped + 1
        end
    end
    return applicable, skipped, #shapes
end

function ADTMaterials:previewActiveTarget()
    if self.previewLabel == nil then
        return
    end
    if self.capturedMaterial == nil then
        self.previewLabel:setText("Preview: capture a source material first.")
        return
    end

    local target = self:getActiveTarget()
    if target == nil then
        self.previewLabel:setText("Preview: capture an active target on the Place tab first.")
        return
    end

    local slot = self:getSlot()
    local applicable, skipped, total = self:countApplicableShapes(target, slot)
    self.previewLabel:setText(string.format(
        "Target: %s\nSlot %d will change on %d of %d shape(s); %d shape(s) will be skipped.",
        getName(target), slot, applicable, total, skipped))
end

function ADTMaterials:applyToRoot(root, contextLabel)
    if self.capturedMaterial == nil then
        self.toolkit:logWarning("Capture a source material first.")
        return
    end
    if root == nil or not entityExists(root) then
        self.toolkit:logWarning("No valid " .. contextLabel .. " is available for material application.")
        return
    end

    local slot = self:getSlot()
    local shapes = self.toolkit:collectShapes(root)
    if #shapes == 0 then
        self.toolkit:logWarning("No shape nodes were found under " .. getName(root), root)
        return
    end

    local changed = 0
    local skipped = 0
    for _, shape in ipairs(shapes) do
        if getNumOfMaterials(shape) > slot then
            setMaterial(shape, self.capturedMaterial, slot)
            changed = changed + 1
        else
            skipped = skipped + 1
            print(string.format("ADT Materials: skipped %s; no slot %d", getName(shape), slot))
        end
    end

    refreshViewport(true)
    self.toolkit:logInfo(string.format(
        "Applied %s to %s %s: changed %d shape(s), skipped %d without slot %d.",
        self.toolkit:getMaterialDisplayName(self.capturedMaterial), contextLabel, getName(root), changed, skipped, slot), root)
    self:updateContextLabels()
    self:previewActiveTarget()
end

function ADTMaterials:applyToActiveTarget()
    self:applyToRoot(self:getActiveTarget(), "active target")
end

function ADTMaterials:applyToCurrentSelection()
    self:applyToRoot(self.toolkit:getPrimarySelection(), "current selection")
end

function ADTMaterials:onSelectionChanged(nodeId, isSelected)
    self:updateContextLabels()
end

function ADTMaterials:onTabOpen(previous)
    self:updateContextLabels()
    self:previewActiveTarget()
end
