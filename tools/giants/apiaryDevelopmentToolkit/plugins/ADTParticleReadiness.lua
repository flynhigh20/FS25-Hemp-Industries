-- Author:OpenAI + flynhigh20
-- Name:ADT Particle Readiness Plugin
-- Namespace: global
-- Description:ParticleEffect emitter readiness checks and conservative smoke XML output.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTParticleReadiness = {}
local ADTParticleReadiness_mt = Class(ADTParticleReadiness)

function ADTParticleReadiness.new(toolkit)
    local self = setmetatable({}, ADTParticleReadiness_mt)
    self.toolkit = toolkit
    self.tabName = "Particle Check"
    return self
end

function ADTParticleReadiness:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local contextSizer = UIRowLayoutSizer.new()
    fold:addPanel("Emitter context", contextSizer)
    self.contextLabel = UILabel.new(contextSizer, "Select the intended ParticleEffect emitter node.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 55, BorderDirection.BOTTOM, 5)
    UIButton.new(contextSizer, "Refresh emitter check", function() self:updateCheck() end,
        nil, -1, -1, -1, 28)

    local checkSizer = UIRowLayoutSizer.new()
    fold:addPanel("ParticleEffect readiness", checkSizer)
    self.checkLabel = UILabel.new(checkSizer, "No emitter selected.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 210, BorderDirection.BOTTOM, 5)
    UIButton.new(checkSizer, "Print readiness report", function() self:printReport() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(checkSizer, "Print conservative smoke preset", function() self:printConservativePreset() end,
        nil, -1, -1, -1, 28)

    local noteSizer = UIRowLayoutSizer.new()
    fold:addPanel("What this catches", noteSizer)
    UILabel.new(noteSizer,
        "Checks whether the selected node is a Shape or transform-only placeholder, whether geometry and materials exist, whether the mapping is I3D-relative, and whether the node name looks like an emitter. The conservative preset omits materialType because names such as smokeParticle may depend on extra registrations.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 120)

    self:updateCheck()
end

function ADTParticleReadiness:getNode()
    local selected = self.toolkit:getPrimarySelection()
    if selected ~= nil and entityExists(selected) then return selected end
    local target = self.toolkit.activeTarget
    if target ~= nil and entityExists(target) then return target end
    return nil
end

function ADTParticleReadiness:getNodePath(node)
    if ADTEffectInspector ~= nil and ADTEffectInspector.getNodePath ~= nil then
        return ADTEffectInspector.getNodePath(self, node)
    end
    return nil
end

function ADTParticleReadiness:getStats(node)
    local shapes = self.toolkit:collectShapes(node)
    local slots = 0
    for _, shape in ipairs(shapes) do slots = slots + getNumOfMaterials(shape) end
    return #shapes, slots
end

function ADTParticleReadiness:getAssessment(node)
    local shapeCount, materialSlots = self:getStats(node)
    local nodeType = self.toolkit:getNodeTypeLabel(node)
    local name = string.lower(getName(node) or "")
    local path = self:getNodePath(node) or "unknown"
    local issues = {}
    local notes = {}

    if path == "unknown" then table.insert(issues, "mapping path could not be calculated") end
    if path ~= "unknown" and string.sub(path, 1, 2) ~= "0>" then table.insert(issues, "mapping is not I3D-relative") end
    if shapeCount == 0 then
        table.insert(issues, "no Shape geometry found; this is probably a transform-only link or placeholder")
    else
        table.insert(notes, string.format("%d recursive Shape node(s) found", shapeCount))
    end
    if materialSlots == 0 then
        table.insert(notes, "no material slots found; acceptable for some hidden emitter shapes but verify against a working stock emitter")
    else
        table.insert(notes, string.format("%d material slot(s) found", materialSlots))
    end
    if string.find(name, "emit") == nil and string.find(name, "particle") == nil and string.find(name, "smoke") == nil then
        table.insert(notes, "node name does not clearly identify an emitter")
    end
    if string.find(string.lower(nodeType or ""), "transform") ~= nil and shapeCount == 0 then
        table.insert(notes, "transform-only nodes are better suited to dynamic smoke linking than ParticleEffect emission")
    end

    local verdict = #issues == 0 and "READY FOR CONTROLLED TEST" or "NOT READY"
    return verdict, issues, notes, shapeCount, materialSlots, path, nodeType
end

function ADTParticleReadiness:updateCheck()
    if self.contextLabel == nil or self.checkLabel == nil then return end
    local node = self:getNode()
    if node == nil then
        self.contextLabel:setText("Current emitter context: none")
        self.checkLabel:setText("Select the intended ParticleEffect emitter node.")
        return
    end

    local verdict, issues, notes, shapeCount, materialSlots, path, nodeType = self:getAssessment(node)
    self.contextLabel:setText(string.format("Current emitter: %s  |  id %s  |  %s", getName(node), tostring(node), nodeType))
    self.checkLabel:setText(string.format(
        "Verdict: %s\nMapping: %s\nRecursive shapes: %d  |  material slots: %d\nBlocking issues: %s\nNotes: %s",
        verdict, path, shapeCount, materialSlots,
        #issues > 0 and table.concat(issues, "; ") or "none",
        #notes > 0 and table.concat(notes, "; ") or "none"))
end

function ADTParticleReadiness:printReport()
    local node = self:getNode()
    if node == nil then self.toolkit:logWarning("Select the intended ParticleEffect emitter first."); return end
    local verdict, issues, notes, shapeCount, materialSlots, path, nodeType = self:getAssessment(node)
    print("ADT PARTICLE READINESS BEGIN")
    print(string.format("Node: %s [%s] type=%s", getName(node), tostring(node), nodeType))
    print("Mapping: " .. path)
    print(string.format("Shapes=%d materialSlots=%d verdict=%s", shapeCount, materialSlots, verdict))
    for _, issue in ipairs(issues) do print("BLOCKING: " .. issue) end
    for _, note in ipairs(notes) do print("NOTE: " .. note) end
    print("ADT PARTICLE READINESS END")
    self.toolkit:setStatus("ParticleEffect readiness report printed for " .. getName(node) .. ".")
end

function ADTParticleReadiness:printConservativePreset()
    local node = self:getNode()
    if node == nil then self.toolkit:logWarning("Select the intended ParticleEffect emitter first."); return end
    local id = getName(node)
    local path = self:getNodePath(node) or "unknown"
    print("ADT CONSERVATIVE PARTICLE SMOKE PRESET BEGIN")
    print("        <effects>")
    print(string.format('            <effectNode effectNode="%s" effectClass="ParticleEffect" particleType="smoke" emitCountScale="1" alphaScale="1" delay="0" worldSpace="true"/>', id))
    print("        </effects>")
    print("    <i3dMappings>")
    print(string.format('        <i3dMapping id="%s" node="%s" />', id, path))
    print("    </i3dMappings>")
    print("NOTE: materialType intentionally omitted for the first controlled test.")
    print("NOTE: Start with emitCountScale=1, then tune upward only after visible smoke is confirmed.")
    print("ADT CONSERVATIVE PARTICLE SMOKE PRESET END")
    self.toolkit:setStatus("Conservative ParticleEffect smoke preset printed for " .. id .. ".")
end

function ADTParticleReadiness:onSelectionChanged(nodeId, isSelected) self:updateCheck() end
function ADTParticleReadiness:onTabOpen(previous) self:updateCheck() end
