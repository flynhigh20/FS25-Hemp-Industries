# Green Horizon Industries - Hemp Greenhouse Blender Generator
# Blender 4.2 LTS
#
# Phase 2.19 all-in-one game model source.
# Builds a peaked glass gable greenhouse, image-based materials, visible trigger
# pads, lighting conduit, and the FS25 helper hierarchy used by the placeable XML.

from __future__ import annotations

import math
import random
from pathlib import Path

import bpy
from mathutils import Vector


random.seed(42025)

GREENHOUSE_LENGTH = 8.4
GREENHOUSE_WIDTH = 5.2
SLAB_LENGTH = 9.4
SLAB_WIDTH = 6.0
WALL_HEIGHT = 2.25
WALL_CENTER_Z = 1.43
EAVE_Z = 2.55
ROOF_RISE = 1.22
RIDGE_Z = EAVE_Z + ROOF_RISE
ROOF_HALF_WIDTH = GREENHOUSE_WIDTH / 2.0
ROOF_OVERHANG = 0.35
WALL_X_MIN = -GREENHOUSE_LENGTH / 2.0
WALL_X_MAX = GREENHOUSE_LENGTH / 2.0
ROOF_X_MIN = WALL_X_MIN - ROOF_OVERHANG
ROOF_X_MAX = WALL_X_MAX + ROOF_OVERHANG

POST_RADIUS = 0.040
RAFTER_RADIUS = 0.045
RAIL_RADIUS = 0.032
WALL_FRAME_X_VALUES = [-4.20, -2.80, -1.40, 0.0, 1.40, 2.80, 4.20]
ROOF_RIB_X_VALUES = [-4.55, -4.20, -2.80, -1.40, 0.0, 1.40, 2.80, 4.20, 4.55]
ROOF_PURLIN_FACTORS = [0.25, 0.50, 0.75]

DOOR_HALF_WIDTH = 0.95
DOOR_BOTTOM_Z = 0.38
DOOR_TOP_Z = 2.45
DOOR_HEIGHT = DOOR_TOP_Z - DOOR_BOTTOM_Z
DOOR_CENTER_Z = (DOOR_TOP_Z + DOOR_BOTTOM_Z) / 2.0

