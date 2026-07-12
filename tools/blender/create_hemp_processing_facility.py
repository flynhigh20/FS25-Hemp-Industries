import bpy
import math
from pathlib import Path


# Blender's Text Editor may expose __file__ as only ``\script.py``. Use the
# canonical desktop Git checkout so running the text block always saves into
# the active repository instead of depending on Blender's temporary path.
ROOT = Path(r"C:\Users\user\Desktop\FS25-Hemp-Industries-main")
OUTPUT = ROOT / "assets" / "blender" / "green_horizon_hemp_processing_facility.blend"


def material(name, color, metallic=0.0, roughness=0.55):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def box(name, location, scale, mat, parent=None, bevel=0.04):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (scale[0] / 2, scale[1] / 2, scale[2] / 2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("edgeSoftening", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    obj.data.materials.append(mat)
    obj.parent = parent
    return obj


def empty(name, location, parent, display="CUBE", size=0.5):
    obj = bpy.data.objects.new(name, None)
    obj.empty_display_type = display
    obj.empty_display_size = size
    obj.location = location
    obj.parent = parent
    bpy.context.collection.objects.link(obj)
    return obj


def beam_between(name, a, b, width, mat, parent):
    ax, ay, az = a
    bx, by, bz = b
    dx, dy, dz = bx - ax, by - ay, bz - az
    length = math.sqrt(dx * dx + dy * dy + dz * dz)
    obj = box(name, ((ax + bx) / 2, (ay + by) / 2, (az + bz) / 2),
              (width, width, length), mat, parent, bevel=0.025)
    direction = mathutils.Vector((dx, dy, dz))
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    return obj


import mathutils

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials):
    pass

steel = material("GHI_DarkSteel", (0.035, 0.055, 0.06), 0.72, 0.28)
panel = material("GHI_LightMetalPanel", (0.47, 0.54, 0.53), 0.55, 0.38)
roof = material("GHI_RoofMetal", (0.12, 0.18, 0.18), 0.68, 0.3)
concrete = material("GHI_Concrete", (0.29, 0.30, 0.28), 0.0, 0.82)
door_mat = material("GHI_RollupDoor", (0.18, 0.25, 0.24), 0.58, 0.36)
accent = material("GHI_GreenAccent", (0.08, 0.32, 0.18), 0.25, 0.42)
glass = material("GHI_DarkGlass", (0.025, 0.07, 0.075), 0.25, 0.18)
logo_mat = material("GHI_BrandLogo", (0.08, 0.32, 0.18), 0.1, 0.38)
logo_image = bpy.data.images.load(str(ROOT / "FS25_GreenHorizonIndustries" / "branding" / "green_horizon_industries_main_logo.png"))
logo_nodes = logo_mat.node_tree.nodes
logo_links = logo_mat.node_tree.links
logo_texture = logo_nodes.new("ShaderNodeTexImage")
logo_texture.name = "GreenHorizonLogo"
logo_texture.image = logo_image
logo_links.new(logo_texture.outputs["Color"], logo_nodes["Principled BSDF"].inputs["Base Color"])

root = empty("greenHorizonHempProcessingFacility", (0, 0, 0), None, "PLAIN_AXES", 1.0)
visuals = empty("visuals", (0, 0, 0), root, "PLAIN_AXES", 0.5)
collisions = empty("collisions", (0, 0, 0), root, "PLAIN_AXES", 0.5)
game_nodes = empty("facilityGameNodes", (0, 0, 0), root, "PLAIN_AXES", 0.5)

# 12 m x 8 m compact industrial bungalow.
box("concreteSlab", (0, 0, 0.12), (13.2, 9.2, 0.24), concrete, visuals, 0.08)
box("loadingApron", (0, -6.0, 0.10), (7.4, 3.0, 0.20), concrete, visuals, 0.06)

# Wall panels leave openings for a 4.4 m roll-up door and personnel door.
box("rearWall", (0, 4.0, 2.0), (12.0, 0.16, 4.0), panel, visuals)
box("leftWall", (-6.0, 0, 2.0), (0.16, 8.0, 4.0), panel, visuals)
box("rightWall", (6.0, 0, 2.0), (0.16, 8.0, 4.0), panel, visuals)
box("frontWallLeft", (-4.7, -4.0, 2.0), (2.6, 0.16, 4.0), panel, visuals)
box("frontWallCenter", (0.9, -4.0, 3.65), (4.4, 0.16, 0.70), panel, visuals)
box("frontWallRight", (4.55, -4.0, 2.0), (2.9, 0.16, 4.0), panel, visuals)

# Visible steel frame.
for x in (-6.05, 0.0, 6.05):
    for y in (-4.05, 4.05):
        box(f"framePost_{x}_{y}", (x, y, 2.1), (0.18, 0.18, 4.2), steel, visuals, 0.025)
for y in (-4.05, 4.05):
    box(f"eaveBeam_{y}", (0, y, 4.05), (12.2, 0.18, 0.18), steel, visuals, 0.025)
for x in (-6.05, 0.0, 6.05):
    beam_between(f"rafterLeft_{x}", (x, -4.05, 4.05), (x, 0, 5.15), 0.16, steel, visuals)
    beam_between(f"rafterRight_{x}", (x, 0, 5.15), (x, 4.05, 4.05), 0.16, steel, visuals)
box("ridgeBeam", (0, 0, 5.15), (12.2, 0.16, 0.16), steel, visuals, 0.025)

# Two continuous shallow roof sheets.
roof_left = box("roofSheetFront", (0, -2.03, 4.59), (12.55, 4.35, 0.12), roof, visuals, 0.025)
roof_left.rotation_euler[0] = math.radians(15.2)
roof_right = box("roofSheetRear", (0, 2.03, 4.59), (12.55, 4.35, 0.12), roof, visuals, 0.025)
roof_right.rotation_euler[0] = math.radians(-15.2)

# Doors, simple signage, and sheltered loading detail.
box("rollupDoor", (0.9, -4.11, 1.75), (4.35, 0.12, 3.45), door_mat, visuals, 0.035)
for z in (0.55, 1.1, 1.65, 2.2, 2.75, 3.3):
    box(f"rollupRib_{z}", (0.9, -4.19, z), (4.2, 0.04, 0.055), steel, visuals, 0.01)
box("personnelDoor", (4.45, -4.12, 1.15), (1.25, 0.12, 2.3), steel, visuals, 0.03)
box("personnelDoorWindow", (4.45, -4.20, 1.55), (0.72, 0.035, 0.62), glass, visuals, 0.015)
box("brandSignBacking", (-4.65, -4.16, 2.55), (1.65, 0.08, 1.65), accent, visuals, 0.04)
bpy.ops.mesh.primitive_plane_add(
    size=2.0,
    location=(-4.65, -4.215, 2.55),
    rotation=(math.radians(90), 0.0, 0.0),
)
brand_logo = bpy.context.object
brand_logo.name = "brandSignLogo"
brand_logo.scale = (0.75, 0.75, 0.75)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
brand_logo.data.materials.append(logo_mat)
brand_logo.parent = visuals

# Minimal process decoration: outdoor buffer tank and transfer pipe.
bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.82, depth=2.35, location=(6.95, 1.8, 1.28))
tank = bpy.context.object
tank.name = "bufferTank"
tank.data.materials.append(panel)
tank.parent = visuals
for z in (0.35, 2.2):
    bpy.ops.mesh.primitive_torus_add(major_radius=0.84, minor_radius=0.045, location=(6.95, 1.8, z))
    band = bpy.context.object
    band.name = f"tankBand_{z}"
    band.data.materials.append(steel)
    band.parent = visuals
