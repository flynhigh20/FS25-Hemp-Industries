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
    "visuals", "collisions", "triggers", "particleEffects", "sounds", "interactionNodes"
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
    UIButton.new(targetSizer, "Refresh hierarchy status", function() self:updateStatus() end,
        nil, -1, -1, -1, 28)

    local standardSizer = UIRowLayoutSizer.new()
    fold:addPanel("Standard child groups", standardSizer)
    UILabel.new(standardSizer,
        "Creates only missing direct child transform groups. Existing nodes are preserved and nothing is renamed, moved or deleted.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 55, BorderDirection.BOTTOM, 5)
    UIButton.new(standardSizer, "Create missing standard groups", function() self:createMissingGroups() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    self.statusLabel = UILabel.new(standardSizer, "Capture an active target on the Place tab first.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 120)

    local productionSizer = UIRowLayoutSizer.new()
    fold:addPanel("Production building preset", productionSizer)
    UILabel.new(productionSizer,
        "Builds a non-destructive production-point node skeleton modeled after working base-game factories. These are transform nodes only; trigger shapes, collision masks, dimensions and final placement still require setup.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 75, BorderDirection.BOTTOM, 5)

    local palletRow = UIColumnLayoutSizer.new()
    UIPanel.new(productionSizer, palletRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    UILabel.new(palletRow, "Pallet spawn lanes", false, TextAlignment.LEFT, VerticalAlignment.CENTER,
        -1, -1, 160, 25, BorderDirection.RIGHT, 5)
    self.palletCountInput = UITextArea.new(palletRow, "4", TextAlignment.LEFT, false, false,
        -1, -1, 80, 25)

    UIButton.new(productionSizer, "Create production building preset",
        function() self:createProductionPreset() end,
        nil, -1, -1, -1, 30, BorderDirection.BOTTOM, 5)
    UIButton.new(productionSizer, "Print XML mappings for active target",
        function() self:printMappings() end,
        nil, -1, -1, -1, 30, BorderDirection.BOTTOM, 5)
    self.productionLabel = UILabel.new(productionSizer,
        "Preset status: waiting for an active target.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 95)

    local effectSizer = UIRowLayoutSizer.new()
    fold:addPanel("Effect setup and validation", effectSizer)
    UILabel.new(effectSizer,
        "Creates safe transform placeholders for common GIANTS effect layouts and validates XML effect IDs against actual scene-node names and paths.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 65, BorderDirection.BOTTOM, 5)
    UIButton.new(effectSizer, "Create directed smoke pair",
        function() self:createDirectedSmokePair() end,
        nil, -1, -1, -1, 30, BorderDirection.BOTTOM, 5)
    UIButton.new(effectSizer, "Create dynamic smoke link node",
        function() self:createDynamicSmokeLink() end,
        nil, -1, -1, -1, 30, BorderDirection.BOTTOM, 5)

    local idsRow = UIColumnLayoutSizer.new()
    UIPanel.new(effectSizer, idsRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    UILabel.new(idsRow, "Expected XML IDs", false, TextAlignment.LEFT, VerticalAlignment.CENTER,
        -1, -1, 160, 25, BorderDirection.RIGHT, 5)
    self.effectIdsInput = UITextArea.new(idsRow, "pipeEffect, pipeEffectSmoke", TextAlignment.LEFT, false, false,
        -1, -1, 300, 25)

    UIButton.new(effectSizer, "Validate effect mappings",
        function() self:validateEffectMappings() end,
        nil, -1, -1, -1, 30, BorderDirection.BOTTOM, 5)
    self.effectLabel = UILabel.new(effectSizer,
        "Validator status: waiting for an active target.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 120)

    local noteSizer = UIRowLayoutSizer.new()
    fold:addPanel("Important", noteSizer)
    UILabel.new(noteSizer,
        "Generated nodes are placeholders. Imported effect meshes must keep their original materials and relative transforms. Mapping output uses the current hierarchy indexes, so print it again after moving or reparenting nodes.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 90)

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

function ADTConfigure:getPalletCount()
    local value = tonumber(self.palletCountInput ~= nil and self.palletCountInput:getValue() or "4") or 4
    return math.max(1, math.min(8, math.floor(value)))
end

function ADTConfigure:findDirectChildByName(parent, name)
    for i=0, getNumOfChildren(parent)-1 do
        local child = getChildAt(parent, i)
        if entityExists(child) and getName(child) == name then return child end
    end
    return nil
end

function ADTConfigure:findNodesByName(root, name, output)
    output = output or {}
    if getName(root) == name then table.insert(output, root) end
    for i=0, getNumOfChildren(root)-1 do
        local child = getChildAt(root, i)
        if entityExists(child) then self:findNodesByName(child, name, output) end
    end
    return output
end

function ADTConfigure:ensureGroup(parent, name, tx, ty, tz)
    local existing = self:findDirectChildByName(parent, name)
    if existing ~= nil then return existing, false end
    local group = createTransformGroup(name)
    if group == nil or not entityExists(group) then
        self.toolkit:logError("Could not create transform group: " .. name, parent)
        return nil, false
    end
    link(parent, group)
    if tx ~= nil then setTranslation(group, tx, ty or 0, tz or 0) end
    return group, true
end

function ADTConfigure:getHierarchyState(target)
    local present, missing = {}, {}
    for _, name in ipairs(ADTConfigure.STANDARD_GROUPS) do
        if self:findDirectChildByName(target, name) ~= nil then table.insert(present, name)
        else table.insert(missing, name) end
    end
    return present, missing
end

function ADTConfigure:updateStatus()
    if self.targetLabel == nil or self.statusLabel == nil then return end
    local target = self:getTarget()
    if target == nil then
        self.targetLabel:setText("Active target: none")
        self.statusLabel:setText("Capture an active target on the Place tab first.")
        if self.productionLabel ~= nil then self.productionLabel:setText("Preset status: waiting for an active target.") end
        if self.effectLabel ~= nil then self.effectLabel:setText("Validator status: waiting for an active target.") end
        return
    end

    self.targetLabel:setText(string.format("Active target: %s  |  node %s  |  %s",
        getName(target), tostring(target), self.toolkit:getNodeTypeLabel(target)))
    local present, missing = self:getHierarchyState(target)
    self.statusLabel:setText(string.format(
        "Present (%d): %s\nMissing (%d): %s\nDirect children currently under target: %d",
        #present, #present > 0 and table.concat(present, ", ") or "none",
        #missing, #missing > 0 and table.concat(missing, ", ") or "none",
        getNumOfChildren(target)))
end

function ADTConfigure:createMissingGroups()
    local target = self:getTarget()
    if target == nil then
        self.toolkit:logWarning("Capture an active target on the Place tab before configuring hierarchy.")
        self:updateStatus()
        return
    end
    local created, preserved = 0, 0
    for _, name in ipairs(ADTConfigure.STANDARD_GROUPS) do
        local _, wasCreated = self:ensureGroup(target, name)
        if wasCreated then created = created + 1 else preserved = preserved + 1 end
    end
    refreshViewport(true)
    self:updateStatus()
    self.toolkit:logInfo(string.format(
        "Hierarchy configured under %s: created %d missing group(s), preserved %d existing group(s).",
        getName(target), created, preserved), target)
end

function ADTConfigure:createAreaThreePoint(parent, baseName, index, xOffset)
    local suffix = string.format("%02d", index)
    local start, c1 = self:ensureGroup(parent, baseName .. "Start" .. suffix, xOffset or 0, 0, 0)
    if start == nil then return c1 and 1 or 0 end
    local _, c2 = self:ensureGroup(start, baseName .. "Width" .. suffix, 3, 0, 0)
    local _, c3 = self:ensureGroup(start, baseName .. "Height" .. suffix, 0, 3, 0)
    return (c1 and 1 or 0) + (c2 and 1 or 0) + (c3 and 1 or 0)
end

function ADTConfigure:createAreaPair(parent, baseName, index, xOffset)
    local suffix = string.format("%02d", index)
    local start, c1 = self:ensureGroup(parent, baseName .. "Start" .. suffix, xOffset or 0, 0, 0)
    if start == nil then return c1 and 1 or 0 end
    local _, c2 = self:ensureGroup(start, baseName .. "End" .. suffix, 3, 0, 3)
    return (c1 and 1 or 0) + (c2 and 1 or 0)
end

function ADTConfigure:createProductionPreset()
    local target = self:getTarget()
    if target == nil then
        self.toolkit:logWarning("Capture the building root on the Place tab before creating the production preset.")
        self:updateStatus()
        return
    end
    local created = 0
    local function group(parent, name, x, y, z)
        local node, wasCreated = self:ensureGroup(parent, name, x, y, z)
        if wasCreated then created = created + 1 end
        return node
    end

    local indoor = group(target, "indoorAreas")
    if indoor ~= nil then
        created = created + self:createAreaThreePoint(indoor, "indoorArea", 1, 0)
        created = created + self:createAreaThreePoint(indoor, "indoorArea", 2, 5)
    end
    local tipAreas = group(target, "tipOcclusionUpdateAreas")
    if tipAreas ~= nil then created = created + self:createAreaPair(tipAreas, "tipOcclusionUpdateArea", 1, 0) end
    local lights = group(target, "lights")
    if lights ~= nil then group(lights, "realLights"); group(lights, "interior") end
    group(target, "infoTrigger")
    local selling = group(target, "sellingStation")
    if selling ~= nil then
        group(selling, "exactFillRootNode"); group(selling, "palletTrigger")
        group(selling, "unloadTriggerMarker"); group(selling, "unloadTriggerAINode", 0, 0, -6)
        group(selling, "unloadTriggerLinkNode")
    end
    local interaction = group(target, "productionInteraction")
    if interaction ~= nil then group(interaction, "playerTrigger"); group(interaction, "playerTriggerMarker") end
    local palletSpawner = group(target, "palletSpawner")
    if palletSpawner ~= nil then
        for i=1, self:getPalletCount() do
            local start, c1 = self:ensureGroup(palletSpawner, string.format("palletAreaStart%02d", i), (i-1)*2.2, 0, 0)
            if c1 then created = created + 1 end
            if start ~= nil then
                local _, c2 = self:ensureGroup(start, string.format("palletAreaEnd%02d", i), 1.8, 0, 2.2)
                if c2 then created = created + 1 end
            end
        end
        group(palletSpawner, "warningStripes01")
    end
    local dynamic = group(target, "dynamicallyLoadedParts")
    if dynamic ~= nil then group(dynamic, "props") end
    group(target, "visuals"); group(target, "collisions")

    refreshViewport(true)
    self:updateStatus()
    self.productionLabel:setText(string.format(
        "Production preset ready under %s. Created %d missing transform node(s). Existing matching nodes were preserved. Pallet lanes: %d.",
        getName(target), created, self:getPalletCount()))
    self.toolkit:logInfo(string.format("Production building preset created under %s: %d new node(s).",
        getName(target), created), target)
end

function ADTConfigure:createDirectedSmokePair()
    local target = self:getTarget()
    if target == nil then self.toolkit:logWarning("Capture the nozzle or effect parent before creating a directed smoke pair."); return end
    local effects, c1 = self:ensureGroup(target, "effects")
    if effects == nil then return end
    local _, c2 = self:ensureGroup(effects, "pipeEffect", 0, 0, 0)
    local _, c3 = self:ensureGroup(effects, "pipeEffectSmoke", 0, 0, 0)
    refreshViewport(true)
    local created = (c1 and 1 or 0) + (c2 and 1 or 0) + (c3 and 1 or 0)
    self.effectLabel:setText(string.format("Directed smoke layout ready. Created %d node(s). Import or replace the two placeholders with the matching effect meshes before use.", created))
    self.toolkit:logInfo("Directed smoke pair ready: effects/pipeEffect + pipeEffectSmoke.", effects)
end

function ADTConfigure:createDynamicSmokeLink()
    local target = self:getTarget()
    if target == nil then self.toolkit:logWarning("Capture the nozzle or desired attachment parent first."); return end
    local node, created = self:ensureGroup(target, "smokeLinkNode")
    refreshViewport(true)
    self.effectLabel:setText(created and
        "Created smokeLinkNode. Use it as linkNode for a dynamicallyLoadedPart such as chimney smoke." or
        "smokeLinkNode already exists and was preserved.")
    self.toolkit:logInfo("Dynamic smoke link node ready.", node)
end

function ADTConfigure:getNodePath(node)
    if node == nil or not entityExists(node) then return nil end
    local indexes, current = {}, node
    while current ~= nil and entityExists(current) do
        local parent = getParent(current)
        if parent == nil or parent == 0 then break end
        local found = nil
        for i=0, getNumOfChildren(parent)-1 do if getChildAt(parent, i) == current then found = i break end end
        if found == nil then return nil end
        table.insert(indexes, 1, tostring(found))
        current = parent
    end
    if #indexes == 0 then return "0>" end
    return "0>" .. table.concat(indexes, "|")
end

function ADTConfigure:collectNamedNodes(root, output)
    output = output or {}
    for i=0, getNumOfChildren(root)-1 do
        local child = getChildAt(root, i)
        if entityExists(child) then
            local name = getName(child)
            if name ~= nil and name ~= "" then table.insert(output, child) end
            self:collectNamedNodes(child, output)
        end
    end
    return output
end

function ADTConfigure:parseExpectedIds()
    local text = self.effectIdsInput ~= nil and self.effectIdsInput:getValue() or ""
    local ids, seen = {}, {}
    for id in string.gmatch(text, "[^,%s]+") do
        if id ~= "" and not seen[id] then table.insert(ids, id); seen[id] = true end
    end
    return ids
end

function ADTConfigure:validateEffectMappings()
    local target = self:getTarget()
    if target == nil then self.toolkit:logWarning("Capture the model root before validating effect mappings."); return end
    local ids = self:parseExpectedIds()
    if #ids == 0 then self.toolkit:logWarning("Enter one or more expected XML IDs separated by commas."); return end

    local missing, duplicate, valid = {}, {}, 0
    print("ADT EFFECT VALIDATION BEGIN - " .. getName(target))
    for _, id in ipairs(ids) do
        local matches = self:findNodesByName(target, id)
        if #matches == 0 then
            table.insert(missing, id)
            print("MISSING: " .. id)
        elseif #matches > 1 then
            table.insert(duplicate, id)
            print(string.format("DUPLICATE: %s (%d matches)", id, #matches))
            for _, node in ipairs(matches) do print(string.format('  <i3dMapping id="%s" node="%s" />', id, self:getNodePath(node) or "unknown")) end
        else
            valid = valid + 1
            print(string.format('OK: <i3dMapping id="%s" node="%s" />', id, self:getNodePath(matches[1]) or "unknown"))
        end
    end
    print("ADT EFFECT VALIDATION END")

    local message = string.format("Effect validation: %d valid, %d missing, %d duplicate ID(s).", valid, #missing, #duplicate)
    if #missing > 0 then message = message .. " Missing: " .. table.concat(missing, ", ") .. "." end
    if #duplicate > 0 then message = message .. " Duplicates: " .. table.concat(duplicate, ", ") .. "." end
    self.effectLabel:setText(message .. " Suggested mapping lines were printed to the console/log.")
    self.toolkit:setStatus(message)
end

function ADTConfigure:printMappings()
    local target = self:getTarget()
    if target == nil then self.toolkit:logWarning("Capture an active target before printing XML mappings."); return end
    local nodes = self:collectNamedNodes(target)
    print("ADT XML MAPPINGS BEGIN - " .. getName(target))
    print("    <i3dMappings>")
    for _, node in ipairs(nodes) do
        local path = self:getNodePath(node)
        if path ~= nil then print(string.format('        <i3dMapping id="%s" node="%s" />', getName(node), path)) end
    end
    print("    </i3dMappings>")
    print("ADT XML MAPPINGS END")
    self.productionLabel:setText(string.format(
        "Printed %d named-node mapping line(s) to the GIANTS Editor console/log. Review duplicate names and indexes before pasting.", #nodes))
    self.toolkit:setStatus(string.format("Printed %d XML mappings for %s.", #nodes, getName(target)))
end

function ADTConfigure:onSelectionChanged(nodeId, isSelected) self:updateStatus() end
function ADTConfigure:onTabOpen(previous) self:updateStatus() end
