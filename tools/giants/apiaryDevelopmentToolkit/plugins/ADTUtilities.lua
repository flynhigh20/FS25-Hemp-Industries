-- Author:OpenAI + flynhigh20
-- Name:ADT Utilities Plugin
-- Namespace: global
-- Description:General scene reporting, mapping and workflow helpers for Apiary Development Toolkit.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTUtilities = {}
local ADTUtilities_mt = Class(ADTUtilities)

function ADTUtilities.new(toolkit)
    local self = setmetatable({}, ADTUtilities_mt)
    self.toolkit = toolkit
    self.tabName = "Other"
    return self
end

function ADTUtilities:tryEnableResize()
    local window = self.toolkit.window
    if window == nil then return false end

    local methods = {"setResizable", "setResizeable", "setCanResize"}
    for _, methodName in ipairs(methods) do
        local method = window[methodName]
        if type(method) == "function" then
            local ok = pcall(method, window, true)
            if ok then return true end
        end
    end
    return false
end

function ADTUtilities:createTab(layoutSizer)
    self:tryEnableResize()

    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local sceneSizer = UIRowLayoutSizer.new()
    fold:addPanel("Scene and I3D", sceneSizer)
    UILabel.new(sceneSizer,
        "Quick reports for the current I3D. Output is printed to the GIANTS Editor console/log and does not modify the scene.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 58, BorderDirection.BOTTOM, 5)
    UIButton.new(sceneSizer, "Print current I3D path", function() self:printScenePath() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(sceneSizer, "Print scene summary", function() self:printSceneSummary() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(sceneSizer, "Print hierarchy tree", function() self:printHierarchy() end,
        nil, -1, -1, -1, 28)

    local mappingSizer = UIRowLayoutSizer.new()
    fold:addPanel("Mapping helpers", mappingSizer)
    UILabel.new(mappingSizer,
        "Prints current hierarchy paths. Regenerate mappings after adding, deleting, moving or reparenting nodes.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 58, BorderDirection.BOTTOM, 5)
    UIButton.new(mappingSizer, "Print selected node mapping", function() self:printSelectedMapping() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(mappingSizer, "Print all named-node mappings", function() self:printAllMappings() end,
        nil, -1, -1, -1, 28)

    local auditSizer = UIRowLayoutSizer.new()
    fold:addPanel("Scene audit", auditSizer)
    UIButton.new(auditSizer, "Check duplicate node names", function() self:checkDuplicateNames() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(auditSizer, "Check common placeable groups", function() self:checkPlaceableGroups() end,
        nil, -1, -1, -1, 28)

    local windowSizer = UIRowLayoutSizer.new()
    fold:addPanel("Window", windowSizer)
    self.resizeLabel = UILabel.new(windowSizer,
        self:tryEnableResize() and "Resizable window support enabled." or
        "This GIANTS Editor build did not expose a runtime resize method. Saved width and height are still preserved.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 58, BorderDirection.BOTTOM, 5)
    UIButton.new(windowSizer, "Retry resizable window", function()
        local enabled = self:tryEnableResize()
        self.resizeLabel:setText(enabled and "Resizable window support enabled." or
            "No supported runtime resize method was found in this editor build.")
    end, nil, -1, -1, -1, 28)
end

function ADTUtilities:getRoot()
    local target = self.toolkit.activeTarget
    if target ~= nil and entityExists(target) then return target end
    local selected = self.toolkit:getPrimarySelection()
    if selected ~= nil and entityExists(selected) then return selected end
    return nil
end

function ADTUtilities:getNodePath(node)
    if node == nil or not entityExists(node) then return nil end
    local indexes, current = {}, node
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

function ADTUtilities:collectNodes(root, output)
    output = output or {}
    if root == nil or not entityExists(root) then return output end
    table.insert(output, root)
    for i=0, getNumOfChildren(root)-1 do
        self:collectNodes(getChildAt(root, i), output)
    end
    return output
end

function ADTUtilities:printScenePath()
    print("ADT I3D PATH: " .. tostring(getSceneFilename()))
    self.toolkit:setStatus("Printed current I3D path.")
end

function ADTUtilities:printSceneSummary()
    local root = self:getRoot()
    if root == nil then self.toolkit:logWarning("Capture an active target or select a scene root first."); return end
    local nodes = self:collectNodes(root)
    local shapeCount, transformCount, materialSlots = 0, 0, 0
    for _, node in ipairs(nodes) do
        if self.toolkit:isShape(node) then
            shapeCount = shapeCount + 1
            materialSlots = materialSlots + getNumOfMaterials(node)
        else
            transformCount = transformCount + 1
        end
    end
    print("ADT SCENE SUMMARY BEGIN")
    print("I3D: " .. tostring(getSceneFilename()))
    print(string.format("Root: %s | nodes=%d transforms=%d shapes=%d materialSlots=%d",
        getName(root), #nodes, transformCount, shapeCount, materialSlots))
    print("ADT SCENE SUMMARY END")
    self.toolkit:setStatus("Printed scene summary for " .. getName(root) .. ".")
end

function ADTUtilities:printHierarchyNode(node, depth)
    print(string.rep("  ", depth) .. string.format("- %s [%s] %s",
        getName(node), tostring(node), self.toolkit:getNodeTypeLabel(node)))
    for i=0, getNumOfChildren(node)-1 do
        self:printHierarchyNode(getChildAt(node, i), depth + 1)
    end
end

function ADTUtilities:printHierarchy()
    local root = self:getRoot()
    if root == nil then self.toolkit:logWarning("Capture an active target or select a hierarchy root first."); return end
    print("ADT HIERARCHY BEGIN - " .. getName(root))
    self:printHierarchyNode(root, 0)
    print("ADT HIERARCHY END")
    self.toolkit:setStatus("Printed hierarchy for " .. getName(root) .. ".")
end

function ADTUtilities:printSelectedMapping()
    local node = self.toolkit:getPrimarySelection()
    if node == nil then self.toolkit:logWarning("Select a node first."); return end
    print(string.format('        <i3dMapping id="%s" node="%s" />', getName(node), self:getNodePath(node) or "unknown"))
    self.toolkit:setStatus("Printed mapping for " .. getName(node) .. ".")
end

function ADTUtilities:printAllMappings()
    local root = self:getRoot()
    if root == nil then self.toolkit:logWarning("Capture an active target or select a hierarchy root first."); return end
    local nodes = self:collectNodes(root)
    print("ADT ALL MAPPINGS BEGIN - " .. getName(root))
    print("    <i3dMappings>")
    for _, node in ipairs(nodes) do
        local name = getName(node)
        if name ~= nil and name ~= "" then
            print(string.format('        <i3dMapping id="%s" node="%s" />', name, self:getNodePath(node) or "unknown"))
        end
    end
    print("    </i3dMappings>")
    print("ADT ALL MAPPINGS END")
    self.toolkit:setStatus(string.format("Printed %d mapping candidates.", #nodes))
end

function ADTUtilities:checkDuplicateNames()
    local root = self:getRoot()
    if root == nil then self.toolkit:logWarning("Capture an active target or select a hierarchy root first."); return end
    local byName = {}
    for _, node in ipairs(self:collectNodes(root)) do
        local name = getName(node)
        if name ~= nil and name ~= "" then
            byName[name] = byName[name] or {}
            table.insert(byName[name], node)
        end
    end
    local duplicates = 0
    print("ADT DUPLICATE NAME CHECK BEGIN")
    for name, matches in pairs(byName) do
        if #matches > 1 then
            duplicates = duplicates + 1
            print(string.format("DUPLICATE: %s (%d)", name, #matches))
            for _, node in ipairs(matches) do print("  " .. (self:getNodePath(node) or "unknown")) end
        end
    end
    if duplicates == 0 then print("No duplicate named nodes found.") end
    print("ADT DUPLICATE NAME CHECK END")
    self.toolkit:setStatus(string.format("Duplicate-name audit complete: %d duplicate name(s).", duplicates))
end

function ADTUtilities:checkPlaceableGroups()
    local root = self:getRoot()
    if root == nil then self.toolkit:logWarning("Capture the placeable root first."); return end
    local expected = {"collisions", "indoorAreas", "tipOcclusionUpdateAreas", "clearAreas", "levelAreas"}
    local present, missing = {}, {}
    for _, name in ipairs(expected) do
        local found = false
        for i=0, getNumOfChildren(root)-1 do
            if getName(getChildAt(root, i)) == name then found = true break end
        end
        table.insert(found and present or missing, name)
    end
    local message = string.format("Placeable groups present: %s | missing: %s",
        #present > 0 and table.concat(present, ", ") or "none",
        #missing > 0 and table.concat(missing, ", ") or "none")
    print("ADT " .. message)
    if #missing > 0 then self.toolkit:logWarning(message, root) else self.toolkit:logInfo(message, root) end
end

function ADTUtilities:onTabOpen(previous)
    self:tryEnableResize()
end
