# Green Horizon Industries - Industrial Hemp Foliage Source Generator
# Blender 4.2 LTS
#
# This script creates project-owned foliage source assets for the inactive
# field-hemp crop. It does NOT register the crop with a map or modDesc.xml.
#
# Output:
#   assets/blender/green_horizon_hemp_foliage.blend
#   FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_diffuse.png
#   FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_normal.png
#   FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_distance_diffuse.png
#   FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_distance_normal.png

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ATLAS_SIZE = 1024
TILE_COLUMNS = 4
TILE_ROWS = 2
TILE_WIDTH = ATLAS_SIZE // TILE_COLUMNS
TILE_HEIGHT = ATLAS_SIZE // TILE_ROWS
DISTANCE_SIZE = 512

STATE_SPECS = [
    # index, name, height m, width m, cards, color RGBA, tile
    (1, "emerged", 0.08, 0.09, 2, (0.20, 0.58, 0.20, 1.0), 0),
    (2, "sprout", 0.18, 0.14, 2, (0.18, 0.56, 0.18, 1.0), 1),
    (3, "juvenile", 0.45, 0.26, 3, (0.14, 0.52, 0.15, 1.0), 2),
    (4, "vegetative", 0.90, 0.42, 3, (0.10, 0.47, 0.12, 1.0), 3),
    (5, "preFlower", 1.35, 0.55, 4, (0.08, 0.43, 0.10, 1.0), 4),
    (6, "flowering", 1.70, 0.66, 4, (0.07, 0.39, 0.09, 1.0), 5),
    (7, "mature", 2.00, 0.76, 4, (0.09, 0.36, 0.08, 1.0), 6),
    (8, "withered", 1.85, 0.68, 3, (0.43, 0.32, 0.12, 1.0), 7),
    # Cut state reuses the mature atlas tile on short crossed cards.
    (9, "cut", 0.20, 0.26, 2, (0.16, 0.29, 0.08, 1.0), 6),
]


def find_repo_root() -> Path:
    try:
        script_path = Path(__file__).resolve()
    except NameError:
        script_path = Path.cwd()

    base = script_path if script_path.is_dir() else script_path.parent
    for candidate in [base, *base.parents]:
        if (candidate / "FS25_GreenHorizonIndustries").exists() or (candidate / ".git").exists():
            return candidate

    return Path.home() / "Documents" / "GreenHorizonIndustries"


REPO_ROOT = find_repo_root()
OUTPUT_DIR = REPO_ROOT / "assets" / "blender"
OUTPUT_FILE = OUTPUT_DIR / "green_horizon_hemp_foliage.blend"
TEXTURE_DIR = REPO_ROOT / "FS25_GreenHorizonIndustries" / "foliage" / "hemp" / "textures"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()

    for data_blocks in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
        for block in list(data_blocks):
            if block.users == 0:
                data_blocks.remove(block)


def clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def distance_to_segment(px: float, py: float, ax: float, ay: float, bx: float, by: float) -> float:
    abx = bx - ax
    aby = by - ay
    apx = px - ax
    apy = py - ay
    denom = abx * abx + aby * aby
    if denom <= 1e-9:
        return math.hypot(px - ax, py - ay)
    t = clamp01((apx * abx + apy * aby) / denom)
    cx = ax + abx * t
    cy = ay + aby * t
    return math.hypot(px - cx, py - cy)


def inside_leaf(px: float, py: float, cx: float, cy: float, radius: float, rotation: float, fingers: int) -> bool:
    # A cannabis-style leaf is approximated as several tapered finger segments.
    half = (fingers - 1) / 2.0
    for index in range(fingers):
        spread = (index - half) * (math.pi / (fingers + 1.0))
        angle = rotation + spread
        length = radius * (1.0 - 0.075 * abs(index - half))
        tip_x = cx + math.sin(angle) * length
        tip_y = cy - math.cos(angle) * length
        segment_distance = distance_to_segment(px, py, cx, cy, tip_x, tip_y)
        along = math.hypot(px - cx, py - cy) / max(length, 1e-6)
        width = radius * 0.14 * max(0.20, 1.0 - along)
        if segment_distance <= width:
            return True
    return False


