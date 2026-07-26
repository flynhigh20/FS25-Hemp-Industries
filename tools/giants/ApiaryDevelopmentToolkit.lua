-- Author:OpenAI + flynhigh20
-- Name:Apiary Development Toolkit
-- Namespace: global
-- Description:GIANTS Editor toolkit for apiary scene construction, materials, particle imports, validation and debugging.
-- Icon:
-- Hide: no
-- AlwaysLoaded: no

source("apiaryDevelopmentToolkit/ApiaryDevelopmentToolkitCore.lua")

if g_apiaryDevelopmentToolkitOpenListener ~= nil then
    removeEventListener(HookType.ON_FILE_OPEN, g_apiaryDevelopmentToolkitOpenListener)
    g_apiaryDevelopmentToolkitOpenListener = nil
end

function openApiaryDevelopmentToolkit()
    if g_apiaryDevelopmentToolkit ~= nil then
        g_apiaryDevelopmentToolkit:close()
        g_apiaryDevelopmentToolkit = nil
    end

    g_apiaryDevelopmentToolkit = ApiaryDevelopmentToolkit.new()
    g_apiaryDevelopmentToolkit:addPlugin("ADTPlace", "apiaryDevelopmentToolkit/plugins/ADTPlace.lua")
    g_apiaryDevelopmentToolkit:addPlugin("ADTConfigure", "apiaryDevelopmentToolkit/plugins/ADTConfigure.lua")
    g_apiaryDevelopmentToolkit:addPlugin("ADTPlaceableSupport", "apiaryDevelopmentToolkit/plugins/ADTPlaceableSupport.lua")
    g_apiaryDevelopmentToolkit:addPlugin("ADTEffectInspector", "apiaryDevelopmentToolkit/plugins/ADTEffectInspector.lua")
    source("apiaryDevelopmentToolkit/ADTMappingPathFix.lua")
    g_apiaryDevelopmentToolkit:addPlugin("ADTParticleReadiness", "apiaryDevelopmentToolkit/plugins/ADTParticleReadiness.lua")
    g_apiaryDevelopmentToolkit:addPlugin("ADTMappingTools", "apiaryDevelopmentToolkit/plugins/ADTMappingTools.lua")
    g_apiaryDevelopmentToolkit:addPlugin("ADTMaterials", "apiaryDevelopmentToolkit/plugins/ADTMaterials.lua")
    g_apiaryDevelopmentToolkit:addPlugin("ADTParticles", "apiaryDevelopmentToolkit/plugins/ADTParticles.lua")
    g_apiaryDevelopmentToolkit:addPlugin("ADTValidate", "apiaryDevelopmentToolkit/plugins/ADTValidate.lua")
    g_apiaryDevelopmentToolkit:addPlugin("ADTDebug", "apiaryDevelopmentToolkit/plugins/ADTDebug.lua")
    g_apiaryDevelopmentToolkit:show()
end

openApiaryDevelopmentToolkit()
g_apiaryDevelopmentToolkitOpenListener = addEventListener(HookType.ON_FILE_OPEN, openApiaryDevelopmentToolkit)
