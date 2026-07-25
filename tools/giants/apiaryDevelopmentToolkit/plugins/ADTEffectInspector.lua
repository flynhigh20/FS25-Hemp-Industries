-- Author:OpenAI + flynhigh20
-- Name:ADT Effect Inspector Plugin
-- Namespace: global
-- Description:Schema-aware GIANTS effect inspector and XML preset generator.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTEffectInspector = {}
local ADTEffectInspector_mt = Class(ADTEffectInspector)

function ADTEffectInspector.new(toolkit)
    local self = setmetatable({}, ADTEffectInspector_mt)
    self.toolkit = toolkit
    self.tabName = "Effects"
    return self
end

function ADTEffectInspector:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local contextSizer = UIRowLayoutSizer.new()
    fold:addPanel("Effect context", contextSizer)
    self.contextLabel = UILabel.new(contextSizer,
        "Select an effect node or capture it as the active target.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 52, BorderDirection.BOTTOM, 5)
    UIButton.new(contextSizer, "Refresh effect inspection", function() self:updateInspection() end,
        nil, -1, -1, -1, 28)

    local inspectSizer = UIRowLayoutSizer.new()
    fold:addPanel("Schema-aware inspection", inspectSizer)
    self.inspectionLabel = UILabel.new(inspectSizer,
        "No effect node available.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 185)
    UIButton.new(inspectSizer, "Print detailed effect report",
        function() self:printEffectReport() end,
        nil, -1, -1, -1, 28)

    local presetSizer = UIRowLayoutSizer.new()
    fold:addPanel("XML effect presets", presetSizer)
    UILabel.new(presetSizer,
        "Prints ready-to-paste XML based on FS25 handTool schema attributes. Mapping paths use the current scene hierarchy.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 58, BorderDirection.BOTTOM, 5)
    UIButton.new(presetSizer, "Print ParticleEffect smoke preset",
        function() self:printParticlePreset() end,
        nil, -1, -1, -1, 30, BorderDirection.BOTTOM, 5)
    UIButton.new(presetSizer, "Print PipeEffect pair preset",
        function() self:printPipePreset() end,
        nil, -1, -1, -1, 30, BorderDirection.BOTTOM, 5)
    UIButton.new(presetSizer, "Print dynamic chimney smoke preset",
        function() self:printDynamicSmokePreset() end,
        nil, -1, -1, -1, 30)

    local warningSizer = UIRowLayoutSizer.new()
    fold:addPanel("Effect behavior warnings", warningSizer)
    UILabel.new(warningSizer,
        "PipeEffect animates visible geometry toward controlPoint; a normal mesh can appear as a solid extending tube. ParticleEffect requires a compatible emitter shape and registered particle/material types. Dynamic chimney smoke loads a complete external smoke asset and may need custom visibility control.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 115)

    self:updateInspection()
end

function ADTEffectInspector:getContextNode()
    local selected = self.toolkit:getPrimarySelection()
    if selected ~= nil and entityExists(selected) then return selected end
    local target = self.toolkit.activeTarget
    if target ~= nil and entityExists(target) then return target end
    return nil
end

function ADTEffectInspector:getNodePath(node)
    if node == nil or not entityExists(node) then return nil end
    local indexes = {}
    local current = node
    while current ~= nil and entityExists(current) do
        local parent = getParent(current)
        if parent == nil or parent == 0 then break end
        local found = nil
        for i=0, getNumOfChildren(parent)-1 do
            if getChildAt(parent, i) == current then found = i break end
        end
        if found == nil then return nil end
        table.insert(indexes, 1, tostring(found))
        current = parent
    end
    if #indexes == 0 then return "0>" end
    return "0>" .. table.concat(indexes, "|")
end

function ADTEffectInspector:getShapeStats(node)
    local shapes = self.toolkit:collectShapes(node)
    local slots = 0
    for _, shape in ipairs(shapes) do slots = slots + getNumOfMaterials(shape) end
    return #shapes, slots
end

function ADTEffectInspector:getLikelyRole(node, shapeCount)
    local name = string.lower(getName(node) or "")
    if string.find(name, "pipe") ~= nil then
        return "Likely PipeEffect geometry. This mesh may visibly extend and retract toward controlPoint."
    elseif string.find(name, "emit") ~= nil or string.find(name, "particle") ~= nil then
        return "Likely ParticleEffect emitter shape. It should remain visually hidden or non-renderable in normal use."
    elseif string.find(name, "smoke") ~= nil and shapeCount == 0 then
        return "Likely smoke attachment/link transform. Suitable for dynamicallyLoadedPart linking."
    elseif shapeCount > 0 then
        return "Rendered geometry is present. Verify the original effect shader/material before assigning an effect class."
    end
    return "Transform-only node. It can be a parent, mapping target or dynamic-effect link, but is not visible effect geometry by itself."
end

function ADTEffectInspector:updateInspection()
    if self.contextLabel == nil or self.inspectionLabel == nil then return end
    local node = self:getContextNode()
    if node == nil then
        self.contextLabel:setText("Current effect context: none")
        self.inspectionLabel:setText("Select an effect node or capture one as the active target.")
        return
    end

    local shapeCount, materialSlots = self:getShapeStats(node)
    local path = self:getNodePath(node) or "unknown"
    local tx, ty, tz = getTranslation(node)
    local sx, sy, sz = getScale(node)
    local role = self:getLikelyRole(node, shapeCount)

    self.contextLabel:setText(string.format("Current effect context: %s  |  id %s  |  %s",
        getName(node), tostring(node), self.toolkit:getNodeTypeLabel(node)))
    self.inspectionLabel:setText(string.format(
        "Mapping path: %s\nDirect children: %d\nRecursive shapes: %d\nMaterial slots: %d\nLocal translation: %.3f %.3f %.3f\nLocal scale: %.3f %.3f %.3f\nAssessment: %s",
        path, getNumOfChildren(node), shapeCount, materialSlots,
        tx or 0, ty or 0, tz or 0, sx or 0, sy or 0, sz or 0, role))
end

function ADTEffectInspector:printEffectReport()
    local node = self:getContextNode()
    if node == nil then self.toolkit:logWarning("Select an effect node or capture one first."); return end
    local shapeCount, materialSlots = self:getShapeStats(node)
    print("ADT EFFECT INSPECTOR BEGIN")
    print(string.format("Node: %s [%s] type=%s", getName(node), tostring(node), self.toolkit:getNodeTypeLabel(node)))
    print("Mapping: " .. (self:getNodePath(node) or "unknown"))
    print(string.format("Direct children=%d recursiveShapes=%d materialSlots=%d", getNumOfChildren(node), shapeCount, materialSlots))
    print("Assessment: " .. self:getLikelyRole(node, shapeCount))
    if string.find(string.lower(getName(node) or ""), "pipe") ~= nil then
        print("WARNING: PipeEffect controls visible extending geometry; it is not a particle emitter.")
    end
    print("ADT EFFECT INSPECTOR END")
    self.toolkit:setStatus("Effect inspection printed for " .. getName(node) .. ".")
end

function ADTEffectInspector:printMapping(node)
    print(string.format('        <i3dMapping id="%s" node="%s" />', getName(node), self:getNodePath(node) or "unknown"))
end

function ADTEffectInspector:printParticlePreset()
    local node = self:getContextNode()
    if node == nil then self.toolkit:logWarning("Select the intended particle emitter shape first."); return end
    local id = getName(node)
    print("ADT PARTICLE EFFECT PRESET BEGIN")
    print("        <effects>")
    print(string.format('            <effectNode effectNode="%s" effectClass="ParticleEffect" particleType="smoke" materialType="smokeParticle" emitCountScale="0.5" alphaScale="1" delay="0" worldSpace="true"/>', id))
    print("        </effects>")
    print("    <i3dMappings>")
    self:printMapping(node)
    print("    </i3dMappings>")
    print("ADT PARTICLE EFFECT PRESET END")
    self.toolkit:setStatus("ParticleEffect smoke preset printed for " .. id .. ".")
end

function ADTEffectInspector:printPipePreset()
    local node = self:getContextNode()
    if node == nil then self.toolkit:logWarning("Select pipeEffect or its shared effects parent first."); return end

    local parent = node
    if string.lower(getName(node) or "") ~= "effects" then
        local p = getParent(node)
        if p ~= nil and p ~= 0 and entityExists(p) then parent = p end
    end

    local pipeNode, smokeNode = nil, nil
    for i=0, getNumOfChildren(parent)-1 do
        local child = getChildAt(parent, i)
        local name = string.lower(getName(child) or "")
        if name == "pipeeffect" then pipeNode = child end
        if name == "pipeeffectsmoke" then smokeNode = child end
    end
    if pipeNode == nil or smokeNode == nil then
        self.toolkit:logWarning("PipeEffect preset requires sibling nodes named pipeEffect and pipeEffectSmoke.")
        return
    end

    print("ADT PIPE EFFECT PRESET BEGIN")
    print("        <effects>")
    print('            <effectNode effectClass="PipeEffect" effectNode="pipeEffect" materialType="pipe" fadeTime="0.25" maxBending="0.15" shapeScaleSpread="0.15 0.15 0.15 0" controlPoint="1 0 0 0" positionUpdateNodes="pipeEffectSmoke"/>')
    print('            <effectNode effectNode="pipeEffectSmoke" materialType="unloadingSmoke" fadeTime="0.35" alignToWorldY="true"/>')
    print("        </effects>")
    print("    <i3dMappings>")
    self:printMapping(pipeNode)
    self:printMapping(smokeNode)
    print("    </i3dMappings>")
    print("WARNING: PipeEffect visibly extends/retracts pipeEffect geometry toward controlPoint.")
    print("ADT PIPE EFFECT PRESET END")
    self.toolkit:setStatus("PipeEffect pair preset printed.")
end

function ADTEffectInspector:printDynamicSmokePreset()
    local node = self:getContextNode()
    if node == nil then self.toolkit:logWarning("Select the smoke attachment/link node first."); return end
    local id = getName(node)
    print("ADT DYNAMIC SMOKE PRESET BEGIN")
    print("    <dynamicallyLoadedParts>")
    print(string.format('        <dynamicallyLoadedPart filename="$data/effects/chimneySmoke/smokeTrailSubUV.i3d" node="1" linkNode="%s" shaderParameterName="colorAlpha" shaderParameter="0.5 0.5 0.5 0.5"/>', id))
    print("    </dynamicallyLoadedParts>")
    print("    <i3dMappings>")
    self:printMapping(node)
    print("    </i3dMappings>")
    print("NOTE: This loads a complete external smoke asset and may run continuously unless controlled separately.")
    print("ADT DYNAMIC SMOKE PRESET END")
    self.toolkit:setStatus("Dynamic chimney smoke preset printed for " .. id .. ".")
end

function ADTEffectInspector:onSelectionChanged(nodeId, isSelected)
    self:updateInspection()
end

function ADTEffectInspector:onTabOpen(previous)
    self:updateInspection()
end
