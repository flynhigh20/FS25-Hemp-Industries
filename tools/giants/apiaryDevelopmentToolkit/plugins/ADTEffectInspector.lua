-- Author:OpenAI + flynhigh20
-- Name:ADT Effect Inspector Plugin
-- Namespace: global
-- Description:Schema-aware GIANTS effect inspector and safe XML/code guidance.
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
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 205)
    UIButton.new(inspectSizer, "Print detailed effect report",
        function() self:printEffectReport() end,
        nil, -1, -1, -1, 28)

    local presetSizer = UIRowLayoutSizer.new()
    fold:addPanel("Safe effect guidance", presetSizer)
    UILabel.new(presetSizer,
        "Only prints a preset when the selected node type is compatible. TransformGroups are valid attachment nodes, but they must never be passed to ShaderPlaneEffect or ParticleEffect as rendered effect geometry.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 82, BorderDirection.BOTTOM, 5)
    UIButton.new(presetSizer, "Print registered ParticleEffect preset",
        function() self:printParticlePreset() end,
        nil, -1, -1, -1, 30, BorderDirection.BOTTOM, 5)
    UIButton.new(presetSizer, "Print PipeEffect pair preset",
        function() self:printPipePreset() end,
        nil, -1, -1, -1, 30, BorderDirection.BOTTOM, 5)
    UIButton.new(presetSizer, "Print external smoke Lua guidance",
        function() self:printDynamicSmokePreset() end,
        nil, -1, -1, -1, 30)

    local warningSizer = UIRowLayoutSizer.new()
    fold:addPanel("Confirmed behavior warnings", warningSizer)
    UILabel.new(warningSizer,
        "Generic particleType=smoke is not verified in FS25. Use a registered particle type such as WASHER_WATER only with a compatible emitter shape. PipeEffect animates mesh geometry and is not smoke. dynamicallyLoadedParts is specialization-dependent and must not be assumed valid for hand tools. Hand-tool external smoke requires custom Lua loading and visibility control.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 145)

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

function ADTEffectInspector:isDirectShape(node)
    return node ~= nil and entityExists(node) and self.toolkit:isShape(node)
end

function ADTEffectInspector:getLikelyRole(node, shapeCount)
    local name = string.lower(getName(node) or "")
    local directShape = self:isDirectShape(node)
    if directShape and string.find(name, "pipe") ~= nil then
        return "Direct Shape likely intended as PipeEffect geometry. It may visibly extend and retract toward controlPoint."
    elseif directShape and (string.find(name, "emit") ~= nil or string.find(name, "particle") ~= nil) then
        return "Direct Shape may be a ParticleEffect emitter. Confirm the source asset and registered particle type before generating XML."
    elseif not directShape and shapeCount == 0 then
        return "Transform-only attachment node. Safe as a link parent, but unsafe as effect geometry for ShaderPlaneEffect or ParticleEffect."
    elseif not directShape and shapeCount > 0 then
        return "TransformGroup containing Shapes. Map the actual compatible child Shape for EffectManager effects, not this parent TransformGroup."
    elseif shapeCount > 0 then
        return "Rendered Shape present. Verify original shader/material and effect class before use."
    end
    return "Unclassified node. Inspect its source asset and runtime specialization before creating effect XML."
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
    local directShape = self:isDirectShape(node) and "yes" or "no"

    self.contextLabel:setText(string.format("Current effect context: %s  |  id %s  |  %s",
        getName(node), tostring(node), self.toolkit:getNodeTypeLabel(node)))
    self.inspectionLabel:setText(string.format(
        "Mapping path: %s\nDirect Shape: %s\nDirect children: %d\nRecursive Shapes: %d\nMaterial slots: %d\nLocal translation: %.3f %.3f %.3f\nLocal scale: %.3f %.3f %.3f\nAssessment: %s",
        path, directShape, getNumOfChildren(node), shapeCount, materialSlots,
        tx or 0, ty or 0, tz or 0, sx or 0, sy or 0, sz or 0, role))
end

function ADTEffectInspector:printEffectReport()
    local node = self:getContextNode()
    if node == nil then self.toolkit:logWarning("Select an effect node or capture one first."); return end
    local shapeCount, materialSlots = self:getShapeStats(node)
    print("ADT EFFECT INSPECTOR BEGIN")
    print(string.format("Node: %s [%s] type=%s", getName(node), tostring(node), self.toolkit:getNodeTypeLabel(node)))
    print("Mapping: " .. (self:getNodePath(node) or "unknown"))
    print(string.format("directShape=%s directChildren=%d recursiveShapes=%d materialSlots=%d",
        tostring(self:isDirectShape(node)), getNumOfChildren(node), shapeCount, materialSlots))
    print("Assessment: " .. self:getLikelyRole(node, shapeCount))
    if not self:isDirectShape(node) then
        print("SAFETY: Do not pass this TransformGroup to g_effectManager as ShaderPlaneEffect or ParticleEffect geometry.")
    end
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
    if node == nil then self.toolkit:logWarning("Select the intended particle emitter Shape first."); return end
    if not self:isDirectShape(node) then
        self.toolkit:logError("ParticleEffect requires a compatible Shape. The selected node is a TransformGroup; no preset was generated.", node)
        return
    end
    local id = getName(node)
    print("ADT REGISTERED PARTICLE EFFECT PRESET BEGIN")
    print("        <effects>")
    print(string.format('            <effectNode effectNode="%s" effectClass="ParticleEffect" particleType="WASHER_WATER" emitCountScale="7000"/>', id))
    print("        </effects>")
    print("    <i3dMappings>")
    self:printMapping(node)
    print("    </i3dMappings>")
    print("WARNING: WASHER_WATER is a confirmed registered type, but visual suitability depends on the emitter Shape and source specialization.")
    print("WARNING: Generic particleType=smoke is intentionally not generated because it remains unverified.")
    print("ADT REGISTERED PARTICLE EFFECT PRESET END")
    self.toolkit:setStatus("Registered ParticleEffect preset printed for " .. id .. ".")
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
    if not self:isDirectShape(pipeNode) or not self:isDirectShape(smokeNode) then
        self.toolkit:logError("PipeEffect pair must map actual compatible Shapes. One or both selected nodes are TransformGroups; no preset was generated.", parent)
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
    print("WARNING: PipeEffect visibly extends/retracts geometry. This is not free-floating smoke.")
    print("ADT PIPE EFFECT PRESET END")
    self.toolkit:setStatus("PipeEffect pair preset printed.")
end

function ADTEffectInspector:printDynamicSmokePreset()
    local node = self:getContextNode()
    if node == nil then self.toolkit:logWarning("Select the external-smoke attachment node first."); return end
    local id = getName(node)
    if self:isDirectShape(node) then
        self.toolkit:logWarning("External smoke attachment should normally be a TransformGroup, not a rendered Shape.")
    end
    print("ADT EXTERNAL SMOKE LUA GUIDANCE BEGIN")
    print(string.format('    <i3dMapping id="%s" node="%s" />', id, self:getNodePath(node) or "unknown"))
    print("HAND TOOL: load the complete external smoke I3D from custom Lua, link its loaded root under this attachment node, then control visibility in the hand-tool specialization.")
    print("DO NOT: pass this TransformGroup through g_effectManager as ShaderPlaneEffect geometry.")
    print("DO NOT: assume <dynamicallyLoadedParts> works on hand tools; it is specialization-dependent and primarily vehicle-side.")
    print("CONFIRMED ASSET USED IN TESTING: $data/effects/chimneySmoke/smokeTrailSubUV.i3d")
    print("CLEANUP: delete the loaded root and release the shared I3D request when the object is deleted.")
    print("ADT EXTERNAL SMOKE LUA GUIDANCE END")
    self.toolkit:setStatus("Safe external smoke guidance printed for " .. id .. ".")
end

function ADTEffectInspector:onSelectionChanged(nodeId, isSelected)
    self:updateInspection()
end

function ADTEffectInspector:onTabOpen(previous)
    self:updateInspection()
end
