# Green Horizon Industries - Hemp Greenhouse Blender Generator
# Run in Blender with:
# blender --background --python tools/blender/create_green_horizon_greenhouse.py
#
# This is an original model concept generator. It creates a better greenhouse
# direction than the temporary Phase 2 XML placeholder. Export to i3d later with
# the GIANTS Blender Exporter after scale, collision, and triggers are finalized.
#
# Phase 2 asset pass: procedural Blender materials/textures are generated here
# so the model is not a plain gray block while we are still before final DDS work.

from __future__ import annotations

import math
import random
from pathlib import Path

import bpy
from mathutils import Vector

OUTPUT_DIR = Path("assets/blender")
OUTPUT_FILE = OUTPUT_DIR / "green_horizon_hemp_greenhouse.blend"

random.seed(42025)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def get_bsdf(mat):
    if not mat.use_nodes:
        mat.use_nodes = True
    return mat.node_tree.nodes.get("Principled BSDF")


def set_input(node, names, value) -> None:
    """Set a node input safely across Blender versions."""
    if isinstance(names, str):
        names = [names]
    for name in names:
        if node and name in node.inputs:
            node.inputs[name].default_value = value
            return


def make_mat(name: str, color, roughness: float = 0.55, metallic: float = 0.0, alpha: float = 1.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = get_bsdf(mat)
    set_input(bsdf, "Base Color", color)
    set_input(bsdf, "Roughness", roughness)
    set_input(bsdf, "Metallic", metallic)
    set_input(bsdf, "Alpha", alpha)
    if alpha < 1.0:
        mat.blend_method = "BLEND"
        mat.show_transparent_back = True
        mat.use_screen_refraction = True
    return mat


def add_noise_color(mat, color_a, color_b, scale=22, detail=7, roughness=0.55):
    """Add procedural color variation to a material."""
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = get_bsdf(mat)
    if bsdf is None:
        return mat

    noise = nodes.new(type="ShaderNodeTexNoise")
    noise.name = f"{mat.name}_noise_color"
    set_input(noise, "Scale", scale)
    set_input(noise, "Detail", detail)
    set_input(noise, "Roughness", roughness)

    ramp = nodes.new(type="ShaderNodeValToRGB")
    ramp.name = f"{mat.name}_color_ramp"
    ramp.color_ramp.elements[0].position = 0.18
    ramp.color_ramp.elements[0].color = color_a
    ramp.color_ramp.elements[1].position = 1.0
    ramp.color_ramp.elements[1].color = color_b

    links.new(noise.outputs.get("Fac"), ramp.inputs.get("Fac"))
    links.new(ramp.outputs.get("Color"), bsdf.inputs.get("Base Color"))
    return mat


def add_bump(mat, strength=0.05, distance=0.08, scale=40, detail=8):
    """Add procedural surface roughness/bump."""
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = get_bsdf(mat)
    if bsdf is None or "Normal" not in bsdf.inputs:
        return mat

    noise = nodes.new(type="ShaderNodeTexNoise")
    noise.name = f"{mat.name}_bump_noise"
    set_input(noise, "Scale", scale)
    set_input(noise, "Detail", detail)

    bump = nodes.new(type="ShaderNodeBump")
    bump.name = f"{mat.name}_bump"
    set_input(bump, "Strength", strength)
    set_input(bump, "Distance", distance)

    links.new(noise.outputs.get("Fac"), bump.inputs.get("Height"))
    links.new(bump.outputs.get("Normal"), bsdf.inputs.get("Normal"))
    return mat


def make_emission_mat(name: str, color, strength: float = 1.2):
    mat = make_mat(name, color, roughness=0.25, metallic=0.0)
    bsdf = get_bsdf(mat)
    if bsdf is not None:
        set_input(bsdf, ["Emission Color", "Emission"], color)
        set_input(bsdf, "Emission Strength", strength)
    return mat


# Procedural texture/material set.
MAT_GLASS = make_mat("smoky_green_polycarbonate_panels_subtle_noise", (0.55, 0.85, 0.70, 0.35), 0.12, 0.0, 0.35)
add_noise_color(MAT_GLASS, (0.45, 0.76, 0.62, 0.35), (0.78, 0.98, 0.86, 0.35), scale=9, detail=4)

MAT_FRAME = make_mat("black_powder_coated_frame_satin_texture", (0.035, 0.04, 0.035, 1.0), 0.42, 0.35)
add_noise_color(MAT_FRAME, (0.015, 0.017, 0.014, 1.0), (0.09, 0.095, 0.085, 1.0), scale=35, detail=8)
add_bump(MAT_FRAME, strength=0.018, distance=0.045, scale=85, detail=8)

MAT_CONCRETE = make_mat("poured_concrete_foundation_mottled", (0.42, 0.42, 0.38, 1.0), 0.88, 0.0)
add_noise_color(MAT_CONCRETE, (0.31, 0.31, 0.28, 1.0), (0.60, 0.59, 0.53, 1.0), scale=18, detail=10)
add_bump(MAT_CONCRETE, strength=0.09, distance=0.11, scale=55, detail=9)

MAT_SOIL = make_mat("dark_chunky_grow_bed_soil", (0.08, 0.05, 0.03, 1.0), 0.96, 0.0)
add_noise_color(MAT_SOIL, (0.035, 0.022, 0.012, 1.0), (0.18, 0.105, 0.055, 1.0), scale=55, detail=12)
add_bump(MAT_SOIL, strength=0.16, distance=0.13, scale=95, detail=12)

MAT_PLANT = make_mat("industrial_hemp_leaf_variation", (0.10, 0.42, 0.15, 1.0), 0.64, 0.0)
add_noise_color(MAT_PLANT, (0.055, 0.25, 0.075, 1.0), (0.22, 0.58, 0.18, 1.0), scale=18, detail=5)

MAT_STEM = make_mat("industrial_hemp_stem_fiber", (0.15, 0.35, 0.12, 1.0), 0.72, 0.0)
add_noise_color(MAT_STEM, (0.08, 0.20, 0.065, 1.0), (0.28, 0.42, 0.16, 1.0), scale=28, detail=7)
add_bump(MAT_STEM, strength=0.06, distance=0.05, scale=60, detail=8)

MAT_WATER = make_mat("blue_poly_water_tank_scuffed", (0.04, 0.20, 0.55, 1.0), 0.38, 0.0)
add_noise_color(MAT_WATER, (0.02, 0.12, 0.38, 1.0), (0.08, 0.32, 0.70, 1.0), scale=12, detail=5)
add_bump(MAT_WATER, strength=0.025, distance=0.04, scale=35, detail=6)

MAT_SIGN = make_mat("green_horizon_sign_painted_panel", (0.02, 0.20, 0.10, 1.0), 0.50, 0.0)
add_noise_color(MAT_SIGN, (0.012, 0.12, 0.055, 1.0), (0.055, 0.32, 0.13, 1.0), scale=16, detail=5)
add_bump(MAT_SIGN, strength=0.025, distance=0.035, scale=38, detail=6)

MAT_TEXT = make_mat("warm_sign_lettering_slightly_raised", (0.92, 0.95, 0.72, 1.0), 0.35, 0.0)
MAT_LIGHT = make_emission_mat("warm_amber_grow_light_strip_emissive", (1.0, 0.70, 0.22, 1.0), strength=1.8)
MAT_RUBBER = make_mat("black_rubber_door_gasket", (0.008, 0.008, 0.007, 1.0), 0.72, 0.0)
add_bump(MAT_RUBBER, strength=0.035, distance=0.03, scale=70, detail=6)


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
    try:
        bpy.ops.object.shade_smooth()
    except Exception:
        pass
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


def add_panel_seams(prefix: str, x: float | None = None, y: float | None = None):
    """Add thin black greenhouse panel seam strips."""
    if y is not None:
        for x_pos in [-3.0, -1.5, 0, 1.5, 3.0]:
            cube(f"{prefix}_vertical_seam_{x_pos}", (x_pos, y, 1.65), (0.035, 0.035, 2.35), MAT_RUBBER)
        for z_pos in [1.05, 1.85, 2.55]:
            cube(f"{prefix}_horizontal_seam_{z_pos}", (0, y, z_pos), (8.1, 0.035, 0.035), MAT_RUBBER)
    if x is not None:
        for y_pos in [-1.8, -0.9, 0, 0.9, 1.8]:
            cube(f"{prefix}_end_vertical_seam_{y_pos}", (x, y_pos, 1.65), (0.035, 0.035, 2.35), MAT_RUBBER)
        for z_pos in [1.05, 1.85, 2.55]:
            cube(f"{prefix}_end_horizontal_seam_{z_pos}", (x, 0, z_pos), (0.035, 4.9, 0.035), MAT_RUBBER)


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
        bar = cube(f"{name}_{x}_segment_{idx:02d}", mid, (width, length, width), MAT_FRAME)
        bar.rotation_euler[0] = -angle


def add_leaf(name: str, loc, angle: float, scale: float = 1.0):
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=loc, rotation=(math.radians(65), 0, angle))
    obj = bpy.context.object
    obj.name = name
    obj.scale = (0.10 * scale, 0.32 * scale, 1.0)
    obj.data.materials.append(MAT_PLANT)
    return obj


