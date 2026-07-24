-- Author:OpenAI + flynhigh20
-- Name:ADT Validate Plugin
-- Namespace: global
-- Description:Hidden plugin module for Apiary Development Toolkit.
-- Icon:
-- Hide: yes
-- AlwaysLoaded: no

ADTValidate = {}
local ADTValidate_mt = Class(ADTValidate)

function ADTValidate.new(toolkit)
    local self = setmetatable({}, ADTValidate_mt)
    self.toolkit = toolkit
    self.tabName = "Validate"
    return self
end

function ADTValidate:createTab(layoutSizer)
    local fold = UIFoldPanel.new(layoutSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
    local sceneSizer = UIRowLayoutSizer.new()
    fold:addPanel("Scene checks", sceneSizer)
    UIButton.new(sceneSizer, "Find duplicate node names", function() self:findDuplicateNames() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(sceneSizer, "Check selected shapes/groups recursively", function() self:checkSelectedMaterials() end,
        nil, -1, -1, -1, 28, BorderDirection.BOTTOM, 5)
    UIButton.new(sceneSizer, "Find particle-named nodes", function() self:findParticleNodes() end,
        nil, -1, -1, -1, 28)
end

function ADTValidate:findDuplicateNames()
    local names = {}
    local duplicates = 0
    I3DUtil.iterateRecursively(getRootNode(), function(node)
        local name = getName(node)
        if not string.isNilOrWhitespace(name) then
            names[name] = names[name] or {}
            table.insert(names[name], node)
        end
    end)

    for name, nodes in pairs(names) do
        if #nodes > 1 then
            duplicates = duplicates + 1
            self.toolkit:logWarning(string.format('Duplicate name "%s" appears %d times.', name, #nodes), nodes[1])
        end
    end
    self.toolkit:setStatus(string.format("Duplicate-name scan complete: %d duplicate name(s).", duplicates))
end

function ADTValidate:checkSelectedMaterials()
    local shapes = self.toolkit:getSelectedShapes()
    if #shapes == 0 then
        self.toolkit:logWarning("The current selection contains no shape nodes.")
        return
    end

    local issues = 0
    local slotsChecked = 0
    for _, shape in ipairs(shapes) do
        local count = getNumOfMaterials(shape)
        if count == 0 then
            issues = issues + 1
            self.toolkit:logWarning("Shape has no material slots: " .. getName(shape), shape)
        else
            for slot=0, count-1 do
                slotsChecked = slotsChecked + 1
                local materialId = getMaterial(shape, slot)
                if materialId == 0 or materialId == nil or not entityExists(materialId) then
                    issues = issues + 1
                    self.toolkit:logError(string.format("Missing material on %s slot %d", getName(shape), slot), shape)
                end
            end
        end
    end
    self.toolkit:setStatus(string.format("Material check: %d shape(s), %d slot(s), %d issue(s).",
        #shapes, slotsChecked, issues))
end

function ADTValidate:findParticleNodes()
    local count = 0
    I3DUtil.iterateRecursively(getRootNode(), function(node)
        local name = string.lower(getName(node) or "")
        if string.find(name, "particle", 1, true) or string.find(name, "bees", 1, true) or string.find(name, "smoke", 1, true) then
            count = count + 1
            self.toolkit:logInfo("Particle-related node: " .. getName(node), node)
        end
    end)
    self.toolkit:setStatus(string.format("Found %d particle-related scene node(s).", count))
end
