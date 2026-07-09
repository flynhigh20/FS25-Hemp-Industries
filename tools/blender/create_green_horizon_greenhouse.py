# Green Horizon Industries - Hemp Greenhouse Blender Generator
# Run in Blender 4.2 LTS with:
# blender --background --python tools/blender/create_green_horizon_greenhouse.py
#
# Safe greenhouse rebuild.
# This creates a Blender concept scene, not final game-ready DDS/i3d assets yet.
#
# Phase 2.6:
# - Starts the greenhouse model over from a clean simple structure.
# - Removes the single curved roof mesh and all solidify/thickness modifiers.
# - Builds the roof from many thin segmented panels so it cannot become one solid slab.
# - Keeps adjustable arched ribs and no top/front signs.

from __future__ import annotations

import math
import random
from pathlib import Path

import bpy
from mathutils import Vector


random.seed(42025)

# Overall greenhouse controls.
GREENHOUSE_LENGTH = 8.4
GREENHOUSE_WIDTH = 5.2
SLAB_LENGTH = 9.0
SLAB_WIDTH = 5.9
WALL_HEIGHT = 2.35
WALL_CENTER_Z = 1.45
EAVE_Z = 2.62
ROOF_RISE = 1.05
ROOF_STEPS = 14

# Roof/rib controls. Tweak these before changing the model functions.
ROOF_HALF_WIDTH = GREENHOUSE_WIDTH / 2.0
ROOF_RIB_WIDTH = 0.075
ROOF_PANEL_THICKNESS = 0.022
ROOF_RIB_X_VALUES = [-4.1, -2.75, -1.38, 0.0, 1.38, 2.75, 4.1]
ROOF_PANEL_X_SPANS = [(-4.1, -2.75), (-2.75, -1.38), (-1.38, 0.0), (0.0, 1.38), (1.38, 2.75), (2.75, 4.1)]
ROOF_LONG_RAIL_T_VALUES = [0.22, 0.50, 0.78]


def find_repo_root() -> Path:
    """Find the project root from this script location, with a safe fallback."""
    try:
        script_path = Path(__file__).resolve()
    except NameError:
        script_path = Path.cwd()

    candidates = [script_path if script_path.is_dir() else script_path.parent]
    candidates.extend(candidates[0].parents)

    for candidate in candidates:
        if (candidate / "FS25_GreenHorizonIndustries").exists() or (candidate / ".git").exists():
            return candidate

    return Path.home() / "Documents" / "GreenHorizonIndustries"


REPO_ROOT = find_repo_root()
OUTPUT_DIR = REPO_ROOT / "assets" / "blender"
OUTPUT_FILE = OUTPUT_DIR / "green_horizon_hemp_greenhouse.blend"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def get_bsdf(mat):
    if not mat.use_nodes:
        mat.use_nodes = True
    return mat.node_tree.nodes.get("Principled BSDF")


def set_input(node, names, value) -> None:
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
        if hasattr(mat, "use_screen_refraction"):
            mat.use_screen_refraction = True
    return mat


def add_noise_color(mat, color_a, color_b, scale=22, detail=7, roughness=0.55):
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


MAT_GLASS = make_mat("clear_smoky_green_polycarbonate", (0.55, 0.85, 0.70, 0.28), 0.14, 0.0, 0.28)
add_noise_color(MAT_GLASS, (0.45, 0.74, 0.62, 0.28), (0.82, 0.98, 0.86, 0.28), scale=9, detail=4)

MAT_FRAME = make_mat("black_powder_coated_steel", (0.035, 0.04, 0.035, 1.0), 0.42, 0.32)
add_noise_color(MAT_FRAME, (0.015, 0.017, 0.014, 1.0), (0.09, 0.095, 0.085, 1.0), scale=35, detail=8)
add_bump(MAT_FRAME, strength=0.018, distance=0.045, scale=85, detail=8)

MAT_CONCRETE = make_mat("poured_concrete_foundation", (0.42, 0.42, 0.38, 1.0), 0.88, 0.0)
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

MAT_LIGHT = make_emission_mat("warm_amber_grow_light_strip", (1.0, 0.70, 0.22, 1.0), strength=1.8)
MAT_RUBBER = make_mat("black_rubber_gasket", (0.008, 0.008, 0.007, 1.0), 0.72, 0.0)