TEXTURE_SIZE = 128
ADD_PREVIEW_CAMERA = False


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
OUTPUT_FILE = OUTPUT_DIR / "green_horizon_hemp_greenhouse.blend"
TEXTURE_DIR = (
    REPO_ROOT
    / "FS25_GreenHorizonIndustries"
    / "placeables"
    / "greenhouses"
    / "textures"
)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()

    for datablocks in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
    ):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def texture_pixels(kind: str, size: int) -> list[float]:
    pixels: list[float] = []
    kind_seed = sum((index + 1) * ord(char) for index, char in enumerate(kind))

    for y in range(size):
        for x in range(size):
            u = x / max(size - 1, 1)
            v = y / max(size - 1, 1)
            noise = random.Random((x * 73856093) ^ (y * 19349663) ^ kind_seed).random()

            if kind == "frame":
                stripe = 0.018 if (x // 6) % 2 == 0 else -0.006
                base = 0.045 + stripe + (noise - 0.5) * 0.015
                rgba = (base, base * 1.04, base * 1.01, 1.0)
            elif kind == "concrete":
                speck = (noise - 0.5) * 0.18
                joint = -0.12 if x % 64 < 2 or y % 64 < 2 else 0.0
                base = 0.48 + speck + joint
                rgba = (base, base * 0.99, base * 0.93, 1.0)
            elif kind == "soil":
                grain = (noise - 0.5) * 0.20
                rgba = (0.12 + grain, 0.070 + grain * 0.55, 0.030 + grain * 0.30, 1.0)
            elif kind == "stem":
                band = 0.035 * math.sin(v * math.pi * 18.0)
                rgba = (0.16 + band, 0.30 + band, 0.10 + band * 0.5, 1.0)
            elif kind == "water":
                band = 0.03 * math.sin(v * math.pi * 10.0)
                rgba = (0.035, 0.18 + band, 0.50 + band, 1.0)
            elif kind in {"rubber", "wire"}:
                base = 0.020 + (noise - 0.5) * 0.010
                rgba = (base, base, base * 1.03, 1.0)
            elif kind == "light":
                center = 1.0 - abs(v - 0.5) * 2.0
                glow = 0.72 + center * 0.28
                rgba = (1.0, 0.48 + glow * 0.32, 0.05 + glow * 0.10, 1.0)
            elif kind == "glass":
                seam = 0.10 if x % 32 < 2 or y % 32 < 2 else 0.0
                highlight = 0.06 if (x + y) % 47 < 2 else 0.0
                rgba = (0.34 + highlight, 0.62 + highlight, 0.58 + highlight, 0.18 + seam)
            elif kind == "leaf":
                px = (u - 0.5) * 2.0
                py = (v - 0.5) * 2.0
                width = max(0.08, 0.58 * (1.0 - abs(py) ** 1.3))
                inside = abs(px) <= width and abs(py) <= 0.96
                vein = 0.18 if abs(px) < 0.035 else 0.0
                serration = 0.05 * math.sin((abs(py) + 0.03) * math.pi * 16.0)
                edge = abs(px) / max(width, 0.001)
                green = 0.34 + (1.0 - edge) * 0.18 + vein + serration
                rgba = (0.035, green, 0.075, 1.0 if inside else 0.0)
            else:
                rgba = (0.5, 0.5, 0.5, 1.0)

            pixels.extend(clamp01(channel) for channel in rgba)

    return pixels


def create_texture(kind: str, filename: str):
    TEXTURE_DIR.mkdir(parents=True, exist_ok=True)
    path = TEXTURE_DIR / filename
    image_name = f"GHI_{kind}_texture"

    old = bpy.data.images.get(image_name)
    if old is not None:
        bpy.data.images.remove(old)

    image = bpy.data.images.new(image_name, width=TEXTURE_SIZE, height=TEXTURE_SIZE, alpha=True)
    image.pixels = texture_pixels(kind, TEXTURE_SIZE)
    image.filepath_raw = str(path)
    image.file_format = "PNG"
    image.save()
    # Keep Blender's stored link relative to the generated .blend location.
    image.filepath = bpy.path.relpath(str(path), start=str(OUTPUT_DIR))
    return image


def set_input(node, names, value) -> None:
    if isinstance(names, str):
        names = [names]
    for name in names:
        if node is not None and name in node.inputs:
            node.inputs[name].default_value = value
            return


def make_image_material(
    name: str,
    texture_kind: str,
    texture_filename: str,
    roughness: float,
    metallic: float = 0.0,
    alpha_mode: str = "OPAQUE",
    emission_strength: float = 0.0,
):
    material = bpy.data.materials.new(name)
    material.use_nodes = True

    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    texture = nodes.new("ShaderNodeTexImage")
    texture.name = f"{name}_DiffuseTexture"
    texture.label = texture_filename
    texture.image = create_texture(texture_kind, texture_filename)
    texture.interpolation = "Linear"

    links.new(texture.outputs["Color"], bsdf.inputs["Base Color"])
    set_input(bsdf, "Roughness", roughness)
    set_input(bsdf, "Metallic", metallic)

    if alpha_mode != "OPAQUE":
        links.new(texture.outputs["Alpha"], bsdf.inputs["Alpha"])
        if hasattr(material, "surface_render_method"):
            material.surface_render_method = "DITHERED"
        elif hasattr(material, "blend_method"):
            material.blend_method = "CLIP" if alpha_mode == "CLIP" else "BLEND"
        if hasattr(material, "alpha_threshold"):
            material.alpha_threshold = 0.3
        if hasattr(material, "show_transparent_back"):
            material.show_transparent_back = True

    if emission_strength > 0.0:
        emission_input = bsdf.inputs.get("Emission Color") or bsdf.inputs.get("Emission")
        if emission_input is not None:
            links.new(texture.outputs["Color"], emission_input)
        set_input(bsdf, "Emission Strength", emission_strength)

    material["ghiMaterialRole"] = texture_kind
    material["ghiTextureFilename"] = texture_filename
    return material


def make_color_material(name: str, color, roughness: float = 0.6, emission_strength: float = 0.0):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    set_input(bsdf, "Base Color", color)
    set_input(bsdf, "Roughness", roughness)
    if emission_strength > 0.0:
        set_input(bsdf, ["Emission Color", "Emission"], color)
        set_input(bsdf, "Emission Strength", emission_strength)
    return material


def make_helper_material():
    material = make_color_material("helperNonRenderable", (1.0, 0.15, 0.02, 1.0), roughness=0.9)
    material.diffuse_color = (1.0, 0.15, 0.02, 0.12)
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    set_input(bsdf, "Alpha", 0.12)
    if hasattr(material, "surface_render_method"):
        material.surface_render_method = "DITHERED"
    elif hasattr(material, "blend_method"):
        material.blend_method = "BLEND"

    return material


def add_empty(name: str, loc=(0, 0, 0), parent=None, display_type="PLAIN_AXES", size=0.20):
    bpy.ops.object.empty_add(type=display_type, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.empty_display_size = size
    if parent is not None:
        obj.parent = parent
    return obj


def cube(name: str, loc, dimensions, material=None, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if material is not None:
        obj.data.materials.append(material)
    if parent is not None:
        obj.parent = parent
    return obj


def cylinder(name: str, loc, radius: float, depth: float, material=None, parent=None, vertices: int = 24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    if material is not None:
        obj.data.materials.append(material)
    if parent is not None:
        obj.parent = parent
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def cylinder_between(name: str, start, end, radius: float, material=None, parent=None, vertices: int = 16):
    start_v = Vector(start)
    end_