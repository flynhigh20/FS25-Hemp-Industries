# Green Horizon Industries - Product Pallet Blender Generator
# Run in Blender with:
# blender --background --python tools/blender/create_green_horizon_pallets.py
#
# Creates original concept pallets for Green Horizon products with readable front
# labels and procedural Blender materials. These are concept/export assets, not
# final game-ready DDS/i3d assets yet.
#
# Phase 2.3:
# - Saves to the repository assets/blender folder instead of Blender's launch folder.
# - Avoids Windows permission errors when Blender is launched from Program Files.
# - Removes top pallet signs/labels because they were too busy and did not look right.

from __future__ import annotations

import math
import random
from pathlib import Path

import bpy


random.seed(2525)


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

    # Fallback avoids trying to write into Blender/Program Files if the script was copied elsewhere.
    return Path.home() / "Documents" / "GreenHorizonIndustries"


REPO_ROOT = find_repo_root()
OUTPUT_DIR = REPO_ROOT / "assets" / "blender"
OUTPUT_FILE = OUTPUT_DIR / "green_horizon_product_pallets.blend"


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
    ramp.name = f"{mat.name}_ramp"
    ramp.color_ramp.elements[0].position = 0.16
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


# Procedural material set. These are Blender procedural materials, not external image textures.
MAT_WOOD = make_mat("rough_reused_pallet_wood", (0.56, 0.39, 0.22, 1.0), 0.86, 0.0)
add_noise_color(MAT_WOOD, (0.32, 0.20, 0.10, 1.0), (0.72, 0.52, 0.30, 1.0), scale=28, detail=10)
add_bump(MAT_WOOD, strength=0.10, distance=0.08, scale=65, detail=10)

MAT_DARK_WOOD = make_mat("dark_end_grain_and_scuffs", (0.23, 0.15, 0.08, 1.0), 0.92, 0.0)
add_noise_color(MAT_DARK_WOOD, (0.12, 0.07, 0.035, 1.0), (0.36, 0.23, 0.11, 1.0), scale=35, detail=10)
add_bump(MAT_DARK_WOOD, strength=0.08, distance=0.06, scale=75, detail=9)

MAT_WRAP = make_mat("slightly_cloudy_clear_pallet_wrap", (0.84, 0.95, 0.92, 0.23), 0.18, 0.0, 0.23)
add_noise_color(MAT_WRAP, (0.55, 0.70, 0.66, 0.20), (0.96, 1.00, 0.98, 0.34), scale=14, detail=5)

MAT_LABEL = make_mat("cream_shipping_label_stock", (0.94, 0.91, 0.78, 1.0), 0.62, 0.0)
add_noise_color(MAT_LABEL, (0.78, 0.73, 0.58, 1.0), (1.0, 0.98, 0.84, 1.0), scale=18, detail=5)

MAT_TEXT_DARK = make_mat("dark_green_printed_label_text", (0.01, 0.10, 0.04, 1.0), 0.52, 0.0)
MAT_BLACK_TEXT = make_mat("black_small_label_text", (0.005, 0.005, 0.004, 1.0), 0.55, 0.0)

MAT_HEMP = make_mat("compressed_industrial_hemp_product", (0.24, 0.46, 0.18, 1.0), 0.74, 0.0)
add_noise_color(MAT_HEMP, (0.13, 0.27, 0.09, 1.0), (0.43, 0.63, 0.23, 1.0), scale=55, detail=12)
add_bump(MAT_HEMP, strength=0.13, distance=0.10, scale=110, detail=12)

MAT_BIOMASS = make_mat("tan_green_hemp_biomass_bale", (0.52, 0.48, 0.28, 1.0), 0.82, 0.0)
add_noise_color(MAT_BIOMASS, (0.30, 0.30, 0.14, 1.0), (0.70, 0.64, 0.35, 1.0), scale=60, detail=12)
add_bump(MAT_BIOMASS, strength=0.14, distance=0.11, scale=115, detail=12)

