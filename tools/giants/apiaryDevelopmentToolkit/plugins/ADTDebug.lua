-- Author:OpenAI + flynhigh20
-- Name:ADT Debug Plugin
-- Namespace: global
-- Description:Hidden plugin module for Apiary Development Toolkit.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTDebug = {}
local ADTDebug_mt = Class(ADTDebug)

function ADTDebug.new(toolkit)
    local self = setmetatable({}, ADTDebug_mt)
    self.toolkit = toolkit
    self.tabName = "Debug"
    return self
end

function ADTDebug:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
    local sizer = UIRowLayoutSizer.new()
    fold:addPanel("Selection", sizer)
    UIButton.new(sizer, "Print selected node details", function() self:printSelection() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(sizer, "Print selected hierarchy", function() self:printHierarchy() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(sizer, "Print recursive shape summary", function() self:printShapeSummary() end,
        nil, -1, -1, -1, 28)
end

function ADTDebug:printSelection()
    for i=0, getNumSelected()-1 do
        local node = getSelection(i)
        local x, y, z = getWorldTranslation(node)
        local materialCount = 0
        if self.toolkit:isShape(node) then
            materialCount = getNumOfMaterials(node)
        end
        print(string.format("ADT DEBUG node=%s id=%s type=%s parent=%s world=(%.3f, %.3f, %.3f) children=%d materials=%d",
            getName(node), tostring(node), self.toolkit:getNodeTypeLabel(node), tostring(getParent(node)),
            x, y, z, getNumOfChildren(node), materialCount))
    end
    self.toolkit:setStatus("Selection details printed to console/log.")
end

function ADTDebug:printHierarchy()
    local root = self.toolkit:getPrimarySelection() or getRootNode()
    local function visit(node, depth)
        print(string.rep("  ", depth) .. string.format("%s [%s] {%s}",
            getName(node), tostring(node), self.toolkit:getNodeTypeLabel(node)))
        for i=0, getNumOfChildren(node)-1 do
            visit(getChildAt(node, i), depth+1)
        end
    end
    visit(root, 0)
    self.toolkit:setStatus("Hierarchy printed to console/log.")
end

function ADTDebug:printShapeSummary()
    local shapes = self.toolkit:getSelectedShapes()
    local slots = 0
    for _, shape in ipairs(shapes) do
        local count = getNumOfMaterials(shape)
        slots = slots + count
        print(string.format("ADT SHAPE %s [%s] slots=%d", getName(shape), tostring(shape), count))
    end
    self.toolkit:setStatus(string.format("Recursive selection contains %d shape(s) and %d material slot(s).", #shapes, slots))
end