def add_hemp_plant(x: float, y: float):
    cylinder("hemp_fiber_stem", (x, y, 0.78), 0.018, 0.62, MAT_STEM, vertices=8)
    for i in range(6):
        a = math.radians(i * 60)
        leaf_scale = random.uniform(0.65, 0.86)
        add_leaf("simple_original_hemp_leaf", (x + math.cos(a) * 0.06, y + math.sin(a) * 0.06, 1.03), a, leaf_scale)


def build_model() -> None:
    clear_scene()

    # Foundation and curbs
    cube("concrete_slab_textured", (0, 0, 0.05), (8.8, 5.6, 0.1), MAT_CONCRETE)
    cube("front_curb_textured", (0, -2.78, 0.28), (8.8, 0.18, 0.36), MAT_CONCRETE)
    cube("rear_curb_textured", (0, 2.78, 0.28), (8.8, 0.18, 0.36), MAT_CONCRETE)
    cube("left_curb_textured", (-4.38, 0, 0.28), (0.18, 5.6, 0.36), MAT_CONCRETE)
    cube("right_curb_textured", (4.38, 0, 0.28), (0.18, 5.6, 0.36), MAT_CONCRETE)

    # Glass shell
    cube("left_wall_polycarbonate_panels", (0, -2.55, 1.55), (8.2, 0.06, 2.5), MAT_GLASS)
    cube("right_wall_polycarbonate_panels", (0, 2.55, 1.55), (8.2, 0.06, 2.5), MAT_GLASS)
    cube("rear_wall_polycarbonate_panels", (-4.1, 0, 1.55), (0.06, 5.0, 2.5), MAT_GLASS)
    cube("front_wall_polycarbonate_panels", (4.1, 0, 1.55), (0.06, 5.0, 2.5), MAT_GLASS)
    cube("roof_polycarbonate_panel", (0, 0, 3.0), (8.2, 5.0, 0.08), MAT_GLASS)

    # Panel seams make the procedural material read like real greenhouse panels.
    add_panel_seams("left_wall", y=-2.59)
    add_panel_seams("right_wall", y=2.59)
    add_panel_seams("front_wall", x=4.14)
    add_panel_seams("rear_wall", x=-4.14)

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
    cube("front_door_center_rubber_gasket", (4.235, 0, 1.25), (0.045, 0.035, 1.65), MAT_RUBBER)
    cube("front_door_glass_left", (4.2, -0.25, 1.25), (0.04, 0.42, 1.65), MAT_GLASS)
    cube("front_door_glass_right", (4.2, 0.25, 1.25), (0.04, 0.42, 1.65), MAT_GLASS)

    # Grow beds and plants
    for y in [-1.45, 0, 1.45]:
        cube("raised_hemp_grow_bed_powder_frame", (0, y, 0.45), (6.8, 0.72, 0.32), MAT_FRAME)
        cube("soil_surface_chunky_texture", (0, y, 0.64), (6.55, 0.55, 0.06), MAT_SOIL)
        for x in [-2.8, -2.0, -1.2, -0.4, 0.4, 1.2, 2.0, 2.8]:
            add_hemp_plant(x, y)

    # Utility details
    cylinder("blue_water_storage_tank_scuffed", (-3.35, 2.05, 1.05), 0.42, 1.55, MAT_WATER, vertices=48)
    cylinder("water_tank_cap_black", (-3.35, 2.05, 1.86), 0.28, 0.08, MAT_FRAME, vertices=32)
    cube("nutrient_control_box_satin_black", (-3.2, -2.35, 1.15), (0.62, 0.12, 0.82), MAT_FRAME)
    cube("grow_light_strip_1_emissive", (0, -1.45, 2.72), (6.8, 0.08, 0.06), MAT_LIGHT)
    cube("grow_light_strip_2_emissive", (0, 0, 2.72), (6.8, 0.08, 0.06), MAT_LIGHT)
    cube("grow_light_strip_3_emissive", (0, 1.45, 2.72), (6.8, 0.08, 0.06), MAT_LIGHT)

    # Branding sign
    cube("front_brand_sign_painted_panel", (4.25, 0, 2.55), (0.08, 2.2, 0.46), MAT_SIGN)
    add_label("front_brand_sign_text", "GREEN HORIZON", (4.32, 0, 2.58), 0.24)
    add_label("front_brand_sub_text", "INDUSTRIAL HEMP", (4.33, 0, 2.35), 0.13)

    # Lighting and camera
    bpy.ops.object.light_add(type="AREA", location=(0, -7, 6))
    light = bpy.context.object
    light.name = "large_softbox_preview_light"
    light.data.energy = 650
    light.data.size = 5

    bpy.ops.object.camera_add(location=(8, -8, 5.2), rotation=(math.radians(62), 0, math.radians(44)))
    bpy.context.scene.camera = bpy.context.object

    try:
        bpy.context.scene.render.engine = "CYCLES"
    except Exception:
        pass
    bpy.context.scene.unit_settings.system = "METRIC"

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_FILE))
    print(f"Saved textured greenhouse model: {OUTPUT_FILE}")


if __name__ == "__main__":
    build_model()
