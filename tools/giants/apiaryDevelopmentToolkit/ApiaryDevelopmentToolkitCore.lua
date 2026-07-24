-- Author:OpenAI + flynhigh20
-- Name:ApiaryDevelopmentToolkitCore
-- Namespace: global
-- Description:Core window and plugin host for Apiary Development Toolkit.
-- Hide: yes
-- AlwaysLoaded: no

source("EditorSettings.lua")
source("editorUtils.lua")
source("ui/MessageBox.lua")
source("ui/LogListDialog.lua")

ApiaryDevelopmentToolkit = {}
ApiaryDevelopmentToolkit.VERSION = "0.4.0"
ApiaryDevelopmentToolkit.WINDOW_WIDTH = 840
ApiaryDevelopmentToolkit.WINDOW_HEIGHT = 720

local ApiaryDevelopmentToolkit_mt = Class(ApiaryDevelopmentToolkit)

function ApiaryDevelopmentToolkit.new()
    local self = setmetatable({}, ApiaryDevelopmentToolkit_mt)

    self.config = EditorSettings.new("apiaryDevelopmentToolkit")
    self.plugins = {}
    self.classNameToPlugin = {}
    self.tabNameToPlugin = {}
    self.currentTab = nil
    self.window = nil
    self.positionX = self.config:getValue("positionX", -1)
    self.positionY = self.config:getValue("positionY", -1)
    self.windowWidth = self.config:getValue("windowWidth", ApiaryDevelopmentToolkit.WINDOW_WIDTH)
    self.windowHeight = self.config:getValue("windowHeight", ApiaryDevelopmentToolkit.WINDOW_HEIGHT)
    self.logDialog = LogListDialog.new("Apiary Development Toolkit log")
    self.statusText = "Ready"

    return self
end

function ApiaryDevelopmentToolkit:addPlugin(className, filename)
    local absolutePath = buildAbsolutePath(getEditorDirectory() .. "scripts/", filename)
    if not fileExists(absolutePath) then
        printError("ADT plugin file missing: " .. filename)
        return
    end

    source(filename)
    local class = _G[className]
    if class == nil then
        printError("ADT plugin class missing: " .. className)
        return
    end

    local instance = class.new(self)
    instance.className = className
    self.classNameToPlugin[className] = instance
    self.tabNameToPlugin[instance.tabName] = instance
    table.insert(self.plugins, instance)
end

function ApiaryDevelopmentToolkit:show()
    if string.isNilOrWhitespace(getSceneFilename()) then
        MessageBox.show("Apiary Development Toolkit", "Open an I3D scene before starting the toolkit.")
        return
    end

    self:createUI()
    self:registerListeners()
    self.window:showWindow()
    self:setStatus("Loaded scene: " .. self:getSceneAssetName())
end

