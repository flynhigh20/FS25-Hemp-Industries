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
    self.selectionLabel = UILabel.new(contextSizer, "Current selection: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 42, BorderDirection.BOTTOM, 5)
    self.targetLabel = UILabel.new(contextSizer, "Active target: none", true,
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

    local emissiveSizer = UIRowLayoutSizer.new()
    fold:addPanel("Emissive repair", emissiveSizer)
    UILabel.new(emissiveSizer,
        "Finds unique materials whose emissive color is white (approximately 1,1,1,1) and resets only those emissive values to 0,0,0,0. Textures and material assignments are preserved.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 68, BorderDirection.BOTTOM, 5)
    UIButton.new(emissiveSizer, "Preview white emissives on active target",
        function() self:previewWhiteEmissives(self:getActiveTarget(), "active target") end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(emissiveSizer, "RESET WHITE EMISSIVES ON ACTIVE TARGET",
        function() self:resetWhiteEmissives(self:getActiveTarget(), "active target") end,
        nil, -1, -1, -1, 32, BorderDirection.BOTTOM, 5)
    UIButton.new(emissiveSizer, "Preview white emissives on current selection",
        function() self:previewWhiteEmissives(self.toolkit:getPrimarySelection(), "current selection") end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(emissiveSizer, "Reset white emissives on current selection",
        function() self:resetWhiteEmissives(self.toolkit:getPrimarySelection(), "current selection") end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    self.emissiveLabel = UILabel.new(emissiveSizer, "Emissive repair: not scanned", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 55)

    local noteSizer = UIRowLayoutSizer.new()
    fold:addPanel("Safety", noteSizer)
    UILabel.new(noteSizer,
        "Material replacement changes only the chosen slot. Emissive repair changes only exact or near-white emissive colors. Save the I3D before applying bulk changes.",
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
    if self.selectionLabel == nil or self.targetLabel == nil then return end
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
    local applicable, skipped = 0, 0
    local shapes = self.toolkit:collectShapes(root)
    for _, shape in ipairs(shapes) do
        if getNumOfMaterials(shape) > slot then applicable = applicable + 1 else skipped = skipped + 1 end
    end
    return applicable, skipped, #shapes
end

function ADTMaterials:previewActiveTarget()
    if self.previewLabel == nil then return end
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
    local changed, skipped = 0, 0
    for _, shape in ipairs(shapes) do
        if getNumOfMaterials(shape) > slot then
            setMaterial(shape, self.capturedMaterial, slot)
            changed = changed + 1
        else
            skipped = skipped + 1
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

function ADTMaterials:getUniqueMaterials(root)
    local materials = {}
    if root == nil or not entityExists(root) then return materials end
    for _, shape in ipairs(self.toolkit:collectShapes(root)) do
        for slot=0, getNumOfMaterials(shape)-1 do
            local materialId = getMaterial(shape, slot)
            if materialId ~= nil and materialId ~= 0 then materials[materialId] = true end
        end
    end
    return materials
end

function ADTMaterials:getEmissive(materialId)
    if getMaterialEmissiveColor == nil then return nil end
    local ok, r, g, b, a = pcall(getMaterialEmissiveColor, materialId)
    if not ok then return nil end
    return r or 0, g or 0, b or 0, a or 0
end

function ADTMaterials:isWhiteEmissive(r, g, b, a)
    return r ~= nil and r >= 0.99 and g >= 0.99 and b >= 0.99 and (a == nil or a >= 0.99)
end

function ADTMaterials:scanWhiteEmissives(root)
    local matches = {}
    local total = 0
    for materialId in pairs(self:getUniqueMaterials(root)) do
        total = total + 1
        local r, g, b, a = self:getEmissive(materialId)
        if self:isWhiteEmissive(r, g, b, a) then
            table.insert(matches, {id=materialId, r=r, g=g, b=b, a=a})
        end
    end
    return matches, total
end

function ADTMaterials:previewWhiteEmissives(root, contextLabel)
    if root == nil or not entityExists(root) then
        self.toolkit:logWarning("No valid " .. contextLabel .. " is available for emissive inspection.")
        return
    end
    if getMaterialEmissiveColor == nil or setMaterialEmissiveColor == nil then
        self.emissiveLabel:setText("Emissive repair: this GIANTS Editor build does not expose the required material API.")
        self.toolkit:logWarning("Material emissive getter/setter API is unavailable in this GIANTS Editor build.")
        return
    end
    local matches, total = self:scanWhiteEmissives(root)
    self.emissiveLabel:setText(string.format("%s: %d white-emissive material(s) found among %d unique material(s).",
        contextLabel, #matches, total))
    for _, match in ipairs(matches) do
        print(string.format("ADT WHITE EMISSIVE material=%s rgba=%.4f %.4f %.4f %.4f",
            self.toolkit:getMaterialDisplayName(match.id), match.r, match.g, match.b, match.a or 0))
    end
    self.toolkit:setStatus(string.format("Found %d white-emissive material(s) under %s.", #matches, getName(root)))
end

function ADTMaterials:resetWhiteEmissives(root, contextLabel)
    if root == nil or not entityExists(root) then
        self.toolkit:logWarning("No valid " .. contextLabel .. " is available for emissive repair.")
        return
    end
    if getMaterialEmissiveColor == nil or setMaterialEmissiveColor == nil then
        self.emissiveLabel:setText("Emissive repair: unsupported by this GIANTS Editor build.")
        self.toolkit:logWarning("Material emissive getter/setter API is unavailable; no materials were changed.")
        return
    end
    local matches, total = self:scanWhiteEmissives(root)
    local changed, failed = 0, 0
    for _, match in ipairs(matches) do
        local ok = pcall(setMaterialEmissiveColor, match.id, 0, 0, 0, 0)
        if ok then changed = changed + 1 else failed = failed + 1 end
    end
    refreshViewport(true)
    self.emissiveLabel:setText(string.format("%s: reset %d white emissive(s); %d failed; %d unique material(s) scanned.",
        contextLabel, changed, failed, total))
    self.toolkit:logInfo(string.format("Reset white emissive colors under %s: changed %d, failed %d.",
        getName(root), changed, failed), root)
end

function ADTMaterials:onSelectionChanged(nodeId, isSelected)
    self:updateContextLabels()
end

function ADTMaterials:onTabOpen(previous)
    self:updateContextLabels()
    self:previewActiveTarget()
end
