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

    -- The first collected index is the loaded I3D root's position beneath the
    -- GIANTS Editor scene root. It must not appear in an XML i3dMapping path.
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
end

if ADTEffectInspector ~= nil then
    ADTEffectInspector.getNodePath = getI3DRelativeNodePath
end
