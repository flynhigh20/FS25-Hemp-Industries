-- Author:OpenAI + flynhigh20
-- Shared I3D-relative mapping path correction.
-- GIANTS XML paths begin at the loaded I3D root (0>), not at the Editor scene root.

local function getI3DRelativeNodePath(self, node)
    if node == nil or not entityExists(node) then
        return nil
    end

    local indexes = {}
    local current = node

    while current ~= nil and entityExists(current) do
        local parent = getParent(current)
        if parent == nil or parent == 0 then
            break
        end

        local childIndex = nil
        for i=0, getNumOfChildren(parent)-1 do
            if getChildAt(parent, i) == current then
                childIndex = i
                break
            end
        end

        if childIndex == nil then
            return nil
        end

        table.insert(indexes, 1, tostring(childIndex))
        current = parent
    end

    -- The first index is the loaded I3D root's position below the GIANTS
    -- Editor scene root. XML i3dMapping paths must not include that index.
    if #indexes > 0 then
        table.remove(indexes, 1)
    end

    if #indexes == 0 then
        return "0>"
    end

    return "0>" .. table.concat(indexes, "|")
end

if ADTConfigure ~= nil then
    ADTConfigure.getNodePath = getI3DRelativeNodePath

    function ADTConfigure:printMappings()
        local target = self:getTarget()
        if target == nil then
            self.toolkit:logWarning("Capture an active target before printing XML mappings.")
            return
        end

        local nodes = self:collectNamedNodes(target)
        local targetName = getName(target)
        local count = #nodes

        print("ADT XML MAPPINGS BEGIN - " .. targetName)
        print("    <i3dMappings>")

        if targetName ~= nil and targetName ~= "" then
            print(string.format('        <i3dMapping id="%s" node="%s" />',
                targetName, self:getNodePath(target) or "unknown"))
            count = count + 1
        end

        for _, node in ipairs(nodes) do
            local path = self:getNodePath(node)
            if path ~= nil then
                print(string.format('        <i3dMapping id="%s" node="%s" />', getName(node), path))
            end
        end

        print("    </i3dMappings>")
        print("ADT XML MAPPINGS END")

        self.productionLabel:setText(string.format(
            "Printed %d named-node mapping line(s). The captured root is included and paths are I3D-relative.", count))
        self.toolkit:setStatus(string.format("Printed %d XML mappings for %s.", count, targetName))
    end
end

if ADTEffectInspector ~= nil then
    ADTEffectInspector.getNodePath = getI3DRelativeNodePath
end
