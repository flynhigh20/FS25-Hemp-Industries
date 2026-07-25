-- Author:OpenAI + flynhigh20
-- Name:ADT Particles Plugin
-- Namespace: global
-- Description:Hidden plugin module for Apiary Development Toolkit.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTParticles = {}
local ADTParticles_mt = Class(ADTParticles)

function ADTParticles.new(toolkit)
    local self = setmetatable({}, ADTParticles_mt)
    self.toolkit = toolkit
    self.tabName = "Particles"
    self.armed = false
    self.mode = "import"
    self.parentNode = nil
    self.placeholderNode = nil
    self.placeholderSnapshot = nil
    self.lastImportPath = ""
    self.lastImportedNode = nil
    return self
end

function ADTParticles:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local destinationSizer = UIRowLayoutSizer.new()
    fold:addPanel("Import destination", destinationSizer)
    self.destinationLabel = UILabel.new(destinationSizer, "Destination: scene root", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 42, BorderDirection.BOTTOM, 5)
    UIButton.new(destinationSizer, "Use shared active target as destination",
        function() self:setParentFromActiveTarget() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(destinationSizer, "Use current selection as destination",
        function() self:setParentFromSelection() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(destinationSizer, "Reset destination to scene root",
        function() self:resetParent() end,
        nil, -1, -1, -1, 28)

    local importSizer = UIRowLayoutSizer.new()
    fold:addPanel("Normal particle import", importSizer)
    UILabel.new(importSizer,
        "Arm this mode, then use File > Import in GIANTS Editor. Imported root nodes are moved under the chosen destination and prefixed with adtParticle_.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 58, BorderDirection.BOTTOM, 5)
    UIButton.new(importSizer, "ARM NEXT PARTICLE IMPORT",
        function() self:armNormalImport() end,
        nil, -1, -1, -1, 32, BorderDirection.BOTTOM, 5)

    local replaceSizer = UIRowLayoutSizer.new()
    fold:addPanel("Replace placeholder with imported particle", replaceSizer)
    self.placeholderLabel = UILabel.new(replaceSizer, "Placeholder: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 42, BorderDirection.BOTTOM, 5)
    UIButton.new(replaceSizer, "Use shared active target as placeholder",
        function() self:setPlaceholderFromActiveTarget() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(replaceSizer, "Use current selection as placeholder",
        function() self:setPlaceholderFromSelection() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(replaceSizer, "ARM IMPORT AND REPLACE PLACEHOLDER",
        function() self:armReplacement() end,
        nil, -1, -1, -1, 32, BorderDirection.BOTTOM, 5)
    UILabel.new(replaceSizer,
        "Replacement preserves the placeholder parent, local translation, rotation, scale and name. The placeholder is deleted only after exactly one valid imported root is captured.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 65)

    local watcherSizer = UIRowLayoutSizer.new()
    fold:addPanel("Watcher status", watcherSizer)
    UIButton.new(watcherSizer, "Disarm watcher",
        function() self:setArmed(false, "import") end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    self.armLabel = UILabel.new(watcherSizer, "Watcher: disarmed", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 30, BorderDirection.BOTTOM, 5)
    self.resultLabel = UILabel.new(watcherSizer, "Last result: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 45)

    local sourceSizer = UIRowLayoutSizer.new()
    fold:addPanel("Source-file helper", sourceSizer)
    UIButton.new(sourceSizer, "Choose an I3D source file",
        function() self:chooseImportFile() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    self.fileLabel = UILabel.new(sourceSizer, "Selected source: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 55)

    self:updateLabels()
end

function ADTParticles:getValidNode(node)
    if node ~= nil and entityExists(node) then
        return node
    end
    return nil
end

function ADTParticles:getActiveTarget()
    local target = self:getValidNode(self.toolkit.activeTarget)
    if target == nil then
        self.toolkit.activeTarget = nil
    end
    return target
end

function ADTParticles:setParent(node, sourceLabel)
    self.parentNode = self:getValidNode(node)
    self:updateLabels()
    if self.parentNode == nil then
        self.toolkit:logInfo("Particle import destination reset to scene root.")
    else
        self.toolkit:logInfo("Particle import destination set from " .. sourceLabel .. ": " .. getName(self.parentNode), self.parentNode)
    end
end

function ADTParticles:setParentFromActiveTarget()
    local target = self:getActiveTarget()
    if target == nil then
        self.toolkit:logWarning("Capture an active target on the Place tab first.")
        return
    end
    self:setParent(target, "active target")
end

function ADTParticles:setParentFromSelection()
    local selected = self.toolkit:getPrimarySelection()
    if selected == nil then
        self.toolkit:logWarning("Select a destination node first.")
        return
    end
    self:setParent(selected, "current selection")
end

function ADTParticles:resetParent()
    self:setParent(nil, "reset")
end

function ADTParticles:setPlaceholder(node, sourceLabel)
    node = self:getValidNode(node)
    if node == nil then
        self.toolkit:logWarning("Select or capture a valid placeholder node first.")
        return
    end
    if node == getRootNode() then
        self.toolkit:logError("The scene root cannot be used as a replacement placeholder.")
        return
    end
    self.placeholderNode = node
    self.placeholderSnapshot = nil
    self:updateLabels()
    self.toolkit:logInfo("Particle replacement placeholder set from " .. sourceLabel .. ": " .. getName(node), node)
end

function ADTParticles:setPlaceholderFromActiveTarget()
    self:setPlaceholder(self:getActiveTarget(), "active target")
end

function ADTParticles:setPlaceholderFromSelection()
    self:setPlaceholder(self.toolkit:getPrimarySelection(), "current selection")
end

function ADTParticles:capturePlaceholderSnapshot()
    local node = self:getValidNode(self.placeholderNode)
    if node == nil then
        return nil
    end

    local tx, ty, tz = getTranslation(node)
    local rx, ry, rz = getRotation(node)
    local sx, sy, sz = getScale(node)
    local parent = getParent(node)
    if parent == nil or parent == 0 or not entityExists(parent) then
        parent = getRootNode()
    end

    return {
        node = node,
        name = getName(node),
        parent = parent,
        tx = tx, ty = ty, tz = tz,
        rx = rx, ry = ry, rz = rz,
        sx = sx, sy = sy, sz = sz
    }
end

function ADTParticles:setArmed(value, mode)
    self.armed = value
    self.mode = mode or "import"
    if not value then
        self.placeholderSnapshot = nil
        self.armLabel:setText("Watcher: disarmed")
        self.toolkit:setStatus("Particle import watcher disarmed.")
    elseif self.mode == "replace" then
        self.armLabel:setText("Watcher: ARMED FOR REPLACEMENT - import one I3D now")
        self.toolkit:setStatus("Particle replacement watcher armed.")
    else
        self.armLabel:setText("Watcher: ARMED FOR IMPORT - import an I3D now")
        self.toolkit:setStatus("Particle import watcher armed.")
    end
end

function ADTParticles:armNormalImport()
    self.placeholderSnapshot = nil
    self:setArmed(true, "import")
end

function ADTParticles:armReplacement()
    local snapshot = self:capturePlaceholderSnapshot()
    if snapshot == nil then
        self.toolkit:logWarning("Choose a valid placeholder before arming replacement.")
        return
    end
    self.placeholderSnapshot = snapshot
    self:setArmed(true, "replace")
end

function ADTParticles:chooseImportFile()
    local startPath = self.lastImportPath
    if string.isNilOrWhitespace(startPath) then
        startPath = getSceneFilename()
    end
    local filename = openFileDialog(startPath, "GIANTS I3D|*.i3d")
    if string.isNilOrWhitespace(filename) then
        return
    end
    self.lastImportPath = filename
    self.fileLabel:setText("Selected source: " .. filename .. "\nUse GE File > Import after arming the desired mode.")
    self.toolkit:logInfo("Particle source selected: " .. filename)
end

function ADTParticles:collectValidImportedNodes(nodes)
    local valid = {}
    if nodes ~= nil then
        for _, node in pairs(nodes) do
            if entityExists(node) then
                table.insert(valid, node)
            end
        end
    end
    return valid
end

function ADTParticles:processNormalImport(filepath, importedNodes)
    local parent = self:getValidNode(self.parentNode) or getRootNode()
    for _, node in ipairs(importedNodes) do
        link(parent, node)
        local currentName = getName(node)
        if not string.startsWith(currentName, "adtParticle_") then
            setName(node, "adtParticle_" .. currentName)
        end
    end

    self.lastImportedNode = importedNodes[1]
    self.resultLabel:setText(string.format("Last result: imported %d root node(s) under %s", #importedNodes, getName(parent)))
    self.toolkit:logInfo(string.format("Processed %d imported particle root node(s) from %s", #importedNodes, filepath), parent)
end

function ADTParticles:processReplacement(filepath, importedNodes)
    local snapshot = self.placeholderSnapshot
    if snapshot == nil or not entityExists(snapshot.node) then
        self.resultLabel:setText("Last result: replacement cancelled; placeholder no longer exists")
        self.toolkit:logError("Particle replacement cancelled because the placeholder no longer exists.")
        return
    end

    if #importedNodes ~= 1 then
        local fallbackParent = self:getValidNode(self.parentNode) or getRootNode()
        for _, node in ipairs(importedNodes) do
            link(fallbackParent, node)
        end
        self.resultLabel:setText(string.format("Last result: replacement cancelled; import produced %d root nodes", #importedNodes))
        self.toolkit:logError(string.format(
            "Replacement requires exactly one imported root node; received %d. Placeholder preserved and imported nodes kept under %s.",
            #importedNodes, getName(fallbackParent)), snapshot.node)
        return
    end

    local replacement = importedNodes[1]
    link(snapshot.parent, replacement)
    setTranslation(replacement, snapshot.tx, snapshot.ty, snapshot.tz)
    setRotation(replacement, snapshot.rx, snapshot.ry, snapshot.rz)
    setScale(replacement, snapshot.sx, snapshot.sy, snapshot.sz)
    setName(replacement, snapshot.name)

    delete(snapshot.node)
    self.placeholderNode = replacement
    self.lastImportedNode = replacement
    self.toolkit.activeTarget = replacement

    self.resultLabel:setText("Last result: replaced placeholder with " .. snapshot.name)
    self.toolkit:logInfo("Replaced particle placeholder with imported root from " .. filepath, replacement)
end

function ADTParticles:onFileImported(filepath, nodes)
    if not self.armed then
        return
    end

    local mode = self.mode
    self.armed = false
    self.armLabel:setText("Watcher: disarmed")

    local importedNodes = self:collectValidImportedNodes(nodes)
    if #importedNodes == 0 then
        self.placeholderSnapshot = nil
        self.resultLabel:setText("Last result: no valid imported root nodes received")
        self.toolkit:logError("The import hook did not receive any valid root nodes from " .. tostring(filepath))
        return
    end

    if mode == "replace" then
        self:processReplacement(filepath, importedNodes)
    else
        self:processNormalImport(filepath, importedNodes)
    end

    self.placeholderSnapshot = nil
    refreshViewport(true)
    self:updateLabels()
end

function ADTParticles:updateLabels()
    if self.destinationLabel == nil or self.placeholderLabel == nil then
        return
    end

    local parent = self:getValidNode(self.parentNode)
    if parent == nil then
        self.parentNode = nil
        self.destinationLabel:setText("Destination: scene root")
    else
        self.destinationLabel:setText(string.format("Destination: %s  |  node %s", getName(parent), tostring(parent)))
    end

    local placeholder = self:getValidNode(self.placeholderNode)
    if placeholder == nil then
        self.placeholderNode = nil
        self.placeholderLabel:setText("Placeholder: none")
    else
        local parentNode = getParent(placeholder)
        local parentName = "scene root"
        if parentNode ~= nil and parentNode ~= 0 and entityExists(parentNode) then
            parentName = getName(parentNode)
        end
        self.placeholderLabel:setText(string.format("Placeholder: %s  |  node %s  |  parent %s",
            getName(placeholder), tostring(placeholder), parentName))
    end
end

function ADTParticles:onSelectionChanged(nodeId, isSelected)
    self:updateLabels()
end

function ADTParticles:onTabOpen(previous)
    self:updateLabels()
end