function ApiaryDevelopmentToolkit:createUI()
    local frameSizer = UIRowLayoutSizer.new()
    self.window = UIWindow.new(frameSizer, "Apiary Development Toolkit", true, false,
        self.positionX, self.positionY, self.windowWidth, self.windowHeight)

    local rootSizer = UIRowLayoutSizer.new()
    UIPanel.new(frameSizer, rootSizer, -1, -1, -1, -1, BorderDirection.ALL, 10, 1)

    local titleSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rootSizer, titleSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
    local title = UILabel.new(titleSizer, "Apiary Development Toolkit", false,
        TextAlignment.LEFT, VerticalAlignment.CENTER, -1, -1, -1, 28, BorderDirection.RIGHT, 10, 1)
    title:setBold(true)
    self.assetLabel = UILabel.new(titleSizer,
        string.format("%s  |  v%s", self:getSceneAssetName(), ApiaryDevelopmentToolkit.VERSION),
        false, TextAlignment.RIGHT, VerticalAlignment.CENTER, -1, -1, -1, 28)

    self.notebook = UINotebook.new(rootSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    for _, plugin in ipairs(self.plugins) do
        local tabSizer = UIRowLayoutSizer.new()
        self.notebook:addTab(plugin.tabName, tabSizer)
        plugin:createTab(tabSizer)
    end

    self.currentTab = self.plugins[1]
    self.notebook:setOnTabChangeCallback(function(tabName)
        local previous = self.currentTab
        local nextTab = self.tabNameToPlugin[tabName]
        if previous ~= nil and previous.onTabClose ~= nil then
            previous:onTabClose(nextTab)
        end
        if nextTab ~= nil and nextTab.onTabOpen ~= nil then
            nextTab:onTabOpen(previous)
        end
        self.currentTab = nextTab
    end)

    UIHorizontalLine.new(rootSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    local statusSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rootSizer, statusSizer, -1, -1, -1, 28, BorderDirection.NONE, 0)
    self.statusLabel = UILabel.new(statusSizer, self.statusText, false,
        TextAlignment.LEFT, VerticalAlignment.CENTER, -1, -1, -1, -1, BorderDirection.RIGHT, 10, 1)
    UIButton.new(statusSizer, "Open Log", function() self.logDialog:showUI() end, nil, -1, -1, 90, -1)

    self.window:setOnCloseCallback(function() self:onClose() end)
    self.window:setOnFocusCallback(function() self:onFocus() end)
end

function ApiaryDevelopmentToolkit:registerListeners()
    self.importListener = addEventListener(HookType.ON_FILE_IMPORTED, self.onFileImported, self)
    self.selectionListener = addEventListener(HookType.ON_SELECTION_CHANGED, self.onSelectionChanged, self)
    self.saveListener = addEventListener(HookType.ON_SAVE, self.onSave, self)
end

function ApiaryDevelopmentToolkit:onFileImported(filepath, nodes)
    for _, plugin in ipairs(self.plugins) do
        if plugin.onFileImported ~= nil then
            plugin:onFileImported(filepath, nodes)
        end
    end
end

function ApiaryDevelopmentToolkit:onSelectionChanged(nodeId, isSelected)
    for _, plugin in ipairs(self.plugins) do
        if plugin.onSelectionChanged ~= nil then
            plugin:onSelectionChanged(nodeId, isSelected)
        end
    end
end

function ApiaryDevelopmentToolkit:onSave(filepath)
    self:setStatus("Saved scene: " .. self:getSceneAssetName())
end

function ApiaryDevelopmentToolkit:onFocus()
    local x, y = self.window:getPosition()
    local width, height = self.window:getSize()
    self.positionX = x
    self.positionY = y
    self.windowWidth = width
    self.windowHeight = height
end

function ApiaryDevelopmentToolkit:onClose()
    if self.importListener ~= nil then
        removeEventListener(HookType.ON_FILE_IMPORTED, self.importListener)
        self.importListener = nil
    end
    if self.selectionListener ~= nil then
        removeEventListener(HookType.ON_SELECTION_CHANGED, self.selectionListener)
        self.selectionListener = nil
    end
    if self.saveListener ~= nil then
        removeEventListener(HookType.ON_SAVE, self.saveListener)
        self.saveListener = nil
    end

    self.config:setValue("positionX", self.positionX)
    self.config:setValue("positionY", self.positionY)
    self.config:setValue("windowWidth", self.windowWidth)
    self.config:setValue("windowHeight", self.windowHeight)
    self.config:saveSettings()

    for _, plugin in ipairs(self.plugins) do
        if plugin.delete ~= nil then
            plugin:delete()
        end
    end

    self.logDialog:close()
end

function ApiaryDevelopmentToolkit:close()
    if self.window ~= nil then
        self.window:close()
    end
end

function ApiaryDevelopmentToolkit:setStatus(text)
    self.statusText = text
    if self.statusLabel ~= nil then
        self.statusLabel:setText(text)
    end
    print("ADT: " .. text)
end

function ApiaryDevelopmentToolkit:logInfo(text, node)
    self.logDialog:addItem(LogListDialog.TYPE_INFO, text, node)
    self:setStatus(text)
end

function ApiaryDevelopmentToolkit:logWarning(text, node)
    self.logDialog:addItem(LogListDialog.TYPE_WARNING, text, node)
    self:setStatus(text)
end

function ApiaryDevelopmentToolkit:logError(text, node)
    self.logDialog:addItem(LogListDialog.TYPE_ERROR, text, node)
    self:setStatus(text)
end

function ApiaryDevelopmentToolkit:getSceneAssetName()
    local filename = getSceneFilename() or "Untitled scene"
    local basename = string.match(filename, "([^/\\]+)$") or filename
    return string.gsub(basename, "%.i3d$", "")
end

function ApiaryDevelopmentToolkit:getPrimarySelection()
    if getNumSelected() == 0 then
        return nil
    end
    return getSelection(0)
end

function ApiaryDevelopmentToolkit:isShape(node)
    return node ~= nil and entityExists(node) and getHasClassId(node, ClassIds.SHAPE)
end

function ApiaryDevelopmentToolkit:getNodeTypeLabel(node)
    if node == nil or not entityExists(node) then
        return "invalid"
    end
    local classes = EditorUtils.getNodeClasses(node)
    if classes == nil or #classes == 0 then
        return "entity"
    end
    table.sort(classes)
    return table.concat(classes, ", ")
end

function ApiaryDevelopmentToolkit:collectShapes(node, output, seen)
    output = output or {}
    seen = seen or {}

    if node == nil or not entityExists(node) or seen[node] then
        return output
    end
    seen[node] = true

    if self:isShape(node) then
        table.insert(output, node)
    end

    for i=0, getNumOfChildren(node)-1 do
        self:collectShapes(getChildAt(node, i), output, seen)
    end

    return output
end

function ApiaryDevelopmentToolkit:getShapesFromPrimarySelection()
    local node = self:getPrimarySelection()
    if node == nil then
        return {}, nil
    end
    return self:collectShapes(node), node
end

function ApiaryDevelopmentToolkit:getSelectedShapes()
    local shapes = {}
    local seen = {}
    for i=0, getNumSelected()-1 do
        self:collectShapes(getSelection(i), shapes, seen)
    end
    return shapes
end

function ApiaryDevelopmentToolkit:findFirstShapeWithMaterialSlot(rootNode, slot)
    local shapes = self:collectShapes(rootNode)
    for _, shape in ipairs(shapes) do
        if getNumOfMaterials(shape) > slot then
            return shape
        end
    end
    return nil
end

function ApiaryDevelopmentToolkit:getMaterialDisplayName(materialId)
    if materialId == nil or materialId == 0 then
        return "none"
    end

    local materialName = ""
    if entityExists(materialId) then
        local ok, value = pcall(getName, materialId)
        if ok and value ~= nil and not string.isNilOrWhitespace(value) then
            materialName = value
        end
    end

    if string.isNilOrWhitespace(materialName) then
        return string.format("ID %s", tostring(materialId))
    end
    return string.format("%s (ID %s)", materialName, tostring(materialId))
end