def sample_state_tile(state_index: int, u: float, v: float):
    _, name, height, _, _, color, _ = STATE_SPECS[state_index]

    # Tile coordinates use bottom-left origin to match Blender image coordinates.
    stem_x = 0.50
    ground_y = 0.06
    normalized_height = min(0.88, 0.18 + height / 2.5)
    top_y = ground_y + normalized_height

    stem_width = 0.012 + state_index * 0.0015
    alpha = 0.0
    red, green, blue, _ = color

    if abs(u - stem_x) <= stem_width and ground_y <= v <= top_y:
        alpha = 1.0
        red *= 0.65
        green *= 0.72
        blue *= 0.55

    leaf_count = min(10, 2 + state_index)
    for leaf_index in range(leaf_count):
        t = (leaf_index + 1) / (leaf_count + 1)
        y = ground_y + normalized_height * t
        side = -1.0 if leaf_index % 2 == 0 else 1.0
        x = stem_x + side * (0.075 + 0.10 * t)
        radius = 0.050 + 0.055 * t
        rotation = side * 0.62
        fingers = 5 if state_index < 2 else 7
        if inside_leaf(u, v, x, y, radius, rotation, fingers):
            alpha = 1.0

        # Branch from stem to leaf center.
        if distance_to_segment(u, v, stem_x, y, x, y) <= 0.008:
            alpha = 1.0
            red *= 0.80
            green *= 0.85
            blue *= 0.75

    # Crown leaves and flower clusters for advanced states.
    if state_index >= 4:
        for crown_index in range(3):
            x = stem_x + (crown_index - 1) * 0.060
            y = top_y - 0.020 - abs(crown_index - 1) * 0.015
            if inside_leaf(u, v, x, y, 0.085, (crown_index - 1) * 0.22, 7):
                alpha = 1.0

    if name in {"flowering", "mature"}:
        flower_color = (0.50, 0.56, 0.22) if name == "flowering" else (0.42, 0.48, 0.18)
        for dx, dy in ((0.0, 0.0), (-0.045, -0.035), (0.045, -0.035)):
            if math.hypot(u - (stem_x + dx), v - (top_y + dy)) <= 0.045:
                red, green, blue = flower_color
                alpha = 1.0

    if name == "withered" and alpha > 0.0:
        red *= 1.05
        green *= 0.92
        blue *= 0.72

    # Soft dark outline improves alpha-card readability.
    if alpha > 0.0:
        edge_darkening = 0.88
        red *= edge_darkening
        green *= edge_darkening
        blue *= edge_darkening

    return clamp01(red), clamp01(green), clamp01(blue), alpha


