# Green Horizon Industries - Hemp Cutter Effect Source Generator
# Blender 4.2 LTS
#
# Generates project-owned source textures and a preview blend for future hemp
# harvesting effects. It does not register effects in FS25.

from __future__ import annotations

import math
import random
from pathlib import Path

import bpy


random.seed(2518)
TEXTURE_SIZE = 256

EFFECT_SPECS = [
    ("hempChaff", "hemp_chaff_diffuse.png", "chaff"),
    ("hempStemShard", "hemp_stem_shard_diffuse.png", "stem"),
    ("hempLeafFragment", "hemp_leaf_fragment_diffuse.png", "leaf"),
    ("hempDust", "hemp_dust_diffuse.png", "dust"),
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
OUTPUT_FILE = OUTPUT_DIR / "green_horizon_hemp_cutter_effects.blend"
TEXTURE_DIR = REPO_ROOT / "FS25_GreenHorizonIndustries" / "foliage" / "hemp" / "effects" / "textures"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()

    for data_blocks in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.cameras, bpy.data.lights):
        for block in list(data_blocks):
            if block.users == 0:
                data_blocks.remove(block)


def clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def blend_pixel(pixels, x: int, y: int, color) -> None:
    if x < 0 or y < 0 or x >= TEXTURE_SIZE or y >= TEXTURE_SIZE:
        return

    index = (y * TEXTURE_SIZE + x) * 4
    source_alpha = clamp01(color[3])
    destination_alpha = pixels[index + 3]
    output_alpha = source_alpha + destination_alpha * (1.0 - source_alpha)
    if output_alpha <= 1e-6:
        return

    for channel in range(3):
        pixels[index + channel] = (
            color[channel] * source_alpha
            + pixels[index + channel] * destination_alpha * (1.0 - source_alpha)
        ) / output_alpha
    pixels[index + 3] = output_alpha


def draw_circle(pixels, cx: float, cy: float, radius: float, color) -> None:
    x0 = max(0, int(cx - radius - 1))
    x1 = min(TEXTURE_SIZE - 1, int(cx + radius + 1))
    y0 = max(0, int(cy - radius - 1))
    y1 = min(TEXTURE_SIZE - 1, int(cy + radius + 1))
    radius_sq = radius * radius

    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= radius_sq:
                blend_pixel(pixels, x, y, color)


def distance_to_segment(px, py, ax, ay, bx, by) -> float:
    abx = bx - ax
    aby = by - ay
    denominator = abx * abx + aby * aby
    if denominator <= 1e-9:
        return math.hypot(px - ax, py - ay)

    t = ((px - ax) * abx + (py - ay) * aby) / denominator
    t = max(0.0, min(1.0, t))
    cx = ax + abx * t
    cy = ay + aby * t
    return math.hypot(px - cx, py - cy)


def draw_line(pixels, ax, ay, bx, by, width, color) -> None:
    x0 = max(0, int(min(ax, bx) - width - 1))
    x1 = min(TEXTURE_SIZE - 1, int(max(ax, bx) + width + 1))
    y0 = max(0, int(min(ay, by) - width - 1))
    y1 = min(TEXTURE_SIZE - 1, int(max(ay, by) + width + 1))

    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if distance_to_segment(x + 0.5, y + 0.5, ax, ay, bx, by) <= width:
                blend_pixel(pixels, x, y, color)


def point_in_polygon(x: float, y: float, points) -> bool:
    inside = False
    j = len(points) - 1
    for i in range(len(points)):
        xi, yi = points[i]
        xj, yj = points[j]
        if (yi > y) != (yj > y):
            intersection_x = (xj - xi) * (y - yi) / (yj - yi) + xi
            if x < intersection_x:
                inside = not inside
        j = i
    return inside


def draw_polygon(pixels, points, color) -> None:
    x0 = max(0, int(min(point[0] for point in points) - 1))
    x1 = min(TEXTURE_SIZE - 1, int(max(point[0] for point in points) + 1))
    y0 = max(0, int(min(point[1] for point in points) - 1))
    y1 = min(TEXTURE_SIZE - 1, int(max(point[1] for point in points) + 1))

    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if point_in_polygon(x + 0.5, y + 0.5, points):
                blend_pixel(pixels, x, y, color)


def create_chaff_texture():
    pixels = [0.0] * (TEXTURE_SIZE * TEXTURE_SIZE * 4)
    colors = [(0.42, 0.45, 0.18, 0.95), (0.60, 0.55, 0.25, 0.90), (0.24, 0.38, 0.12, 0.90)]
    for _ in range(42):
        cx = random.uniform(34, 222)
        cy = random.uniform(34, 222)
        angle = random.uniform(0, math.tau)
        length = random.uniform(10, 28)
        width = random.uniform(1.5, 4.0)
        draw_line(
            pixels,
            cx - math.cos(angle) * length / 2,
            cy - math.sin(angle) * length / 2,
            cx + math.cos(angle) * length / 2,
            cy + math.sin(angle) * length / 2,
            width,
            random.choice(colors),
        )
    return pixels


