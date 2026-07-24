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
    self.parentNode = nil
    self.lastImportPath = ""
    return self
end

function ADTParticles:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local importSizer = UIRowLayoutSizer.new()
    fold:addPanel("Native particle import assistant", importSizer)
    UILabel.new(importSizer,
        "1. Select the destination parent. 2. Arm the watcher. 3. Use File > Import in GIANTS Editor to import amberHollowBees.i3d or another particle I3D.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 65, BorderDirection.BOTTOM, 5)

    UIButton.new(importSizer, "Use current selection as parent", function() self:setParentFromSelection() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    self.parentLabel = UILabel.new(importSizer, "Parent: scene root", false,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 25, BorderDirection.BOTTOM, 5)

    UIButton.new(importSizer, "Arm next particle import", function() self:setArmed(true) end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(importSizer, "Disarm", function() self:setArmed(false) end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    self.armLabel = UILabel.new(importSizer, "Watcher: disarmed", false,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 25)

    local presetsSizer = UIRowLayoutSizer.new()
    fold:addPanel("Amber Hollow presets", presetsSizer)
    UIButton.new(presetsSizer, "Choose amberHollowBees.i3d", function() self:chooseImportFile("amberHollowBees.i3d") end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(presetsSizer, "Choose smoker particle I3D", function() self:chooseImportFile("amberHollowBeeSmoker.i3d") end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    self.fileLabel = UILabel.new(presetsSizer, "Selected source: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 42)

    local postSizer = UIRowLayoutSizer.new()
    fold:addPanel("Post-import processing", postSizer)
    UILabel.new(postSizer,
        "The import hook receives the top-level nodes created by GE. The toolkit reparents them, prefixes their names, and keeps GE responsible for all node/material/file ID remapping.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 60)
end

function ADTParticles:setParentFromSelection()
    self.parentNode = self.toolkit:getPrimarySelection()
    if self.parentNode == nil then
        self.parentLabel:setText("Parent: scene root")
        self.toolkit:logInfo("Particle import parent reset to scene root.")
    else
        self.parentLabel:setText("Parent: " .. getName(self.parentNode))
        self.toolkit:logInfo("Particle import parent set to " .. getName(self.parentNode), self.parentNode)
    end
end

function ADTParticles:setArmed(value)
    self.armed = value
    self.armLabel:setText(value and "Watcher: ARMED - import an I3D now" or "Watcher: disarmed")
    self.toolkit:setStatus(value and "Particle import watcher armed." or "Particle import watcher disarmed.")
end

function ADTParticles:chooseImportFile(defaultName)
    local startPath = self.lastImportPath
    if string.isNilOrWhitespace(startPath) then
        startPath = getSceneFilename()
    end
    local filename = openFileDialog(startPath, "GIANTS I3D|*.i3d")
    if string.isNilOrWhitespace(filename) then
        return
    end
    self.lastImportPath = filename
    self.fileLabel:setText("Selected source: " .. filename .. "\nNow arm the watcher and import this file through GE File > Import.")
    self.toolkit:logInfo("Particle source selected: " .. filename)
end

function ADTParticles:onFileImported(filepath, nodes)
    if not self.armed then
        return
    end

    self.armed = false
    self.armLabel:setText("Watcher: disarmed")

    local parent = self.parentNode
    if parent == nil or not entityExists(parent) then
        parent = getRootNode()
    end

    local count = 0
    if nodes ~= nil then
        for _, node in pairs(nodes) do
            if entityExists(node) then
                link(parent, node)
                local currentName = getName(node)
                if not string.startsWith(currentName, "adtParticle_") then
                    setName(node, "adtParticle_" .. currentName)
                end
                count = count + 1
            end
        end
    end

    refreshViewport(true)
    self.toolkit:logInfo(string.format("Processed %d imported particle root node(s) from %s", count, filepath), parent)
end
