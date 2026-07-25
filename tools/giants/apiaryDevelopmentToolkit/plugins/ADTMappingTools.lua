-- Author:OpenAI + flynhigh20
-- Name:ADT Mapping Tools Plugin
-- Namespace: global
-- Description:I3D-relative mapping inspection, subtree export and duplicate-name validation.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTMappingTools = {}
local ADTMappingTools_mt = Class(ADTMappingTools)

function ADTMappingTools.new(toolkit)
    local self = setmetatable({}, ADTMappingTools_mt)
    self.toolkit = toolkit
    self.tabName = "Mappings"
    return self
end

function ADTMappingTools:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local contextSizer = UIRowLayoutSizer.new()
    fold:addPanel("Mapping context", contextSizer)
    self.contextLabel = UILabel.new(contextSizer,
        "Capture the loaded I3D root on Place, then select any node to inspect its XML path.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 68, BorderDirection.BOTTOM, 5)
    UIButton.new(contextSizer, "Refresh mapping context", function() self:updateContext() end,
        nil, -1, -1, -1, 28)

    local pathSizer = UIRowLayoutSizer.new()
    fold:addPanel("Current node path", pathSizer)
    self.pathLabel = UILabel.new(pathSizer, "No valid node selected.", true,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 105, BorderDirection.BOTTOM, 5)
    UIButton.new(pathSizer, "Print selected mapping line", function() self:printSelectedMapping() end,
        nil, -1, -1, -1, 28)

    local exportSizer = UIRowLayoutSizer.new()
    fold:addPanel("Subtree mapping export", exportSizer)
    UILabel.new(exportSizer,
        "Exports the selected node and all named descendants using paths relative to the captured I3D root. Duplicate names are flagged instead of silently producing unsafe XML IDs.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 72, BorderDirection.BOTTOM, 5)
    UIButton.new(exportSizer, "Print selected subtree mappings", function() self:printSubtreeMappings() end,
        nil, -1, -1, -1, 30, BorderDirection.BOTTOM, 5)
    UIButton.new(exportSizer, "Check duplicate names in active target", function() self:checkDuplicateNames() end,
        nil, -1, -1, -1, 30)

    local rootSizer = UIRowLayoutSizer.new()
    fold:addPanel("Root sanity checks", rootSizer)
    UILabel.new(rootSizer,
        "The captured active target is treated as the loaded I3D root and must map to 0>. Direct children must map to 0>0, 0>1, and so on. Editor scene-root indexes are excluded.",
        true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, 80, BorderDirection.BOTTOM, 5)
    UIButton.new(rootSizer, "Validate root and first-level paths", function() self:validateRootPaths() end,
        nil, -1, -1, -1, 30)

    self:updateContext()
end

function ADTMappingTools:getRoot()
    local root = self.toolkit.activeTarget
    if root ~= nil and entityExists(root) then return root end
    return nil
end

function ADTMappingTools:getSelection()
    local node = self.toolkit:getPrimarySelection()
    if node ~= nil and entityExists(node) then return node end
    return self:getRoot()
end

function ADTMappingTools:isDescendantOrSelf(root, node)
    local current = node
    while current ~= nil and current ~= 0 and entityExists(current) do
        if current == root then return true end
        current = getParent(current)
    end
    return false
end

function ADTMappingTools:getRelativePath(node)
    local root = self:getRoot()
    if root == nil or node == nil or not entityExists(node) then return nil, "Capture the loaded I3D root first." end
    if not self:isDescendantOrSelf(root, node) then return nil, "Selected node is outside the captured I3D root." end
    if node == root then return "0>", nil end

    local indexes = {}
    local current = node
    while current ~= root do
        local parent = getParent(current)
        if parent == nil or parent == 0 or not entityExists(parent) then
            return nil, "Could not reach captured root while calculating path."
        end
        local index = nil
        for i=0, getNumOfChildren(parent)-1 do
            if getChildAt(parent, i) == current then index = i break end
        end
        if index == nil then return nil, "Could not resolve child index." end
        table.insert(indexes, 1, tostring(index))
        current = parent
    end
    return "0>" .. table.concat(indexes, "|"), nil
end

function ADTMappingTools:updateContext()
    if self.contextLabel == nil or self.pathLabel == nil then return end
    local root = self:getRoot()
    local node = self:getSelection()
    if root == nil then
        self.contextLabel:setText("Active I3D root: none. Capture the loaded model root on Place.")
        self.pathLabel:setText("Mapping path unavailable until an I3D root is captured.")
        return
    end
    self.contextLabel:setText(string.format("Active I3D root: %s [%s]", getName(root), tostring(root)))
    if node == nil then
        self.pathLabel:setText("No valid selected node.")
        return
    end
    local path, err = self:getRelativePath(node)
    if path == nil then
        self.pathLabel:setText(string.format("Selected: %s\nPath error: %s", getName(node), err or "unknown"))
    else
        self.pathLabel:setText(string.format("Selected: %s [%s]\nI3D-relative XML path: %s\nMapping: <i3dMapping id=\"%s\" node=\"%s\" />",
            getName(node), tostring(node), path, getName(node), path))
    end
end

function ADTMappingTools:printSelectedMapping()
    local node = self:getSelection()
    if node == nil then self.toolkit:logWarning("Select a node or capture the I3D root first."); return end
    local path, err = self:getRelativePath(node)
    if path == nil then self.toolkit:logWarning(err or "Could not calculate mapping path."); return end
    print(string.format('<i3dMapping id="%s" node="%s" />', getName(node), path))
    self.toolkit:setStatus("Printed mapping for " .. getName(node) .. ".")
end

function ADTMappingTools:collectSubtree(root, output)
    output = output or {}
    table.insert(output, root)
    for i=0, getNumOfChildren(root)-1 do
        local child = getChildAt(root, i)
        if entityExists(child) then self:collectSubtree(child, output) end
    end
    return output
end

function ADTMappingTools:buildNameIndex(nodes)
    local names = {}
    for _, node in ipairs(nodes) do
        local name = getName(node)
        if name ~= nil and name ~= "" then
            names[name] = names[name] or {}
            table.insert(names[name], node)
        end
    end
    return names
end

function ADTMappingTools:printSubtreeMappings()
    local node = self:getSelection()
    if node == nil then self.toolkit:logWarning("Select a subtree root first."); return end
    local nodes = self:collectSubtree(node)
    local names = self:buildNameIndex(nodes)
    local printed, duplicates = 0, 0

    print("ADT SUBTREE MAPPINGS BEGIN - " .. getName(node))
    print("    <i3dMappings>")
    for _, current in ipairs(nodes) do
        local name = getName(current)
        if name ~= nil and name ~= "" then
            if #names[name] == 1 then
                local path = self:getRelativePath(current)
                if path ~= nil then
                    print(string.format('        <i3dMapping id="%s" node="%s" />', name, path))
                    printed = printed + 1
                end
            elseif current == names[name][1] then
                duplicates = duplicates + 1
                print(string.format("        <!-- DUPLICATE ID SKIPPED: %s (%d nodes) -->", name, #names[name]))
            end
        end
    end
    print("    </i3dMappings>")
    print("ADT SUBTREE MAPPINGS END")
    self.toolkit:setStatus(string.format("Printed %d unique mapping(s); skipped %d duplicate name(s).", printed, duplicates))
end

function ADTMappingTools:checkDuplicateNames()
    local root = self:getRoot()
    if root == nil then self.toolkit:logWarning("Capture the loaded I3D root first."); return end
    local nodes = self:collectSubtree(root)
    local names = self:buildNameIndex(nodes)
    local duplicateNames = 0
    print("ADT DUPLICATE MAPPING IDS BEGIN")
    for name, matches in pairs(names) do
        if #matches > 1 then
            duplicateNames = duplicateNames + 1
            print(string.format("DUPLICATE: %s (%d nodes)", name, #matches))
            for _, node in ipairs(matches) do
                local path = self:getRelativePath(node) or "unknown"
                print(string.format("  %s [%s] -> %s", getName(node), tostring(node), path))
            end
        end
    end
    print("ADT DUPLICATE MAPPING IDS END")
    self.toolkit:setStatus(string.format("Duplicate-name scan complete: %d duplicate XML ID name(s).", duplicateNames))
end

function ADTMappingTools:validateRootPaths()
    local root = self:getRoot()
    if root == nil then self.toolkit:logWarning("Capture the loaded I3D root first."); return end
    local rootPath = self:getRelativePath(root)
    print("ADT ROOT PATH VALIDATION BEGIN")
    print(string.format("ROOT: %s -> %s", getName(root), rootPath or "ERROR"))
    local failures = rootPath == "0>" and 0 or 1
    for i=0, getNumOfChildren(root)-1 do
        local child = getChildAt(root, i)
        local path = self:getRelativePath(child)
        local expected = "0>" .. tostring(i)
        local ok = path == expected
        if not ok then failures = failures + 1 end
        print(string.format("%s childIndex=%d actual=%s expected=%s", ok and "OK" or "ERROR", i, path or "nil", expected))
    end
    print("ADT ROOT PATH VALIDATION END")
    self.toolkit:setStatus(string.format("Root-path validation complete: %d failure(s).", failures))
end

function ADTMappingTools:onSelectionChanged(nodeId, isSelected)
    self:updateContext()
end

function ADTMappingTools:onTabOpen(previous)
    self:updateContext()
end
