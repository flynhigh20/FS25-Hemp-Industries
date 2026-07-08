# Green Horizon Industries - Hemp Greenhouse Blender Generator
# Run in Blender with:
# blender --background --python tools/blender/create_green_horizon_greenhouse.py
#
# This is an original model concept generator. It creates a better greenhouse
# direction than the temporary Phase 2 XML placeholder. Export to i3d later with
# the GIANTS Blender Exporter after scale, collision, and triggers are finalized.

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector

OUTPUT_DIR = Path("assets/blender")
OUTPUT_FILE = OUTPUT_DIR / "green_horizon_hemp_greenhouse.blend"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def make_mat(name: str, color, roughness: float = 0.55, metallic: float = 0.0, alpha: float = 1.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Alpha"].default_value = alpha
    if alpha < 1.0:
        mat.blend_method = "BLEND"
        mat.show_transparent_back = True
    return mat


MAT_GLASS = make_mat("smoky_green_polycarbonate_panels", (0.55, 0.85, 0.70, 0.35), 0.18, 0.0, 0.35)
MAT_FRAME = make_mat("black_powder_coated_frame", (0.035, 0.04, 0.035, 1.0), 0.35, 0.25)
MAT_CONCRETE = make_mat("concrete_foundation", (0.42, 0.42, 0.38, 1.0), 0.85, 0.0)
MAT_SOIL = make_mat("dark_grow_bed_soil", (0.08, 0.05, 0.03, 1.0), 0.9, 0.0)
MAT_PLANT = make_mat("industrial_hemp_green", (0.10, 0.42, 0.15, 1.0), 0.6, 0.0)
MAT_WATER = make_mat("blue_water_tank", (0.04, 0.20, 0.55, 1.0), 0.35, 0.0)
MAT_SIGN = make_mat("green_horizon_sign", (0.02, 0.20, 0.10, 1.0), 0.45, 0.0)
MAT_TEXT = make_mat("warm_sign_lettering", (0.92, 0.95, 0.72, 1.0), 0.35, 0.0)
MAT_LIGHT = make_mat("warm_grow_light_strip", (1.0, 0.70, 0.22, 1.0), 0.25, 0.0)


def cube(name: str, loc, scale, mat=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if mat:
        obj.data.materials.append(mat)
    return obj


def cylinder(name: str, loc, radius: float, depth: float, mat=None, vertices: int = 32, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    if mat:
        obj.data.materials.append(mat)
    return obj


def add_label(name: str, text: str, loc, size: float):
    bpy.ops.object.text_add(location=loc, rotation=(math.radians(90), 0, 0))
    obj = bpy.context.object
    obj.name = name
    obj.data.body = text
    obj.data.align_x = "CENTER"
    obj.data.align_y = "CENTER"
    obj.data.size = size
    obj.data.extrude = 0.015
    obj.data.materials.append(MAT_TEXT)
    return obj


def add_arch_rib(name: str, x: float, radius: float = 2.55, z_base: float = 1.15, width: float = 0.075):
    points = []
    for i in range(17):
        t = math.pi * i / 16
        y = math.cos(t) * radius
        z = z_base + math.sin(t) * 1.65
        points.append(Vector((x, y, z)))

    for idx, (a, b) in enumerate(zip(points, points[1:])):
        mid = (a + b) * 0.5
        length = (b - a).length
        angle = math.atan2((b - a).z, (b - a).y)
        bar = cube(f"{name}_segment_{idx:02d}", mid, (width, length, width), MAT_FRAME)
        bar.rotation_euler[0] = -angle


def add_leaf(name: str, loc, angle: float, scale: float = 1.0):
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=loc, rotation=(math.radians(65), 0, angle))
    obj = bpy.context.object
    obj.name = name
    obj.scale = (0.10 * scale, 0.32 * scale, 1.0)
    obj.data.materials.append(MAT_PLANT)
    return obj


def add_hemp_plant(x: float, y: float):
    cylinder("hemp_stem", (x, y, 0.78), 0.018, 0.62, MAT_PLANT, vertices=8)
    for i in range(6):
        a = math.radians(i * 60)
        add_leaf("simple_original_hemp_leaf", (x + math.cos(a) * 0.06, y + math.sin(a) * 0.06, 1.03), a, 0.75)


def build_model() -> None:
    clear_scene()

    # Foundation and curbs
    cube("concrete_slab", (0, 0, 0.05), (8.8, 5.6, 0.1), MAT_CONCRETE)
    cube("front_curb", (0, -2.78, 0.28), (8.8, 0.18, 0.36), MAT_CONCRETE)
    cube("rear_curb", (0, 2.78, 0.28), (8.8, 0.18, 0.36), MAT_CONCRETE)
    cube("left_curb", (-4.38, 0, 0.28), (0.18, 5.6, 0.36), MAT_CONCRETE)
    cube("right_curb", (4.38, 0, 0.28), (0.18, 5.6, 0.36), MAT_CONCRETE)

    # Glass shell
    cube("left_wall_glass", (0, -2.55, 1.55), (8.2, 0.06, 2.5), MAT_GLASS)
    cube("right_wall_glass", (0, 2.55, 1.55), (8.2, 0.06, 2.5), MAT_GLASS)
    cube("rear_wall_glass", (-4.1, 0, 1.55), (0.06, 5.0, 2.5), MAT_GLASS)
    cube("front_wall_glass", (4.1, 0, 1.55), (0.06, 5.0, 2.5), MAT_GLASS)
    cube("curved_roof_panel", (0, 0, 3.0), (8.2, 5.0, 0.08), MAT_GLASS)

    # Frame ribs and rails
    for x in [-4, -2.7, -1.35, 0, 1.35, 2.7, 4]:
        add_arch_rib("arched_steel_roof_rib", x)
        cube("vertical_wall_post_left", (x, -2.55, 1.45), (0.08, 0.08, 2.2), MAT_FRAME)
        cube("vertical_wall_post_right", (x, 2.55, 1.45), (0.08, 0.08, 2.2), MAT_FRAME)

    for y in [-2.55, 2.55]:
        cube("lower_side_rail", (0, y, 0.72), (8.3, 0.08, 0.08), MAT_FRAME)
        cube("upper_side_rail", (0, y, 2.55), (8.3, 0.08, 0.08), MAT_FRAME)

    # Front double doors
    cube("front_door_left_frame", (4.18, -0.45, 1.25), (0.08, 0.08, 1.85), MAT_FRAME)
    cube("front_door_right_frame", (4.18, 0.45, 1.25), (0.08, 0.08, 1.85), MAT_FRAME)
    cube("front_door_top_frame", (4.18, 0, 2.18), (0.08, 1.05, 0.08), MAT_FRAME)
    cube("front_door_glass_left", (4.2, -0.25, 1.25), (0.04, 0.42, 1.65), MAT_GLASS)
    cube("front_door_glass_right", (4.2, 0.25, 1.25), (0.04, 0.42, 1.65), MAT_GLASS)

    # Grow beds and plants
    for y in [-1.45, 0, 1.45]:
        cube("raised_hemp_grow_bed", (0, y, 0.45), (6.8, 0.72, 0.32), MAT_FRAME)
        cube("soil_surface", (0, y, 0.64), (6.55, 0.55, 0.06), MAT_SOIL)
        for x in [-2.8, -2.0, -1.2, -0.4, 0.4, 1.2, 2.0, 2.8]:
            add_hemp_plant(x, y)

    # Utility details
    cylinder("water_storage_tank", (-3.35, 2.05, 1.05), 0.42, 1.55, MAT_WATER, vertices=48)
    cylinder("water_tank_cap", (-3.35, 2.05, 1.86), 0.28, 0.08, MAT_FRAME, vertices=32)
    cube("nutrient_control_box", (-3.2, -2.35, 1.15), (0.62, 0.12, 0.82), MAT_FRAME)
    cube("grow_light_strip_1", (0, -1.45, 2.72), (6.8, 0.08, 0.06), MAT_LIGHT)
    cube("grow_light_strip_2", (0, 0, 2.72), (6.8, 0.08, 0.06), MAT_LIGHT)
    cube("grow_light_strip_3", (0, 1.45, 2.72), (6.8, 0.08, 0.06), MAT_LIGHT)

    # Branding sign
    cube("front_brand_sign_panel", (4.25, 0, 2.55), (0.08, 2.2, 0.46), MAT_SIGN)
    add_label("front_brand_sign_text", "GREEN HORIZON", (4.32, 0, 2.58), 0.24)
    add_label("front_brand_sub_text", "INDUSTRIAL HEMP", (4.33, 0, 2.35), 0.13)

    # Lighting and camera
    bpy.ops.object.light_add(type="AREA", location=(0, -7, 6))
    light = bpy.context.object
    light.name = "large_softbox_preview_light"
    light.data.energy = 550
    light.data.size = 5

    bpy.ops.object.camera_add(location=(8, -8, 5.2), rotation=(math.radians(62), 0, math.radians(44)))
    bpy.context.scene.camera = bpy.context.object

    bpy.context.scene.render.engine = "CYCLES"
    bpy.context.scene.unit_settings.system = "METRIC"

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_FILE))
    print(f"Saved {OUTPUT_FILE}")


if __name__ == "__main__":
    build_model()
