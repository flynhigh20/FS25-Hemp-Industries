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

    local inspectSizer = UIRowLayoutSizer.new()
    fold:addPanel("Selected shape or group", inspectSizer)
    self.selectionLabel = UILabel.new(inspectSizer,
        "No selection. Shape children are searched recursively.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 42, BorderDirection.BOTTOM, 5)
    UIButton.new(inspectSizer, "Inspect selected material slots recursively",
        function() self:inspectSelected() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)

    local captureSizer = UIRowLayoutSizer.new()
    fold:addPanel("Capture / apply", captureSizer)
    local slotSizer = UIColumnLayoutSizer.new()
    UIPanel.new(captureSizer, slotSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    UILabel.new(slotSizer, "Material slot", false, TextAlignment.LEFT, VerticalAlignment.CENTER,
        -1, -1, 140, 25, BorderDirection.RIGHT, 5)
    self.slotInput = UITextArea.new(slotSizer, "0", TextAlignment.LEFT, false, false,
        -1, -1, 100, 25)

    UIButton.new(captureSizer, "Capture from first valid shape in primary selection",
        function() self:captureMaterial() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(captureSizer, "Apply to selected shapes and child shapes",
        function() self:applyMaterial() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)

    self.captureLabel = UILabel.new(captureSizer, "Captured material: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 42)

    local noteSizer = UIRowLayoutSizer.new()
    fold:addPanel("Safety", noteSizer)
    UILabel.new(noteSizer,
        "Groups are now expanded recursively. The chosen slot is changed only on shapes that contain that slot. Save a backup before bulk changes.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 60)

    self:updateSelectionLabel()
end

function ADTMaterials:getSlot()
    local slot = tonumber(self.slotInput:getValue()) or 0
    return math.max(0, math.floor(slot))
end

function ADTMaterials:updateSelectionLabel()
    if self.selectionLabel == nil then
        return
    end

    local primary = self.toolkit:getPrimarySelection()
    if primary == nil then
        self.selectionLabel:setText("No selection. Shape children are searched recursively.")
        return
    end

    local shapes = self.toolkit:collectShapes(primary)
    local nodeType = self.toolkit:getNodeTypeLabel(primary)
    self.selectionLabel:setText(string.format("Primary: %s  |  %s  |  %d shape(s) found recursively",
        getName(primary), nodeType, #shapes))
end

function ADTMaterials:inspectSelected()
    local shapes, root = self.toolkit:getShapesFromPrimarySelection()
    if root == nil then
        self.toolkit:logWarning("Select a shape or group first.")
        return
    end
    if #shapes == 0 then
        self.toolkit:logWarning("No material-bearing shape nodes were found under " .. getName(root), root)
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

function ADTMaterials:captureMaterial()
    local root = self.toolkit:getPrimarySelection()
    if root == nil then
        self.toolkit:logWarning("Select a source shape or group first.")
        return
    end

    local slot = self:getSlot()
    local shape = self.toolkit:findFirstShapeWithMaterialSlot(root, slot)
    if shape == nil then
        self.toolkit:logError(string.format("No child shape under %s has material slot %d.", getName(root), slot), root)
        return
    end

    self.capturedMaterial = getMaterial(shape, slot)
    self.capturedSlot = slot
    self.capturedSource = shape
    self.captureLabel:setText(string.format("Captured %s from %s slot %d",
        self.toolkit:getMaterialDisplayName(self.capturedMaterial), getName(shape), slot))
    self.toolkit:logInfo("Captured material from " .. getName(shape), shape)
end

function ADTMaterials:applyMaterial()
    if self.capturedMaterial == nil then
        self.toolkit:logWarning("Capture a source material first.")
        return
    end

    local shapes = self.toolkit:getSelectedShapes()
    if #shapes == 0 then
        self.toolkit:logWarning("The current selection contains no shape nodes.")
        return
    end

    local slot = self:getSlot()
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
    self.toolkit:logInfo(string.format("Applied %s to %d shape(s); skipped %d without slot %d.",
        self.toolkit:getMaterialDisplayName(self.capturedMaterial), changed, skipped, slot), self.capturedSource)
end

function ADTMaterials:onSelectionChanged(nodeId, isSelected)
    self:updateSelectionLabel()
end
