-- Author:OpenAI + flynhigh20
-- Name:ADT Placeable Support Plugin
-- Namespace: global
-- Description:Creates and audits required FS25 placeable support nodes without moving existing scene content.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTPlaceableSupport = {}
local ADTPlaceableSupport_mt = Class(ADTPlaceableSupport)

function ADTPlaceableSupport.new(toolkit)
    local self = setmetatable({}, ADTPlaceableSupport_mt)
    self.toolkit = toolkit
    self.tabName = "Placeables"
    return self
end

function ADTPlaceableSupport:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local targetSizer = UIRowLayoutSizer.new()
    fold:addPanel("Active placeable root", targetSizer)
    self.targetLabel = UILabel.new(targetSizer, "Active target: none", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 52, BorderDirection.BOTTOM, 5)
    UIButton.new(targetSizer, "Refresh placeable audit", function() self:updateAudit() end,
        nil, -1, -1, -1, 28)

    local repairSizer = UIRowLayoutSizer.new()
    fold:addPanel("Required support nodes", repairSizer)
    UILabel.new(repairSizer,
        "Adds only missing transform groups for clear, level, indoor, test and tip-occlusion areas. Existing groups and children are preserved. Area width uses local X and area height/depth uses local Z.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 82, BorderDirection.BOTTOM, 5)
    UIButton.new(repairSizer, "Create missing placeable support nodes",
        function() self:createMissingSupportNodes() end,
        nil, -1, -1, -1, 30, BorderDirection.BOTTOM, 5)
    UIButton.new(repairSizer, "Repair selling-station helper nodes",
        function() self:repairSellingStationNodes() end,
        nil, -1, -1, -1, 30, BorderDirection.BOTTOM, 5)
    self.auditLabel = UILabel.new(repairSizer, "Capture the placeable root on the Place tab first.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 165)

    local mappingSizer = UIRowLayoutSizer.new()
    fold:addPanel("After hierarchy changes", mappingSizer)
    UILabel.new(mappingSizer,
        "Run the Mappings tab after adding, deleting, moving or reparenting any node. Index paths are hierarchy-dependent. Do not keep mappings from an earlier export.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 72)

    self:updateAudit()
end

function ADTPlaceableSupport:getTarget()
    local target = self.toolkit.activeTarget
    if target == nil or not entityExists(target) then
        self.toolkit.activeTarget = nil
        return nil
    end
    return target
end

function ADTPlaceableSupport:findDirectChild(parent, name)
    if parent == nil or not entityExists(parent) then return nil end
    for i=0, getNumOfChildren(parent)-1 do
        local child = getChildAt(parent, i)
        if entityExists(child) and getName(child) == name then return child end
    end
    return nil
end

function ADTPlaceableSupport:ensureGroup(parent, name, x, y, z)
    local existing = self:findDirectChild(parent, name)
    if existing ~= nil then return existing, false end
    local node = createTransformGroup(name)
    if node == nil or not entityExists(node) then
        self.toolkit:logError("Could not create placeable node: " .. name, parent)
        return nil, false
    end
    link(parent, node)
    setTranslation(node, x or 0, y or 0, z or 0)
    return node, true
end

function ADTPlaceableSupport:ensureThreePointArea(root, groupName, baseName, width, depth)
    local created = 0
    local group, c1 = self:ensureGroup(root, groupName)
    if c1 then created = created + 1 end
    if group == nil then return created end
    local start, c2 = self:ensureGroup(group, baseName .. "Start01", 0, 0, 0)
    if c2 then created = created + 1 end
    if start == nil then return created end
    local _, c3 = self:ensureGroup(start, baseName .. "Height01", 0, 0, -(depth or 6))
    local _, c4 = self:ensureGroup(start, baseName .. "Width01", width or 10, 0, 0)
    if c3 then created = created + 1 end
    if c4 then created = created + 1 end
    return created
end

function ADTPlaceableSupport:ensurePairArea(root, groupName, baseName, x, y, z)
    local created = 0
    local group, c1 = self:ensureGroup(root, groupName)
    if c1 then created = created + 1 end
    if group == nil then return created end
    local start, c2 = self:ensureGroup(group, baseName .. "Start01", 0, 0, 0)
    if c2 then created = created + 1 end
    if start == nil then return created end
    local _, c3 = self:ensureGroup(start, baseName .. "End01", x or 10, y or 5, z or -6)
    if c3 then created = created + 1 end
    return created
end

function ADTPlaceableSupport:createMissingSupportNodes()
    local target = self:getTarget()
    if target == nil then
        self.toolkit:logWarning("Capture the placeable root before creating support nodes.")
        return
    end

    local created = 0
    created = created + self:ensureThreePointArea(target, "clearAreas", "clearArea", 10, 6)
    created = created + self:ensureThreePointArea(target, "levelAreas", "levelArea", 10, 6)
    created = created + self:ensureThreePointArea(target, "indoorAreas", "indoorArea", 8, 5)
    created = created + self:ensurePairArea(target, "testAreas", "testArea", 10, 4, -6)
    created = created + self:ensurePairArea(target, "tipOcclusionUpdateAreas", "tipOcclusionUpdateArea", 10, 6, -7)

    refreshViewport(true)
    self:updateAudit()
    self.toolkit:logInfo(string.format(
        "Placeable support repair finished under %s: created %d missing transform node(s). Existing nodes were preserved.",
        getName(target), created), target)
end

function ADTPlaceableSupport:repairSellingStationNodes()
    local target = self:getTarget()
    if target == nil then
        self.toolkit:logWarning("Capture the placeable root before repairing selling-station helpers.")
        return
    end

    local selling = self:findDirectChild(target, "sellingStation")
    if selling == nil then
        selling = self:ensureGroup(target, "sellingStation")
    end
    if selling == nil then return end

    local created = 0
    local reserved = self:findDirectChild(selling, "reservedSellingStationNode")
    local exact = self:findDirectChild(selling, "exactFillRootNode")
    if exact == nil and reserved ~= nil then
        setName(reserved, "exactFillRootNode")
        exact = reserved
        self.toolkit:logInfo("Renamed reservedSellingStationNode to exactFillRootNode.", exact)
    elseif exact == nil then
        local _, wasCreated = self:ensureGroup(selling, "exactFillRootNode")
        if wasCreated then created = created + 1 end
    end

    local required = {
        {"palletTrigger", 0, 0, 0},
        {"unloadTriggerAINode", 0, 0, -6},
        {"unloadTriggerMarker", 0, 0, -5}
    }
    for _, data in ipairs(required) do
        local _, wasCreated = self:ensureGroup(selling, data[1], data[2], data[3], data[4])
        if wasCreated then created = created + 1 end
    end

    refreshViewport(true)
    self:updateAudit()
    self.toolkit:logInfo(string.format(
        "Selling-station helper repair finished: created %d missing transform node(s). Trigger shapes still require manual shape and collision setup.",
        created), selling)
end

function ADTPlaceableSupport:getState(target)
    local required = {
        "clearAreas", "levelAreas", "indoorAreas", "testAreas", "tipOcclusionUpdateAreas"
    }
    local present, missing = {}, {}
    for _, name in ipairs(required) do
        if self:findDirectChild(target, name) ~= nil then
            table.insert(present, name)
        else
            table.insert(missing, name)
        end
    end

    local selling = self:findDirectChild(target, "sellingStation")
    local sellingStatus = "sellingStation: not present"
    if selling ~= nil then
        local exact = self:findDirectChild(selling, "exactFillRootNode")
        local reserved = self:findDirectChild(selling, "reservedSellingStationNode")
        if exact ~= nil then sellingStatus = "sellingStation: exactFillRootNode present"
        elseif reserved ~= nil then sellingStatus = "sellingStation: reservedSellingStationNode needs rename"
        else sellingStatus = "sellingStation: exactFillRootNode missing" end
    end
    return present, missing, sellingStatus
end

function ADTPlaceableSupport:updateAudit()
    if self.targetLabel == nil or self.auditLabel == nil then return end
    local target = self:getTarget()
    if target == nil then
        self.targetLabel:setText("Active target: none")
        self.auditLabel:setText("Capture the placeable root on the Place tab first.")
        return
    end
    self.targetLabel:setText(string.format("Active target: %s | node %s | %s",
        getName(target), tostring(target), self.toolkit:getNodeTypeLabel(target)))
    local present, missing, sellingStatus = self:getState(target)
    self.auditLabel:setText(string.format(
        "Present (%d): %s\nMissing (%d): %s\n%s\nDefaults are placeholders only; resize and position every area in GIANTS Editor before game testing.",
        #present, #present > 0 and table.concat(present, ", ") or "none",
        #missing, #missing > 0 and table.concat(missing, ", ") or "none",
        sellingStatus))
end

function ADTPlaceableSupport:onSelectionChanged(nodeId, isSelected)
    self:updateAudit()
end

function ADTPlaceableSupport:onTabOpen(previous)
    self:updateAudit()
end