MAT_SEED_BAG = make_mat("natural_canvas_hemp_seed_bag", (0.70, 0.62, 0.43, 1.0), 0.88, 0.0)
add_noise_color(MAT_SEED_BAG, (0.48, 0.40, 0.25, 1.0), (0.86, 0.78, 0.54, 1.0), scale=42, detail=10)
add_bump(MAT_SEED_BAG, strength=0.09, distance=0.08, scale=90, detail=10)

MAT_STRAP = make_mat("black_plastic_pallet_strap", (0.006, 0.006, 0.005, 1.0), 0.48, 0.0)


def cube(name: str, loc, scale, mat=None, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rot)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if mat:
        obj.data.materials.append(mat)
    return obj


def add_text(name: str, body: str, loc, size: float, mat, rot=(math.radians(90), 0, 0), align="CENTER"):
    bpy.ops.object.text_add(location=loc, rotation=rot)
    obj = bpy.context.object
    obj.name = name
    obj.data.body = body
    obj.data.align_x = align
    obj.data.align_y = "CENTER"
    obj.data.size = size
    obj.data.extrude = 0.006
    obj.data.materials.append(mat)
    return obj


def make_pallet_base(cx: float, cy: float, title: str):
    # Top deck boards.
    for y in [-0.44, -0.22, 0.0, 0.22, 0.44]:
        board = cube(f"{title}_top_deck_board", (cx, cy + y, 0.16), (1.36, 0.13, 0.07), MAT_WOOD)
        board.rotation_euler[2] = random.uniform(-0.01, 0.01)

    # Bottom runners.
    for y in [-0.43, 0.0, 0.43]:
        cube(f"{title}_bottom_runner", (cx, cy + y, 0.035), (1.42, 0.10, 0.07), MAT_DARK_WOOD)

    # Pallet blocks.
    for x in [-0.52, 0.0, 0.52]:
        for y in [-0.43, 0.0, 0.43]:
            cube(f"{title}_pallet_block", (cx + x, cy + y, 0.095), (0.14, 0.14, 0.12), MAT_DARK_WOOD)


def make_front_label(cx: float, cy: float, z: float, product_title: str, product_code: str):
    # Front is negative Y. Text is laid on the vertical front face.
    label_y = cy - 0.615
    cube(f"label_panel_{product_code}", (cx, label_y, z), (0.94, 0.025, 0.38), MAT_LABEL)
    add_text(f"label_brand_{product_code}", "GREEN HORIZON", (cx, label_y - 0.018, z + 0.115), 0.085, MAT_TEXT_DARK)
    add_text(f"label_product_{product_code}", product_title, (cx, label_y - 0.019, z + 0.005), 0.062, MAT_BLACK_TEXT)
    add_text(f"label_code_{product_code}", f"LOT GH-{product_code}  |  FS25", (cx, label_y - 0.020, z - 0.105), 0.035, MAT_BLACK_TEXT)


def add_wrap(cx: float, cy: float, z: float, height: float, product_code: str):
    # Thin transparent shell around the stacked product.
    cube(f"clear_wrap_front_{product_code}", (cx, cy - 0.62, z), (1.18, 0.018, height), MAT_WRAP)
    cube(f"clear_wrap_back_{product_code}", (cx, cy + 0.62, z), (1.18, 0.018, height), MAT_WRAP)
    cube(f"clear_wrap_left_{product_code}", (cx - 0.60, cy, z), (0.018, 1.20, height), MAT_WRAP)
    cube(f"clear_wrap_right_{product_code}", (cx + 0.60, cy, z), (0.018, 1.20, height), MAT_WRAP)