box("transferPipeVertical", (6.95, 0.55, 2.6), (0.13, 0.13, 2.6), steel, visuals, 0.02)
box("transferPipeHorizontal", (6.48, 0.55, 3.85), (1.08, 0.13, 0.13), steel, visuals, 0.02)

# Non-rendered helper meshes, kept spatially separate. Trigger collision flags
# are finalized after I3D export, but these must be real shapes rather than
# empties for FS25 to detect them.
player_trigger = box("playerTrigger", (4.5, -5.0, 1.0), (1.8, 1.8, 2.0), concrete, game_nodes, 0)
player_trigger.hide_render = True
player_trigger.display_type = "WIRE"
empty("playerTriggerMarker", (4.5, -5.0, 0.05), game_nodes, "PLAIN_AXES", 0.25)
unload_trigger = box("unloadTrigger", (-1.0, -6.0, 0.8), (4.5, 3.0, 1.6), concrete, game_nodes, 0)
unload_trigger.hide_render = True
unload_trigger.display_type = "WIRE"
empty("unloadTriggerMarker", (-1.0, -6.0, 0.05), game_nodes, "PLAIN_AXES", 0.25)
empty("palletSpawner", (4.3, 4.8, 0.05), game_nodes, "PLAIN_AXES", 0.3)
empty("palletAreaStart", (2.6, 4.8, 0.05), game_nodes, "PLAIN_AXES", 0.2)
empty("palletAreaEnd", (5.6, 7.0, 0.05), game_nodes, "PLAIN_AXES", 0.2)

# Simple collision boxes are separate and hidden from rendering.
for name, loc, size in (
    ("collisionRear", (0, 4.0, 2.0), (12.0, 0.18, 4.0)),
    ("collisionLeft", (-6.0, 0, 2.0), (0.18, 8.0, 4.0)),
    ("collisionRight", (6.0, 0, 2.0), (0.18, 8.0, 4.0)),
    ("collisionFrontLeft", (-4.7, -4.0, 2.0), (2.6, 0.18, 4.0)),
    ("collisionFrontRight", (4.55, -4.0, 2.0), (2.9, 0.18, 4.0)),
):
    obj = box(name, loc, size, concrete, collisions, 0)
    obj.hide_render = True
    obj.display_type = "WIRE"

bpy.context.scene.render.engine = "BLENDER_EEVEE_NEXT"
bpy.context.scene.unit_settings.system = "METRIC"
bpy.context.scene.unit_settings.scale_length = 1.0
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT))
print(f"Saved Green Horizon processing facility to {OUTPUT}")
