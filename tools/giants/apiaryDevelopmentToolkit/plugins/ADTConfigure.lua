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

    local noteSizer = UIRowLayoutSizer.new()
    fold:addPanel("Important", noteSizer)
    UILabel.new(noteSizer,
        "Generated area endpoints start at small default offsets so they are selectable. Move and scale them to fit the building. Mapping output is printed to the GIANTS Editor console/log and uses the current hierarchy indexes.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 80)

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
        if entityExists(child) and getName(child) == name then
            return child
        end
    end
    return nil
end

function ADTConfigure:ensureGroup(parent, name, tx, ty, tz)
    local existing = self:findDirectChildByName(parent, name)
    if existing ~= nil then
        return existing, false
    end
    local group = createTransformGroup(name)
    if group == nil or not entityExists(group) then
        self.toolkit:logError("Could not create transform group: " .. name, parent)
        return nil, false
    end
    link(parent, group)
    if tx ~= nil then
        setTranslation(group, tx, ty or 0, tz or 0)
    end
    return group, true
end

function ADTConfigure:getHierarchyState(target)
    local present, missing = {}, {}
    for _, name in ipairs(ADTConfigure.STANDARD_GROUPS) do
        if self:findDirectChildByName(target, name) ~= nil then
            table.insert(present, name)
        else
            table.insert(missing, name)
        end
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
    if lights ~= nil then
        group(lights, "realLights")
        group(lights, "interior")
    end

    group(target, "infoTrigger")

    local selling = group(target, "sellingStation")
    if selling ~= nil then
        group(selling, "exactFillRootNode")
        group(selling, "palletTrigger")
        group(selling, "unloadTriggerMarker")
        group(selling, "unloadTriggerAINode", 0, 0, -6)
        group(selling, "unloadTriggerLinkNode")
    end

    local interaction = group(target, "productionInteraction")
    if interaction ~= nil then
        group(interaction, "playerTrigger")
        group(interaction, "playerTriggerMarker")
    end

    local palletSpawner = group(target, "palletSpawner")
    if palletSpawner ~= nil then
        local count = self:getPalletCount()
        for i=1, count do
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

    group(target, "visuals")
    group(target, "collisions")

    refreshViewport(true)
    self:updateStatus()
    self.productionLabel:setText(string.format(
        "Production preset ready under %s. Created %d missing transform node(s). Existing matching nodes were preserved. Pallet lanes: %d.",
        getName(target), created, self:getPalletCount()))
    self.toolkit:logInfo(string.format("Production building preset created under %s: %d new node(s).",
        getName(target), created), target)
end

function ADTConfigure:getNodePath(node)
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

function ADTConfigure:printMappings()
    local target = self:getTarget()
    if target == nil then
        self.toolkit:logWarning("Capture an active target before printing XML mappings.")
        return
    end

    local nodes = self:collectNamedNodes(target)
    print("ADT XML MAPPINGS BEGIN - " .. getName(target))
    print("    <i3dMappings>")
    for _, node in ipairs(nodes) do
        local path = self:getNodePath(node)
        if path ~= nil then
            print(string.format('        <i3dMapping id="%s" node="%s" />', getName(node), path))
        end
    end
    print("    </i3dMappings>")
    print("ADT XML MAPPINGS END")
    self.productionLabel:setText(string.format(
        "Printed %d named-node mapping line(s) to the GIANTS Editor console/log. Review duplicate names and indexes before pasting.", #nodes))
    self.toolkit:setStatus(string.format("Printed %d XML mappings for %s.", #nodes, getName(target)))
end

function ADTConfigure:onSelectionChanged(nodeId, isSelected)
    self:updateStatus()
end

function ADTConfigure:onTabOpen(previous)
    self:updateStatus()
end