def create_atlas_image(name: str, size: int, diffuse: bool):
    image = bpy.data.images.new(name, width=size, height=size, alpha=True)
    pixels = [0.0] * (size * size * 4)

    columns = TILE_COLUMNS
    rows = TILE_ROWS
    tile_width = size // columns
    tile_height = size // rows

    for y in range(size):
        tile_row = min(rows - 1, y // tile_height)
        local_y = (y % tile_height) / max(tile_height - 1, 1)
        for x in range(size):
            tile_column = min(columns - 1, x // tile_width)
            tile_index = tile_row * columns + tile_column
            local_x = (x % tile_width) / max(tile_width - 1, 1)

            rgba = sample_state_tile(tile_index, local_x, local_y)
            pixel_index = (y * size + x) * 4

            if diffuse:
                pixels[pixel_index : pixel_index + 4] = rgba
            else:
                # Functional flat normal map with the same alpha silhouette.
                pixels[pixel_index : pixel_index + 4] = (0.5, 0.5, 1.0, rgba[3])

    image.pixels = pixels
    return image


def save_image(image, filename: str) -> None:
    TEXTURE_DIR.mkdir(parents=True, exist_ok=True)
    path = TEXTURE_DIR / filename
    image.filepath_raw = str(path)
    image.file_format = "PNG"
    image.save()


def create_textures():
    diffuse = create_atlas_image("GHI_HempFoliageDiffuse", ATLAS_SIZE, True)
    normal = create_atlas_image("GHI_HempFoliageNormal", ATLAS_SIZE, False)
    save_image(diffuse, "hempFoliage_diffuse.png")
    save_image(normal, "hempFoliage_normal.png")

    distance_diffuse = diffuse.copy()
    distance_diffuse.name = "GHI_HempFoliageDistanceDiffuse"
    distance_diffuse.scale(DISTANCE_SIZE, DISTANCE_SIZE)
    save_image(distance_diffuse, "hempFoliage_distance_diffuse.png")

    distance_normal = normal.copy()
    distance_normal.name = "GHI_HempFoliageDistanceNormal"
    distance_normal.scale(DISTANCE_SIZE, DISTANCE_SIZE)
    save_image(distance_normal, "hempFoliage_distance_normal.png")

    return diffuse, normal


def create_material(diffuse_image, normal_image):
    material = bpy.data.materials.new("GHI_hempFoliageAtlas")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links

    bsdf = nodes.get("Principled BSDF")
    diffuse_node = nodes.new("ShaderNodeTexImage")
    diffuse_node.name = "hempFoliageDiffuse"
    diffuse_node.image = diffuse_image
    normal_node = nodes.new("ShaderNodeTexImage")
    normal_node.name = "hempFoliageNormal"
    normal_node.image = normal_image
    normal_node.image.colorspace_settings.name = "Non-Color"
    normal_map = nodes.new("ShaderNodeNormalMap")

    links.new(diffuse_node.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(diffuse_node.outputs["Alpha"], bsdf.inputs["Alpha"])
    links.new(normal_node.outputs["Color"], normal_map.inputs["Color"])
    links.new(normal_map.outputs["Normal"], bsdf.inputs["Normal"])

    bsdf.inputs["Roughness"].default_value = 0.68
    if hasattr(material, "surface_render_method"):
        material.surface_render_method = "DITHERED"
    elif hasattr(material, "blend_method"):
        material.blend_method = "CLIP"
    if hasattr(material, "alpha_threshold"):
        material.alpha_threshold = 0.35
    if hasattr(material, "show_transparent_back"):
        material.show_transparent_back = True

    material["ghiFruitType"] = "HEMP"
    material["ghiTextureAtlas"] = "hempFoliage_diffuse.png"
    return material


def tile_uv(tile_index: int):
    column = tile_index % TILE_COLUMNS
    row = tile_index // TILE_COLUMNS
    u0 = column / TILE_COLUMNS
    u1 = (column + 1) / TILE_COLUMNS
    v0 = row / TILE_ROWS
    v1 = (row + 1) / TILE_ROWS
    return ((u0, v0), (u1, v0), (u1, v1), (u0, v1))


def create_card(name: str, width: float, height: float, rotation_z: float, tile_index: int, material, parent):
    half_width = width * 0.5
    vertices = [
        Vector((-half_width, 0.0, 0.0)),
        Vector((half_width, 0.0, 0.0)),
        Vector((half_width, 0.0, height)),
        Vector((-half_width, 0.0, height)),
    ]

    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata([tuple(vertex) for vertex in vertices], [], [(0, 1, 2, 3)])
    mesh.update()

    uv_layer = mesh.uv_layers.new(name="UVMap")
    for loop, uv in zip(mesh.loops, tile_uv(tile_index)):
        uv_layer.data[loop.index].uv = uv

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.rotation_euler.z = rotation_z
    obj.data.materials.append(material)
    obj.parent = parent
    return obj


def create_state_source(root, material, spec, x_position: float):
    state_index, state_name, height, width, card_count, _, tile_index = spec
    state_root = bpy.data.objects.new(f"growthState{state_index:02d}_{state_name}", None)
    bpy.context.collection.objects.link(state_root)
    state_root.location.x = x_position
    state_root.parent = root
    state_root["growthState"] = state_index
    state_root["stateName"] = state_name
    state_root["heightMeters"] = height
    state_root["harvestReady"] = state_index == 7
    state_root["withered"] = state_index == 8
    state_root["cutState"] = state_index == 9

    for card_index in range(card_count):
        rotation = math.pi * card_index / card_count
        card = create_card(
            f"state{state_index:02d}_nearCard{card_index + 1:02d}",
            width,
            height,
            rotation,
            tile_index,
            material,
            state_root,
        )
        card["lod"] = "near"

    distance_card = create_card(
        f"state{state_index:02d}_distanceCard",
        width * 1.05,
        height,
        0.0,
        tile_index,
        material,
        state_root,
    )
    distance_card.location.y = -0.90
    distance_card["lod"] = "distance"

    return state_root


def build_source_scene(material):
    root = bpy.data.objects.new("hempFoliageSource", None)
    bpy.context.collection.objects.link(root)
    root["fruitType"] = "HEMP"
    root["numStateChannels"] = 4
    root["numGrowthStates"] = 7
    root["witheredState"] = 8
    root["cutState"] = 9

    spacing = 1.65
    for index, spec in enumerate(STATE_SPECS):
        create_state_source(root, material, spec, (index - 4) * spacing)

    return root


def build() -> None:
    clear_scene()
    diffuse, normal = create_textures()
    material = create_material(diffuse, normal)
    build_source_scene(material)

    bpy.context.scene.unit_settings.system = "METRIC"
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_FILE))

    print(f"Saved hemp foliage source blend: {OUTPUT_FILE}")
    print(f"Saved foliage texture set: {TEXTURE_DIR}")
    print("Crop registration remains inactive until map foliage integration is complete.")


if __name__ == "__main__":
    build()
