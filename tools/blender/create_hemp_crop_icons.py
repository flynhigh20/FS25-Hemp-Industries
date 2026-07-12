# Green Horizon Industries - Hemp Crop and Product Icon Generator
# Blender 4.2 LTS
#
# Generates project-owned transparent PNG source icons. The icons remain inactive
# until their final DDS/PNG format and XML keys are verified against the target
# FS25 build.

from __future__ import annotations

import math
from pathlib import Path

import bpy


ICON_SIZE = 512

ICON_SPECS = [
    ("HEMP", "fillType_hemp.png", "leaf", (0.12, 0.46, 0.16, 1.0)),
    ("GHI_HEMP_SEED", "fillType_hempSeed.png", "seed", (0.56, 0.43, 0.20, 1.0)),
    ("GHI_HEMP_BIOMASS", "fillType_hempBiomass.png", "biomass", (0.39, 0.38, 0.17, 1.0)),
    ("GHI_HEMP_FIBER", "fillType_hempFiber.png", "fiber", (0.69, 0.62, 0.43, 1.0)),
    ("HEMP_FLOWER", "fillType_hempFlower.png", "flower", (0.30, 0.45, 0.16, 1.0)),
    ("GHI_HEMP_OIL", "fillType_hempOil.png", "oil", (0.84, 0.58, 0.08, 1.0)),
    ("HEMP_CROP", "crop_hemp.png", "crop", (0.10, 0.42, 0.14, 1.0)),
    ("HEMP_CALENDAR", "calendar_hemp.png", "calendar", (0.15, 0.36, 0.17, 1.0)),
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
OUTPUT_DIR = REPO_ROOT / "FS25_GreenHorizonIndustries" / "ui" / "icons"


def clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def blend_pixel(pixels, x: int, y: int, color) -> None:
    if x < 0 or y < 0 or x >= ICON_SIZE or y >= ICON_SIZE:
        return

    index = (y * ICON_SIZE + x) * 4
    source_alpha = clamp01(color[3])
    destination_alpha = pixels[index + 3]
    output_alpha = source_alpha + destination_alpha * (1.0 - source_alpha)

    if output_alpha <= 1e-6:
        return

    for channel in range(3):
        destination = pixels[index + channel]
        pixels[index + channel] = (
            color[channel] * source_alpha
            + destination * destination_alpha * (1.0 - source_alpha)
        ) / output_alpha
    pixels[index + 3] = output_alpha


def draw_circle(pixels, cx: float, cy: float, radius: float, color) -> None:
    x0 = max(0, int(cx - radius - 1))
    x1 = min(ICON_SIZE - 1, int(cx + radius + 1))
    y0 = max(0, int(cy - radius - 1))
    y1 = min(ICON_SIZE - 1, int(cy + radius + 1))
    radius_sq = radius * radius

    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            distance_sq = (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2
            if distance_sq <= radius_sq:
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
    x1 = min(ICON_SIZE - 1, int(max(ax, bx) + width + 1))
    y0 = max(0, int(min(ay, by) - width - 1))
    y1 = min(ICON_SIZE - 1, int(max(ay, by) + width + 1))

    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if distance_to_segment(x + 0.5, y + 0.5, ax, ay, bx, by) <= width:
                blend_pixel(pixels, x, y, color)


def point_in_polygon(x: float, y: float, points) -> bool:
    inside = False
    count = len(points)
    j = count - 1
    for i in range(count):
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
    x1 = min(ICON_SIZE - 1, int(max(point[0] for point in points) + 1))
    y0 = max(0, int(min(point[1] for point in points) - 1))
    y1 = min(ICON_SIZE - 1, int(max(point[1] for point in points) + 1))

    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if point_in_polygon(x + 0.5, y + 0.5, points):
                blend_pixel(pixels, x, y, color)


def draw_rounded_frame(pixels, base_color) -> None:
    shadow = (0.0, 0.0, 0.0, 0.30)
    border = (0.035, 0.055, 0.035, 0.98)
    panel = (base_color[0] * 0.18, base_color[1] * 0.18, base_color[2] * 0.18, 0.96)

    draw_circle(pixels, 264, 244, 205, shadow)
    draw_circle(pixels, 256, 256, 205, border)
    draw_circle(pixels, 256, 256, 188, panel)
    draw_circle(pixels, 215, 310, 120, (1.0, 1.0, 1.0, 0.035))


def draw_hemp_leaf(pixels, cx, cy, scale, color) -> None:
    dark = (color[0] * 0.48, color[1] * 0.48, color[2] * 0.48, 1.0)
    draw_line(pixels, cx, cy - 125 * scale, cx, cy + 105 * scale, 9 * scale, dark)

    angles = (-62, -42, -22, 0, 22, 42, 62)
    lengths = (112, 145, 176, 200, 176, 145, 112)
    widths = (26, 31, 35, 39, 35, 31, 26)

    for angle_deg, length, width in zip(angles, lengths, widths):
        angle = math.radians(angle_deg)
        direction_x = math.sin(angle)
        direction_y = math.cos(angle)
        tip = (cx + direction_x * length * scale, cy + direction_y * length * scale)
        perpendicular = (-direction_y, direction_x)
        base_y = cy - 20 * scale
        points = [
            (cx + perpendicular[0] * 5 * scale, base_y + perpendicular[1] * 5 * scale),
            (cx + direction_x * length * 0.58 * scale + perpendicular[0] * width * scale,
             cy + direction_y * length * 0.58 * scale + perpendicular[1] * width * scale),
            tip,
            (cx + direction_x * length * 0.58 * scale - perpendicular[0] * width * scale,
             cy + direction_y * length * 0.58 * scale - perpendicular[1] * width * scale),
        ]
        draw_polygon(pixels, points, color)
        draw_line(pixels, cx, base_y, tip[0], tip[1], 3.2 * scale, dark)


def draw_seed_icon(pixels, color) -> None:
    positions = [(205, 308, -28), (292, 318, 25), (252, 236, 4), (181, 221, 34), (330, 224, -33)]
    for cx, cy, rotation_deg in positions:
        rotation = math.radians(rotation_deg)
        length = 76
        width = 47
        direction = (math.cos(rotation), math.sin(rotation))
        perpendicular = (-direction[1], direction[0])
        points = [
            (cx - direction[0] * length / 2, cy - direction[1] * length / 2),
            (cx + perpendicular[0] * width / 2, cy + perpendicular[1] * width / 2),
            (cx + direction[0] * length / 2, cy + direction[1] * length / 2),
            (cx - perpendicular[0] * width / 2, cy - perpendicular[1] * width / 2),
        ]
        draw_polygon(pixels, points, color)
        draw_line(pixels, points[0][0], points[0][1], points[2][0], points[2][1], 3, (0.19, 0.12, 0.05, 0.8))


def draw_biomass_icon(pixels, color) -> None:
    bale = [(135, 177), (362, 177), (390, 318), (122, 318)]
    draw_polygon(pixels, bale, color)
    for y in (205, 246, 287):
        draw_line(pixels, 135, y, 377, y, 5, (0.78, 0.70, 0.38, 0.72))
    for x in (178, 255, 332):
        draw_line(pixels, x, 182, x, 313, 4, (0.12, 0.10, 0.04, 0.62))
    draw_hemp_leaf(pixels, 256, 323, 0.40, (0.16, 0.47, 0.15, 1.0))


def draw_fiber_icon(pixels, color) -> None:
    for radius in (110, 82, 54):
        ring_color = (color[0] * (1.0 - radius / 700), color[1] * (1.0 - radius / 700), color[2] * (1.0 - radius / 700), 1.0)
        for angle in range(0, 360, 2):
            a = math.radians(angle)
            b = math.radians(angle + 3)
            draw_line(pixels, 256 + math.cos(a) * radius, 256 + math.sin(a) * radius,
                      256 + math.cos(b) * radius, 256 + math.sin(b) * radius, 8, ring_color)
    draw_circle(pixels, 256, 256, 31, (0.11, 0.08, 0.04, 1.0))
    draw_line(pixels, 352, 319, 400, 365, 10, color)


def draw_flower_icon(pixels, color) -> None:
    dark = (color[0] * 0.50, color[1] * 0.50, color[2] * 0.50, 1.0)
    draw_line(pixels, 256, 132, 256, 339, 10, dark)
    clusters = [(256, 300, 74), (213, 257, 57), (300, 257, 57), (240, 207, 51), (281, 205, 50)]
    for cx, cy, radius in clusters:
        draw_circle(pixels, cx, cy, radius, color)
        for angle in range(0, 360, 45):
            a = math.radians(angle)
            draw_circle(pixels, cx + math.cos(a) * radius * 0.62, cy + math.sin(a) * radius * 0.62, radius * 0.31, (0.43, 0.62, 0.18, 0.95))
    for cx, cy in ((225, 282), (286, 286), (253, 333), (316, 245)):
        draw_circle(pixels, cx, cy, 7, (0.72, 0.52, 0.76, 0.95))


def draw_oil_icon(pixels, color) -> None:
    droplet = [(256, 367), (188, 263), (205, 192), (256, 155), (307, 192), (324, 263)]
    draw_polygon(pixels, droplet, color)
    draw_circle(pixels, 229, 259, 25, (1.0, 0.91, 0.45, 0.30))
    draw_line(pixels, 333, 177, 385, 177, 8, (0.19, 0.14, 0.04, 1.0))
    draw_line(pixels, 385, 177, 385, 319, 8, (0.19, 0.14, 0.04, 1.0))


def draw_crop_icon(pixels, color) -> None:
    draw_hemp_leaf(pixels, 256, 255, 0.86, color)
    draw_line(pixels, 125, 132, 387, 132, 9, (0.67, 0.76, 0.60, 0.90))
    draw_line(pixels, 125, 132, 125, 178, 9, (0.67, 0.76, 0.60, 0.90))
    draw_line(pixels, 387, 132, 387, 178, 9, (0.67, 0.76, 0.60, 0.90))


def draw_calendar_icon(pixels, color) -> None:
    body = [(150, 155), (362, 155), (362, 352), (150, 352)]
    draw_polygon(pixels, body, (0.89, 0.90, 0.79, 1.0))
    draw_polygon(pixels, [(150, 298), (362, 298), (362, 352), (150, 352)], color)
    draw_line(pixels, 195, 330, 195, 378, 10, (0.08, 0.10, 0.07, 1.0))
    draw_line(pixels, 317, 330, 317, 378, 10, (0.08, 0.10, 0.07, 1.0))
    for x in (190, 256, 322):
        for y in (205, 256):
            draw_circle(pixels, x, y, 13, color)
    draw_hemp_leaf(pixels, 256, 220, 0.30, (0.10, 0.43, 0.13, 1.0))


def build_icon(kind: str, base_color):
    pixels = [0.0] * (ICON_SIZE * ICON_SIZE * 4)
    draw_rounded_frame(pixels, base_color)

    if kind == "leaf":
        draw_hemp_leaf(pixels, 256, 245, 0.84, base_color)
    elif kind == "seed":
        draw_seed_icon(pixels, base_color)
    elif kind == "biomass":
        draw_biomass_icon(pixels, base_color)
    elif kind == "fiber":
        draw_fiber_icon(pixels, base_color)
    elif kind == "flower":
        draw_flower_icon(pixels, base_color)
    elif kind == "oil":
        draw_oil_icon(pixels, base_color)
    elif kind == "crop":
        draw_crop_icon(pixels, base_color)
    elif kind == "calendar":
        draw_calendar_icon(pixels, base_color)

    return pixels


def save_icon(identifier: str, filename: str, kind: str, base_color) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    image_name = f"GHI_icon_{identifier}"
    old = bpy.data.images.get(image_name)
    if old is not None:
        bpy.data.images.remove(old)

    image = bpy.data.images.new(image_name, width=ICON_SIZE, height=ICON_SIZE, alpha=True)
    image.pixels = build_icon(kind, base_color)
    image.filepath_raw = str(OUTPUT_DIR / filename)
    image.file_format = "PNG"
    image.save()
    bpy.data.images.remove(image)


def main() -> None:
    for identifier, filename, kind, base_color in ICON_SPECS:
        save_icon(identifier, filename, kind, base_color)
        print(f"Generated {identifier}: {OUTPUT_DIR / filename}")

    print("Icons remain inactive until XML paths and final DDS/PNG requirements are verified.")


if __name__ == "__main__":
    main()
