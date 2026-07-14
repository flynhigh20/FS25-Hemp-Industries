# Green Horizon Industries - Product Pallet Blender Generator
# Blender 4.2 LTS
#
# Builds six project-owned pallet source models with export-oriented helper
# hierarchies and image-based materials. The pallet XML templates remain inactive
# until each root is exported to its matching i3d and the node paths are verified.

from __future__ import annotations

import math
import random
from pathlib import Path

import bpy


random.seed(2525)

TEXTURE_SIZE = 128
ADD_PREVIEW_CAMERA = True

PRODUCTS = [
    {
        "code": "hemp",
        "fill_type": "HEMP",
        "title": "INDUSTRIAL HEMP",
        "kind": "blocks",
        "color": (0.20, 0.43, 0.14, 1.0),
        "accent": (0.50, 0.72, 0.25, 1.0),
    },
    {
        "code": "seed",
        "fill_type": "GHI_HEMP_SEED",
        "title": "HEMP SEED",
        "kind": "bags",
        "color": (0.58, 0.48, 0.27, 1.0),
        "accent": (0.86, 0.77, 0.48, 1.0),
    },
    {
        "code": "biomass",
        "fill_type": "GHI_HEMP_BIOMASS",
        "title": "HEMP BIOMASS",
        "kind": "bales",
        "color": (0.43, 0.42, 0.21, 1.0),
        "accent": (0.69, 0.63, 0.34, 1.0),
    },
    {
        "code": "fiber",
        "fill_type": "GHI_HEMP_FIBER",
        "title": "HEMP FIBER",
        "kind": "fiber",
        "color": (0.64, 0.58, 0.40, 1.0),
        "accent": (0.88, 0.83, 0.61, 1.0),
    },
    {
        "code": "flower",
        "fill_type": "HEMP_FLOWER",
        "title": "HEMP FLOWER",
        "kind": "cartons",
        "color": (0.23, 0.38, 0.13, 1.0),
        "accent": (0.59, 0.42, 0.68, 1.0),
    },
    {
        "code": "oil",
        "fill_type": "GHI_HEMP_OIL",
        "title": "HEMP OIL",
        "kind": "drums",
        "color": (0.57, 0.40, 0.08, 1.0),
        "accent": (0.90, 0.68, 0.15, 1.0),
    },
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
OUTPUT_FILE = OUTPUT_DIR / "green_horizon_product_pallets.blend"
TEXTURE_DIR = REPO_ROOT / "FS25_GreenHorizonIndustries" / "pallets" / "textures"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()

    for data_blocks in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.materials,
        bpy.data.images,
        bpy.data.cameras,
        bpy.data.lights,
    ):
        for block in list(data_blocks):
            if block.users == 0:
                data_blocks.remove(block)


def clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def texture_pixels(name: str, base_color, accent_color=None) -> list[float]:
    pixels: list[float] = []
    seed = sum((index + 1) * ord(char) for index, char in enumerate(name))

    for y in range(TEXTURE_SIZE):
        for x in range(TEXTURE_SIZE):
            noise = random.Random((x * 73856093) ^ (y * 19349663) ^ seed).random()
            grain = (noise - 0.5) * 0.13
            stripe = 0.0

            if name == "wood":
                stripe = 0.08 * math.sin(x * math.pi / 12.0)
            elif name == "wrap":
                stripe = 0.05 * math.sin((x + y) * math.pi / 18.0)
            elif name == "label":
                stripe = -0.08 if x < 5 or x > TEXTURE_SIZE - 6 or y < 5 or y > TEXTURE_SIZE - 6 else 0.0
            elif name == "metal":
                stripe = 0.04 * math.sin(x * math.pi / 7.0)

            color = list(base_color)
            for channel in range(3):
                color[channel] = clamp01(color[channel] + grain + stripe)

            if accent_color is not None and ((x // 16) + (y // 16)) % 7 == 0:
                for channel in range(3):
                    color[channel] = color[channel] * 0.70 + accent_color[channel] * 0.30

            pixels.extend((color[0], color[1], color[2], color[3]))

    return pixels


def create_texture(name: str, filename: str, base_color, accent_color=None):
    TEXTURE_DIR.mkdir(parents=True, exist_ok=True)
    path = TEXTURE_DIR / filename

    image_name = f"GHI_{name}_{filename}"
    old = bpy.data.images.get(image_name)
    if old is not None:
        bpy.data.images.remove(old)

    image = bpy.data.images.new(image_name, width=TEXTURE_SIZE, height=TEXTURE_SIZE, alpha=True)
    image.pixels = texture_pixels(name, base_color, accent_color)
    image.filepath_raw = str(path)
    image.file_format = "PNG"
    image.save()
    return image


def make_image_material(
    name: str,
    texture_name: str,
    filename: str,
    base_color,
    accent_color=None,
    roughness: float = 0.65,
    metallic: float = 0.0,
    alpha: bool = False,
):
    material = bpy.data.materials.new(name)
    material.use_nodes = True

    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    texture = nodes.new("ShaderNodeTexImage")
    texture.name = name + "Texture"
    texture.image = create_texture(texture_name, filename, base_color, accent_color)

    links.new(texture.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic

    if alpha:
        links.new(texture.outputs["Alpha"], bsdf.inputs["Alpha"])
        if hasattr(material, "surface_render_method"):
            material.surface_render_method = "DITHERED"
        elif hasattr(material, "blend_method"):
            material.blend_method = "BLEND"
        if hasattr(material, "show_transparent_back"):
            material.show_transparent_back = True

    material["ghiTextureFilename"] = filename
    return material


def add_empty(name: str, loc=(0.0, 0.0, 0.0), parent=None, size: float = 0.12):
    bpy.ops.object.empty_add(type="PLAIN_AXES", location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.empty_display_size = size
    if parent is not None:
        obj.parent = parent
    return obj


def cube(name: str, loc, dimensions, material=None, parent=None, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rotation)
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


def add_text_mesh(name: str, body: str, loc, size: float, material, parent):
    bpy.ops.object.text_add(location=loc, rotation=(math.radians(90), 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    obj.data.body = body
    obj.data.align_x = "CENTER"
    obj.data.align_y = "CENTER"
    obj.data.size = size
    obj.data.extrude = 0.004
    obj.data.materials.append(material)
    obj.parent = parent

    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    return bpy.context.object


def make_trigger_box(name: str, loc, dimensions, helper_material, parent):
    obj = cube(name, loc, dimensions, helper_material, parent)
    obj.display_type = "WIRE"
    obj.hide_render = True
    obj["static"] = True
    obj["trigger"] = True
    obj["collisionFilterGroup"] = "0x20000000"
    obj["collisionFilterMask"] = "0x100000"
    obj["nonRenderable"] = True
    obj["castsShadows"] = False
    return obj


def make_collision(name: str, loc, dimensions, helper_material, parent):
    obj = cube(name, loc, dimensions, helper_material, parent)
    obj.display_type = "WIRE"
    obj.hide_render = True
    obj["dynamic"] = True
    obj["collisionFilterGroup"] = "0x8"
    obj["collisionFilterMask"] = "0x1"
    obj["nonRenderable"] = True
    obj["castsShadows"] = False
    return obj


def build_materials():
    materials = {
        "wood": make_image_material(
            "GHI_palletWood",
            "wood",
            "pallet_wood_diffuse.png",
            (0.46, 0.30, 0.15, 1.0),
            (0.75, 0.56, 0.31, 1.0),
            roughness=0.88,
        ),
        "darkWood": make_image_material(
            "GHI_palletDarkWood",
            "wood",
            "pallet_dark_wood_diffuse.png",
            (0.20, 0.12, 0.05, 1.0),
            (0.40, 0.25, 0.10, 1.0),
            roughness=0.92,
        ),
        "wrap": make_image_material(
            "GHI_clearWrap",
            "wrap",
            "pallet_wrap_diffuse.png",
            (0.70, 0.88, 0.84, 0.20),
            roughness=0.20,
            alpha=True,
        ),
        "label": make_image_material(
            "GHI_labelStock",
            "label",
            "pallet_label_diffuse.png",
            (0.92, 0.88, 0.70, 1.0),
            (0.75, 0.70, 0.52, 1.0),
            roughness=0.65,
        ),
        "text": make_image_material(
            "GHI_labelText",
            "solid",
            "pallet_text_diffuse.png",
            (0.01, 0.05, 0.02, 1.0),
            roughness=0.55,
        ),
        "metal": make_image_material(
            "GHI_drumMetal",
            "metal",
            "pallet_metal_diffuse.png",
            (0.18, 0.20, 0.19, 1.0),
            (0.34, 0.37, 0.35, 1.0),
            roughness=0.38,
            metallic=0.55,
        ),
        "strap": make_image_material(
            "GHI_blackStrap",
            "solid",
            "pallet_strap_diffuse.png",
            (0.01, 0.01, 0.01, 1.0),
            roughness=0.45,
        ),
        "helper": make_image_material(
            "GHI_helperNonRenderable",
            "solid",
            "pallet_helper_diffuse.png",
            (1.0, 0.12, 0.02, 0.10),
            roughness=0.90,
            alpha=True,
        ),
    }

    for product in PRODUCTS:
        materials[product["code"]] = make_image_material(
            f"GHI_{product['code']}Product",
            "product",
            f"pallet_{product['code']}_diffuse.png",
            product["color"],
            product["accent"],
            roughness=0.72 if product["code"] != "oil" else 0.38,
            metallic=0.0,
        )

    return materials


def make_pallet_base(parent, materials):
    for y in (-0.44, -0.22, 0.0, 0.22, 0.44):
        cube("topDeckBoard", (0.0, y, 0.16), (1.36, 0.13, 0.07), materials["wood"], parent)

    for y in (-0.43, 0.0, 0.43):
        cube("bottomRunner", (0.0, y, 0.035), (1.42, 0.10, 0.07), materials["darkWood"], parent)

    for x in (-0.52, 0.0, 0.52):
        for y in (-0.43, 0.0, 0.43):
            cube("palletBlock", (x, y, 0.095), (0.14, 0.14, 0.12), materials["darkWood"], parent)


def add_wrap(parent, materials, z=0.62, height=0.82):
    cube("wrapFront", (0.0, -0.62, z), (1.18, 0.018, height), materials["wrap"], parent)
    cube("wrapBack", (0.0, 0.62, z), (1.18, 0.018, height), materials["wrap"], parent)
    cube("wrapLeft", (-0.60, 0.0, z), (0.018, 1.20, height), materials["wrap"], parent)
    cube("wrapRight", (0.60, 0.0, z), (0.018, 1.20, height), materials["wrap"], parent)

    for x in (-0.34, 0.34):
        cube("strapFront", (x, -0.642, z), (0.055, 0.018, height + 0.05), materials["strap"], parent)
        cube("strapBack", (x, 0.642, z), (0.055, 0.018, height + 0.05), materials["strap"], parent)


def add_label(parent, product, materials, z=0.62):
    cube("labelPanel", (0.0, -0.654, z), (1.02, 0.025, 0.38), materials["label"], parent)
    add_text_mesh("brandText", "GREEN HORIZON", (0.0, -0.674, z + 0.105), 0.075, materials["text"], parent)
    add_text_mesh("productText", product["title"], (0.0, -0.675, z - 0.015), 0.055, materials["text"], parent)
    add_text_mesh("fillTypeText", product["fill_type"], (0.0, -0.676, z - 0.115), 0.030, materials["text"], parent)


def build_product_visual(parent, product, materials):
    product_material = materials[product["code"]]
    kind = product["kind"]

    if kind == "blocks":
        for z in (0.34, 0.58, 0.82):
            for x in (-0.32, 0.32):
                for y in (-0.28, 0.28):
                    cube("compressedHempPack", (x, y, z), (0.56, 0.48, 0.20), product_material, parent)

    elif kind == "bags":
        positions = [
            (-0.36, -0.30, 0.36), (0.00, -0.30, 0.36), (0.36, -0.30, 0.36),
            (-0.36, 0.02, 0.36), (0.00, 0.02, 0.36), (0.36, 0.02, 0.36),
            (-0.18, 0.33, 0.60), (0.18, 0.33, 0.60),
            (-0.18, -0.13, 0.60), (0.18, -0.13, 0.60),
        ]
        for x, y, z in positions:
            cube("seedBag", (x, y, z), (0.32, 0.26, 0.22), product_material, parent, rotation=(0.0, 0.0, random.uniform(-0.08, 0.08)))

    elif kind == "bales":
        for z in (0.40, 0.72):
            for y in (-0.30, 0.30):
                cube("biomassBale", (0.0, y, z), (1.08, 0.48, 0.28), product_material, parent)

    elif kind == "fiber":
        for x in (-0.36, 0.0, 0.36):
            for z in (0.39, 0.68):
                cylinder("fiberCoil", (x, 0.0, z), 0.22, 0.42, product_material, parent, vertices=28)

    elif kind == "cartons":
        for z in (0.38, 0.67):
            for x in (-0.31, 0.31):
                for y in (-0.27, 0.27):
                    cube("flowerCarton", (x, y, z), (0.55, 0.47, 0.25), product_material, parent)

    elif kind == "drums":
        for x in (-0.31, 0.31):
            for y in (-0.27, 0.27):
                cylinder("oilDrum", (x, y, 0.50), 0.23, 0.68, product_material, parent, vertices=32)
                cylinder("oilDrumBandTop", (x, y, 0.76), 0.238, 0.035, materials["metal"], parent, vertices=32)
                cylinder("oilDrumBandBottom", (x, y, 0.24), 0.238, 0.035, materials["metal"], parent, vertices=32)

    add_wrap(parent, materials)
    add_label(parent, product, materials)


def build_helper_hierarchy(root, materials):
    # Order matches the inactive pallet XML templates.
    make_trigger_box("dynamicMountTrigger", (0.0, 0.0, 0.55), (1.25, 0.90, 0.90), materials["helper"], root)
    add_empty("dischargeNode", (0.0, 0.75, 0.55), root)

    fill_unit = add_empty("fillUnit", parent=root)
    exact_fill = cube("exactFillRootNode", (0.0, 0.0, 0.56), (1.02, 0.78, 0.72), materials["helper"], fill_unit)
    exact_fill.display_type = "WIRE"
    exact_fill.hide_render = True
    exact_fill["kinematic"] = True
    exact_fill["compound"] = True
    exact_fill["collisionFilterGroup"] = "0x40000000"
    exact_fill["collisionFilterMask"] = "0x20000000"
    make_trigger_box("fillTrigger", (0.0, 0.0, 0.65), (1.15, 1.00, 0.80), materials["helper"], fill_unit)
    fill_volume = cube("fillVolume", (0.0, 0.0, 0.60), (1.00, 0.76, 0.70), materials["helper"], fill_unit)
    fill_volume.display_type = "WIRE"
    fill_volume.hide_render = True
    fill_volume["nonRenderable"] = True

    visuals = add_empty("palletVisuals", parent=root)

    collisions = add_empty("collisions", parent=root)
    make_collision("floorCollision01", (0.0, 0.0, 0.13), (1.42, 0.96, 0.24), materials["helper"], collisions)
    make_collision("floorCollision02", (0.0, 0.0, 0.58), (1.16, 0.92, 0.76), materials["helper"], collisions)

    add_empty("raycastNode", (0.0, 0.70, 0.60), root)
    make_trigger_box("dischargeActivationTrigger", (0.0, 0.80, 0.55), (0.70, 0.45, 0.65), materials["helper"], root)

    return visuals


def build_product_root(product, x_position: float, y_position: float, materials):
    root = add_empty(f"pallet_{product['code']}", (x_position, y_position, 0.0), size=0.35)
    root["fillType"] = product["fill_type"]
    root["capacityLiters"] = 1000
    root["exportFilename"] = f"{product['code']}Pallet.i3d"

    visuals = build_helper_hierarchy(root, materials)
    make_pallet_base(visuals, materials)
    build_product_visual(visuals, product, materials)
    return root


def add_preview_camera():
    if not ADD_PREVIEW_CAMERA:
        return

    bpy.ops.object.light_add(type="AREA", location=(0.0, -8.0, 7.0))
    light = bpy.context.object
    light.name = "previewAreaLight"
    light.data.energy = 1100
    light.data.size = 8

    bpy.ops.object.camera_add(location=(11.5, -13.5, 8.5), rotation=(math.radians(66), 0.0, math.radians(40)))
    camera = bpy.context.object
    camera.name = "previewCamera"
    bpy.context.scene.camera = camera


def build_model() -> None:
    clear_scene()
    materials = build_materials()

    positions = [
        (-3.3, 1.65), (0.0, 1.65), (3.3, 1.65),
        (-3.3, -1.65), (0.0, -1.65), (3.3, -1.65),
    ]

    for product, position in zip(PRODUCTS, positions):
        build_product_root(product, position[0], position[1], materials)

    add_preview_camera()
    bpy.context.scene.unit_settings.system = "METRIC"

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_FILE))

    print(f"Saved complete Green Horizon pallet source set: {OUTPUT_FILE}")
    print(f"Generated pallet material textures: {TEXTURE_DIR}")
    print("Export each pallet root separately to FS25_GreenHorizonIndustries/pallets/i3d/.")
    print("The pallet XML templates remain inactive until i3d node paths are verified.")


if __name__ == "__main__":
    build_model()