def create_stem_texture():
    pixels = [0.0] * (TEXTURE_SIZE * TEXTURE_SIZE * 4)
    for _ in range(16):
        cx = random.uniform(38, 218)
        cy = random.uniform(38, 218)
        angle = random.uniform(0, math.tau)
        length = random.uniform(34, 76)
        width = random.uniform(3.0, 7.0)
        color = random.choice(
            [(0.42, 0.34, 0.12, 0.98), (0.30, 0.39, 0.12, 0.96), (0.58, 0.49, 0.20, 0.94)]
        )
        draw_line(
            pixels,
            cx - math.cos(angle) * length / 2,
            cy - math.sin(angle) * length / 2,
            cx + math.cos(angle) * length / 2,
            cy + math.sin(angle) * length / 2,
            width,
            color,
        )
    return pixels


def create_leaf_texture():
    pixels = [0.0] * (TEXTURE_SIZE * TEXTURE_SIZE * 4)
    for _ in range(14):
        cx = random.uniform(38, 218)
        cy = random.uniform(38, 218)
        angle = random.uniform(0, math.tau)
        length = random.uniform(20, 44)
        width = length * random.uniform(0.28, 0.42)
        direction = (math.cos(angle), math.sin(angle))
        perpendicular = (-direction[1], direction[0])
        tip = (cx + direction[0] * length / 2, cy + direction[1] * length / 2)
        tail = (cx - direction[0] * length / 2, cy - direction[1] * length / 2)
        points = [
            tail,
            (cx + perpendicular[0] * width, cy + perpendicular[1] * width),
            tip,
            (cx - perpendicular[0] * width, cy - perpendicular[1] * width),
        ]
        color = random.choice(
            [(0.10, 0.40, 0.10, 0.95), (0.18, 0.50, 0.14, 0.92), (0.29, 0.46, 0.12, 0.90)]
        )
        draw_polygon(pixels, points, color)
        draw_line(pixels, tail[0], tail[1], tip[0], tip[1], 1.5, (0.04, 0.18, 0.04, 0.85))
    return pixels


def create_dust_texture():
    pixels = [0.0] * (TEXTURE_SIZE * TEXTURE_SIZE * 4)
    center_x = TEXTURE_SIZE / 2
    center_y = TEXTURE_SIZE / 2
    maximum = TEXTURE_SIZE * 0.48

    for y in range(TEXTURE_SIZE):
        for x in range(TEXTURE_SIZE):
            distance = math.hypot(x + 0.5 - center_x, y + 0.5 - center_y)
            radial = max(0.0, 1.0 - distance / maximum)
            noise = random.Random(x * 92821 + y * 68917).random()
            alpha = radial ** 2.4 * (0.18 + noise * 0.42)
            if alpha > 0.01:
                blend_pixel(pixels, x, y, (0.64, 0.56, 0.34, alpha))

    for _ in range(26):
        draw_circle(
            pixels,
            random.uniform(45, 211),
            random.uniform(45, 211),
            random.uniform(4, 11),
            (0.76, 0.68, 0.42, random.uniform(0.08, 0.20)),
        )
    return pixels


def create_pixels(kind: str):
    if kind == "chaff":
        return create_chaff_texture()
    if kind == "stem":
        return create_stem_texture()
    if kind == "leaf":
        return create_leaf_texture()
    return create_dust_texture()


def save_texture(name: str, filename: str, kind: str):
    TEXTURE_DIR.mkdir(parents=True, exist_ok=True)
    image = bpy.data.images.new(name, width=TEXTURE_SIZE, height=TEXTURE_SIZE, alpha=True)
    image.pixels = create_pixels(kind)
    image.filepath_raw = str(TEXTURE_DIR / filename)
    image.file_format = "PNG"
    image.save()
    return image


def create_material(name: str, image):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = image
    links.new(texture.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(texture.outputs["Alpha"], bsdf.inputs["Alpha"])
    bsdf.inputs["Roughness"].default_value = 0.75

    if hasattr(material, "surface_render_method"):
        material.surface_render_method = "DITHERED"
    elif hasattr(material, "blend_method"):
        material.blend_method = "BLEND"
    if hasattr(material, "show_transparent_back"):
        material.show_transparent_back = True
    return material


def create_preview_card(name: str, location, material):
    bpy.ops.mesh.primitive_plane_add(size=2.0, location=location, rotation=(math.radians(90), 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    obj["sourceOnly"] = True
    return obj


def create_preview_scene(images):
    spacing = 2.4
    for index, (name, _, _) in enumerate(EFFECT_SPECS):
        material = create_material(name + "Material", images[name])
        create_preview_card(name + "Preview", ((index - 1.5) * spacing, 0.0, 1.2), material)

    bpy.ops.object.light_add(type="AREA", location=(0.0, -4.0, 6.0))
    light = bpy.context.object
    light.data.energy = 700
    light.data.size = 6

    bpy.ops.object.camera_add(location=(8.5, -11.0, 6.6), rotation=(math.radians(67), 0.0, math.radians(38)))
    bpy.context.scene.camera = bpy.context.object


def main() -> None:
    clear_scene()
    images = {}
    for name, filename, kind in EFFECT_SPECS:
        images[name] = save_texture(name, filename, kind)
        print(f"Generated cutter-effect source texture: {TEXTURE_DIR / filename}")

    create_preview_scene(images)
    bpy.context.scene.unit_settings.system = "METRIC"
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_FILE))

    print(f"Saved cutter-effect preview blend: {OUTPUT_FILE}")
    print("Effect assets remain inactive until vehicle/cutter nodes and FS25 effect XML are verified.")


if __name__ == "__main__":
    main()
