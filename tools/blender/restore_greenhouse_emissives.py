from pathlib import Path

import bpy


ROOT = Path(r"C:\Users\user\Desktop\FS25-Hemp-Industries-main")
BLEND_PATH = ROOT / "assets" / "blender" / "green_horizon_hemp_greenhouse.blend"
EXPORT_PATH = ROOT / "assets" / "blender" / "green_horizon_hemp_greenhouse_emissive_test.i3d"


def set_input(node, names, value):
    if isinstance(names, str):
        names = (names,)
    for name in names:
        socket = node.inputs.get(name)
        if socket is not None:
            socket.default_value = value
            return


def emissive_material(name, color, strength):
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    set_input(bsdf, "Base Color", color)
    set_input(bsdf, ("Emission Color", "Emission"), color)
    set_input(bsdf, "Emission Strength", strength)
    set_input(bsdf, "Roughness", 0.28)
    return material


def cube(name, location, scale, material, parent):
    old = bpy.data.objects.get(name)
    if old is not None:
        bpy.data.objects.remove(old, do_unlink=True)
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (scale[0] / 2, scale[1] / 2, scale[2] / 2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    obj.parent = parent
    return obj


root = bpy.data.objects.get("greenHorizonHempGreenhouse")
if root is None:
    raise RuntimeError("greenHorizonHempGreenhouse root is missing")

visuals = bpy.data.objects.get("visuals") or root
green = emissive_material("productionScreenEmissive", (0.04, 0.72, 0.20, 1.0), 2.2)
amber = emissive_material("greenhouseStatusAmberEmissive", (1.0, 0.34, 0.025, 1.0), 1.8)

# Restrained status display on the existing production console; no floodlights.
cube("productionTriggerScreenEmissive", (3.55, -2.555, 1.22), (0.25, 0.018, 0.27), green, visuals)
cube("waterStatusEmissive", (3.47, -2.567, 1.33), (0.045, 0.012, 0.025), amber, visuals)
cube("seedStatusEmissive", (3.55, -2.567, 1.33), (0.045, 0.012, 0.025), amber, visuals)
cube("productionStatusEmissive", (3.63, -2.567, 1.33), (0.045, 0.012, 0.025), green, visuals)

bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))

settings = bpy.context.scene.I3D_UIexportSettings
settings.i3D_exportUseSoftwareFileName = False
settings.i3D_exportFileLocation = str(EXPORT_PATH)
bpy.ops.i3d.panelexport_buttonexport(state=1)
print(f"Saved emissive source: {BLEND_PATH}")
print(f"Exported emissive test: {EXPORT_PATH}")