def add_straps(cx: float, cy: float, z: float, height: float, product_code: str):
    # Strap bands on front/back and sides.
    for x in [-0.34, 0.34]:
        cube(f"vertical_strap_front_{product_code}", (cx + x, cy - 0.642, z), (0.055, 0.018, height + 0.05), MAT_STRAP)
        cube(f"vertical_strap_back_{product_code}", (cx + x, cy + 0.642, z), (0.055, 0.018, height + 0.05), MAT_STRAP)
    for z_band in [z - height * 0.25, z + height * 0.22]:
        cube(f"horizontal_strap_front_{product_code}", (cx, cy - 0.648, z_band), (1.18, 0.018, 0.045), MAT_STRAP)
        cube(f"horizontal_strap_back_{product_code}", (cx, cy + 0.648, z_band), (1.18, 0.018, 0.045), MAT_STRAP)


def make_hemp_pallet(cx: float, cy: float):
    code = "HEMP"
    make_pallet_base(cx, cy, code)

    # Stacked compressed hemp boxes/bales.
    for row_z, z in enumerate([0.34, 0.58, 0.82]):
        for x in [-0.32, 0.32]:
            for y in [-0.28, 0.28]:
                cube(f"industrial_hemp_compressed_pack_{row_z}", (cx + x, cy + y, z), (0.56, 0.48, 0.20), MAT_HEMP)

    add_wrap(cx, cy, 0.62, 0.78, code)
    add_straps(cx, cy, 0.62, 0.78, code)
    make_front_label(cx, cy, 0.62, "INDUSTRIAL HEMP", code)


def make_biomass_pallet(cx: float, cy: float):
    code = "BIOMASS"
    make_pallet_base(cx, cy, code)

    # Larger rough bales for by-product material.
    for z in [0.40, 0.72]:
        for y in [-0.30, 0.30]:
            cube(f"hemp_biomass_bale_{z}_{y}", (cx, cy + y, z), (1.08, 0.48, 0.28), MAT_BIOMASS)

    add_wrap(cx, cy, 0.58, 0.82, code)
    add_straps(cx, cy, 0.58, 0.82, code)
    make_front_label(cx, cy, 0.60, "HEMP BIOMASS", code)


def make_seed_input_pallet(cx: float, cy: float):
    # Kept as an input pallet, not a money-crop/sellable concept unless later strains are added.
    code = "SEED"
    make_pallet_base(cx, cy, code)

    bag_positions = [
        (-0.36, -0.30, 0.36), (0.00, -0.30, 0.36), (0.36, -0.30, 0.36),
        (-0.36, 0.02, 0.36), (0.00, 0.02, 0.36), (0.36, 0.02, 0.36),
        (-0.18, 0.33, 0.60), (0.18, 0.33, 0.60),
        (-0.18, -0.13, 0.60), (0.18, -0.13, 0.60),
    ]
    for i, (x, y, z) in enumerate(bag_positions):
        rot_z = random.uniform(-0.08, 0.08)
        cube(f"hemp_seed_canvas_bag_{i:02d}", (cx + x, cy + y, z), (0.32, 0.26, 0.22), MAT_SEED_BAG, rot=(0, 0, rot_z))

    add_wrap(cx, cy, 0.58, 0.72, code)
    add_straps(cx, cy, 0.58, 0.72, code)
    make_front_label(cx, cy, 0.60, "HEMP SEED INPUT", code)


def add_scene_lighting_and_camera():
    bpy.ops.object.light_add(type="AREA", location=(0, -5.5, 4.2))
    light = bpy.context.object
    light.name = "large_soft_preview_light"
    light.data.energy = 600
    light.data.size = 5

    bpy.ops.object.camera_add(location=(4.5, -5.5, 3.1), rotation=(math.radians(60), 0, math.radians(39)))
    bpy.context.scene.camera = bpy.context.object

    try:
        bpy.context.scene.render.engine = "CYCLES"
    except Exception:
        pass
    bpy.context.scene.unit_settings.system = "METRIC"


def build_model() -> None:
    clear_scene()
    make_hemp_pallet(-1.85, 0.0)
    make_biomass_pallet(0.0, 0.0)
    make_seed_input_pallet(1.85, 0.0)
    add_scene_lighting_and_camera()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_FILE))
    print(f"Saved Green Horizon product pallets: {OUTPUT_FILE}")


if __name__ == "__main__":
    build_model()