def cube(name: str, loc, scale, mat=None, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.rotation_euler = rotation
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


def roof_points(steps: int = ROOF_STEPS):
    """Roof arch from left wall top to right wall top. It never touches the floor."""
    points = []
    for i in range(steps + 1):
        t = math.pi * i / steps
        y = math.cos(t) * ROOF_HALF_WIDTH
        z = EAVE_Z + math.sin(t) * ROOF_RISE
        points.append(Vector((0.0, y, z)))
    return points


def add_arch_segmented_bar(name: str, x: float, width: float, mat, z_offset: float = 0.0):
    """Build one arched rib or seam out of small straight bars."""
    pts = roof_points()
    for idx, (p, q) in enumerate(zip(pts, pts[1:])):
        a = Vector((x, p.y, p.z + z_offset))
        b = Vector((x, q.y, q.z + z_offset))
        mid = (a + b) * 0.5
        seg_len = (b - a).length
        angle = math.atan2((b - a).z, (b - a).y)
        cube(
            f"{name}_{x:.2f}_{idx:02d}",
            mid,
            (width, seg_len, width),
            mat,
            rotation=(-angle, 0.0, 0.0),
        )


def add_roof_ribs():
    for x in ROOF_RIB_X_VALUES:
        add_arch_segmented_bar("adjustable_arched_roof_rib", x, ROOF_RIB_WIDTH, MAT_FRAME, z_offset=0.0)


def add_segmented_roof_panels():
    """Build roof panels as separate thin transparent pieces, not one solid mesh."""
    pts = roof_points()
    for span_index, (x0, x1) in enumerate(ROOF_PANEL_X_SPANS):
        x_mid = (x0 + x1) * 0.5
        x_len = abs(x1 - x0) - 0.08
        for idx, (p, q) in enumerate(zip(pts, pts[1:])):
            a = Vector((x_mid, p.y, p.z + 0.018))
            b = Vector((x_mid, q.y, q.z + 0.018))
            mid = (a + b) * 0.5
            seg_len = (b - a).length - 0.015
            angle = math.atan2((b - a).z, (b - a).y)
            cube(
                f"roof_panel_segment_{span_index}_{idx:02d}",
                mid,
                (x_len, seg_len, ROOF_PANEL_THICKNESS),
                MAT_GLASS,
                rotation=(-angle, 0.0, 0.0),
            )


def add_roof_long_rails():
    span_length = max(ROOF_RIB_X_VALUES) - min(ROOF_RIB_X_VALUES)
    for t in ROOF_LONG_RAIL_T_VALUES:
        y = math.cos(math.pi * t) * ROOF_HALF_WIDTH
        z = EAVE_Z + math.sin(math.pi * t) * ROOF_RISE + 0.04
        cube(f"roof_longitudinal_black_rail_{t:.2f}", (0, y, z), (span_length, 0.045, 0.045), MAT_RUBBER)


def add_wall_panel_seams(prefix: str, x: float | None = None, y: float | None = None):
    if y is not None:
        for x_pos in [-3.0, -1.5, 0, 1.5, 3.0]:
            cube(f"{prefix}_vertical_seam_{x_pos}", (x_pos, y, WALL_CENTER_Z), (0.035, 0.035, WALL_HEIGHT), MAT_RUBBER)
        for z_pos in [0.95, 1.75, EAVE_Z]:
            cube(f"{prefix}_horizontal_seam_{z_pos}", (0, y, z_pos), (GREENHOUSE_LENGTH, 0.035, 0.035), MAT_RUBBER)
    if x is not None:
        for y_pos in [-1.8, -0.9, 0, 0.9, 1.8]:
            cube(f"{prefix}_end_vertical_seam_{y_pos}", (x, y_pos, WALL_CENTER_Z), (0.035, 0.035, WALL_HEIGHT), MAT_RUBBER)
        for z_pos in [0.95, 1.75, EAVE_Z]:
            cube(f"{prefix}_end_horizontal_seam_{z_pos}", (x, 0, z_pos), (0.035, GREENHOUSE_WIDTH - 0.2, 0.035), MAT_RUBBER)


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
        angle = math.radians(i * 60)
        leaf_scale = random.uniform(0.65, 0.86)
        add_leaf("simple_industrial_hemp_leaf", (x + math.cos(angle) * 0.06, y + math.sin(angle) * 0.06, 1.03), angle, leaf_scale)


def build_foundation_and_shell():
    # Foundation and curbs.
    cube("concrete_slab_textured", (0, 0, 0.05), (SLAB_LENGTH, SLAB_WIDTH, 0.1), MAT_CONCRETE)
    cube("front_curb_textured", (0, -SLAB_WIDTH / 2, 0.28), (SLAB_LENGTH, 0.18, 0.36), MAT_CONCRETE)
    cube("rear_curb_textured", (0, SLAB_WIDTH / 2, 0.28), (SLAB_LENGTH, 0.18, 0.36), MAT_CONCRETE)
    cube("left_curb_textured", (-SLAB_LENGTH / 2, 0, 0.28), (0.18, SLAB_WIDTH, 0.36), MAT_CONCRETE)
    cube("right_curb_textured", (SLAB_LENGTH / 2, 0, 0.28), (0.18, SLAB_WIDTH, 0.36), MAT_CONCRETE)

    # Straight walls.
    cube("left_wall_polycarbonate_panels", (0, -GREENHOUSE_WIDTH / 2, WALL_CENTER_Z), (GREENHOUSE_LENGTH, 0.055, WALL_HEIGHT), MAT_GLASS)
    cube("right_wall_polycarbonate_panels", (0, GREENHOUSE_WIDTH / 2, WALL_CENTER_Z), (GREENHOUSE_LENGTH, 0.055, WALL_HEIGHT), MAT_GLASS)
    cube("rear_wall_polycarbonate_panels", (-GREENHOUSE_LENGTH / 2, 0, WALL_CENTER_Z), (0.055, GREENHOUSE_WIDTH, WALL_HEIGHT), MAT_GLASS)
    cube("front_wall_polycarbonate_panels", (GREENHOUSE_LENGTH / 2, 0, WALL_CENTER_Z), (0.055, GREENHOUSE_WIDTH, WALL_HEIGHT), MAT_GLASS)

    # Wall posts and rails.
    for x in ROOF_RIB_X_VALUES:
        cube("vertical_wall_post_left", (x, -GREENHOUSE_WIDTH / 2, 1.47), (0.08, 0.08, 2.25), MAT_FRAME)
        cube("vertical_wall_post_right", (x, GREENHOUSE_WIDTH / 2, 1.47), (0.08, 0.08, 2.25), MAT_FRAME)

    for y in [-GREENHOUSE_WIDTH / 2, GREENHOUSE_WIDTH / 2]:
        cube("lower_side_rail", (0, y, 0.72), (GREENHOUSE_LENGTH + 0.12, 0.08, 0.08), MAT_FRAME)
        cube("upper_side_rail", (0, y, EAVE_Z), (GREENHOUSE_LENGTH + 0.12, 0.08, 0.08), MAT_FRAME)

    add_wall_panel_seams("left_wall", y=-GREENHOUSE_WIDTH / 2 - 0.035)
    add_wall_panel_seams("right_wall", y=GREENHOUSE_WIDTH / 2 + 0.035)
    add_wall_panel_seams("front_wall", x=GREENHOUSE_LENGTH / 2 + 0.035)
    add_wall_panel_seams("rear_wall", x=-GREENHOUSE_LENGTH / 2 - 0.035)


def build_roof():
    # Order matters: panels first, ribs/rails above them.
    add_segmented_roof_panels()
    add_roof_ribs()
    add_roof_long_rails()


def build_doors_and_details():
    # Front double doors.
    front_x = GREENHOUSE_LENGTH / 2 + 0.08
    cube("front_door_left_frame", (front_x, -0.45, 1.25), (0.08, 0.08, 1.85), MAT_FRAME)
    cube("front_door_right_frame", (front_x, 0.45, 1.25), (0.08, 0.08, 1.85), MAT_FRAME)
    cube("front_door_top_frame", (front_x, 0, 2.18), (0.08, 1.05, 0.08), MAT_FRAME)
    cube("front_door_center_rubber_gasket", (front_x + 0.035, 0, 1.25), (0.045, 0.035, 1.65), MAT_RUBBER)
    cube("front_door_glass_left", (front_x + 0.02, -0.25, 1.25), (0.04, 0.42, 1.65), MAT_GLASS)
    cube("front_door_glass_right", (front_x + 0.02, 0.25, 1.25), (0.04, 0.42, 1.65), MAT_GLASS)

    # Grow beds and plants.
    for y in [-1.45, 0, 1.45]:
        cube("raised_hemp_grow_bed_powder_frame", (0, y, 0.45), (6.8, 0.72, 0.32), MAT_FRAME)
        cube("soil_surface_chunky_texture", (0, y, 0.64), (6.55, 0.55, 0.06), MAT_SOIL)
        for x in [-2.8, -2.0, -1.2, -0.4, 0.4, 1.2, 2.0, 2.8]:
            add_hemp_plant(x, y)

    # Utility details. No roof/front brand signs in this version.
    cylinder("blue_water_storage_tank_scuffed", (-3.35, 2.05, 1.05), 0.42, 1.55, MAT_WATER, vertices=48)
    cylinder("water_tank_cap_black", (-3.35, 2.05, 1.86), 0.28, 0.08, MAT_FRAME, vertices=32)
    cube("nutrient_control_box_satin_black", (-3.2, -2.45, 1.15), (0.62, 0.12, 0.82), MAT_FRAME)
    cube("grow_light_strip_1_emissive", (0, -1.45, 2.46), (6.8, 0.08, 0.06), MAT_LIGHT)
    cube("grow_light_strip_2_emissive", (0, 0, 2.46), (6.8, 0.08, 0.06), MAT_LIGHT)
    cube("grow_light_strip_3_emissive", (0, 1.45, 2.46), (6.8, 0.08, 0.06), MAT_LIGHT)


def add_preview_lighting_and_camera():
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


def build_model() -> None:
    clear_scene()
    build_foundation_and_shell()
    build_roof()
    build_doors_and_details()
    add_preview_lighting_and_camera()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_FILE))
    print(f"Saved safe rebuilt greenhouse model: {OUTPUT_FILE}")


if __name__ == "__main__":
    build_model()
