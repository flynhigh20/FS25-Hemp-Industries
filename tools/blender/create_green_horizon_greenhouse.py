# Green Horizon Industries - Hemp Greenhouse Blender Generator
# Run in Blender 4.2 LTS with:
# blender --background --python tools/blender/create_green_horizon_greenhouse.py
#
# Phase 2.7 frame-first greenhouse rebuild.
# This creates a Blender concept scene, not final game-ready DDS/i3d assets yet.
#
# Goal for this pass:
# - Stop trying to fix bad roof panels.
# - Remove all roof panel geometry.
# - Build only the slab, walls, clean hoop ribs, rails, doors, beds, and simple details.
# - Approve the arch/rib shape first.
# - Add transparent roof panels only after the frame shape is approved.

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
WALL_HEIGHT = 2.25
WALL_CENTER_Z = 1.43
EAVE_Z = 2.55
ROOF_RISE = 1.22
ROOF_STEPS = 18

# Frame controls. Tweak these first if the roof shape still needs work.
ROOF_HALF_WIDTH = GREENHOUSE_WIDTH / 2.0
HOOP_RADIUS = 0.045
RAIL_RADIUS = 0.032
POST_RADIUS = 0.04
ROOF_RIB_X_VALUES = [-4.05, -2.7, -1.35, 0.0, 1.35, 2.7, 4.05]
ROOF_LONG_RAIL_T_VALUES = [0.18, 0.36, 0.50, 0.64, 0.82]

# Important: roof panels stay OFF until the rib shape is approved.
ENABLE_ROOF_PANELS = False


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


def make_emission_mat(name: str, color, strength: float = 1.2):
    mat = make_mat(name, color, roughness=0.25, metallic=0.0)
    bsdf = get_bsdf(mat)
    if bsdf is not None:
        set_input(bsdf, ["Emission Color", "Emission"], color)
        set_input(bsdf, "Emission Strength", strength)
    return mat


MAT_GLASS = make_mat("transparent_wall_polycarbonate_preview", (0.55, 0.85, 0.70, 0.25), 0.18, 0.0, 0.25)
MAT_FRAME = make_mat("black_powder_coated_frame", (0.025, 0.028, 0.025, 1.0), 0.45, 0.25)
MAT_CONCRETE = make_mat("poured_concrete_slab", (0.45, 0.45, 0.40, 1.0), 0.85, 0.0)
MAT_SOIL = make_mat("dark_grow_bed_soil", (0.075, 0.045, 0.025, 1.0), 0.95, 0.0)
MAT_PLANT = make_mat("industrial_hemp_green", (0.09, 0.42, 0.15, 1.0), 0.65, 0.0)
MAT_STEM = make_mat("hemp_stem_green_brown", (0.13, 0.30, 0.10, 1.0), 0.72, 0.0)
MAT_WATER = make_mat("blue_water_tank", (0.04, 0.20, 0.55, 1.0), 0.38, 0.0)
MAT_RUBBER = make_mat("black_rubber_gasket", (0.008, 0.008, 0.007, 1.0), 0.72, 0.0)
MAT_LIGHT = make_emission_mat("warm_amber_grow_light", (1.0, 0.70, 0.22, 1.0), strength=1.6)


def cube(name: str, loc, scale, mat=None):
    """Add an unrotated cube. No rotation magic in this function."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if mat:
        obj.data.materials.append(mat)
    return obj


def cylinder_between(name: str, start: Vector, end: Vector, radius: float, mat=None, vertices: int = 16):
    """Cylinder aligned between two points. Used for roof hoops so they cannot become floor slabs."""
    start = Vector(start)
    end = Vector(end)
    mid = (start + end) * 0.5
    direction = end - start
    length = direction.length

    if length <= 0.0001:
        return None

    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=length, location=mid)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    if mat:
        obj.data.materials.append(mat)
    try:
        bpy.ops.object.shade_smooth()
    except Exception:
        pass
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
    """Hoop arch from left wall top to right wall top. It never touches the floor."""
    points = []
    for i in range(steps + 1):
        t = math.pi * i / steps
        y = math.cos(t) * ROOF_HALF_WIDTH
        z = EAVE_Z + math.sin(t) * ROOF_RISE
        points.append(Vector((0.0, y, z)))
    return points


def add_roof_hoop(x: float):
    pts = roof_points()
    for idx, (p, q) in enumerate(zip(pts, pts[1:])):
        start = Vector((x, p.y, p.z))
        end = Vector((x, q.y, q.z))
        cylinder_between(f"approval_roof_hoop_x{x:.2f}_{idx:02d}", start, end, HOOP_RADIUS, MAT_FRAME, vertices=12)


def add_roof_frame():
    # Main adjustable hoops.
    for x in ROOF_RIB_X_VALUES:
        add_roof_hoop(x)

    # Straight longitudinal rails following the arch at set positions.
    x_min = min(ROOF_RIB_X_VALUES)
    x_max = max(ROOF_RIB_X_VALUES)
    for t in ROOF_LONG_RAIL_T_VALUES:
        y = math.cos(math.pi * t) * ROOF_HALF_WIDTH
        z = EAVE_Z + math.sin(math.pi * t) * ROOF_RISE
        cylinder_between(
            f"approval_long_roof_rail_t{t:.2f}",
            Vector((x_min, y, z)),
            Vector((x_max, y, z)),
            RAIL_RADIUS,
            MAT_RUBBER,
            vertices=12,
        )

    # Eave rails where the roof meets wall tops.
    for y in [-ROOF_HALF_WIDTH, ROOF_HALF_WIDTH]:
        cylinder_between(
            f"approval_eave_rail_y{y:.2f}",
            Vector((x_min, y, EAVE_Z)),
            Vector((x_max, y, EAVE_Z)),
            RAIL_RADIUS,
            MAT_FRAME,
            vertices=12,
        )


def add_wall_frame():
    # Transparent side/end walls for scale only.
    cube("left_wall_transparent_preview", (0, -GREENHOUSE_WIDTH / 2, WALL_CENTER_Z), (GREENHOUSE_LENGTH, 0.04, WALL_HEIGHT), MAT_GLASS)
    cube("right_wall_transparent_preview", (0, GREENHOUSE_WIDTH / 2, WALL_CENTER_Z), (GREENHOUSE_LENGTH, 0.04, WALL_HEIGHT), MAT_GLASS)
    cube("rear_wall_transparent_preview", (-GREENHOUSE_LENGTH / 2, 0, WALL_CENTER_Z), (0.04, GREENHOUSE_WIDTH, WALL_HEIGHT), MAT_GLASS)
    cube("front_wall_transparent_preview", (GREENHOUSE_LENGTH / 2, 0, WALL_CENTER_Z), (0.04, GREENHOUSE_WIDTH, WALL_HEIGHT), MAT_GLASS)

    # Vertical posts line up with roof hoops.
    for x in ROOF_RIB_X_VALUES:
        cylinder_between(f"left_wall_post_x{x:.2f}", Vector((x, -ROOF_HALF_WIDTH, 0.38)), Vector((x, -ROOF_HALF_WIDTH, EAVE_Z)), POST_RADIUS, MAT_FRAME, vertices=12)
        cylinder_between(f"right_wall_post_x{x:.2f}", Vector((x, ROOF_HALF_WIDTH, 0.38)), Vector((x, ROOF_HALF_WIDTH, EAVE_Z)), POST_RADIUS, MAT_FRAME, vertices=12)

    # Side rails.
    for y in [-ROOF_HALF_WIDTH, ROOF_HALF_WIDTH]:
        cylinder_between(f"lower_side_rail_y{y:.2f}", Vector((min(ROOF_RIB_X_VALUES), y, 0.75)), Vector((max(ROOF_RIB_X_VALUES), y, 0.75)), RAIL_RADIUS, MAT_FRAME, vertices=12)
        cylinder_between(f"middle_side_rail_y{y:.2f}", Vector((min(ROOF_RIB_X_VALUES), y, 1.60)), Vector((max(ROOF_RIB_X_VALUES), y, 1.60)), RAIL_RADIUS, MAT_FRAME, vertices=12)
        cylinder_between(f"upper_side_rail_y{y:.2f}", Vector((min(ROOF_RIB_X_VALUES), y, EAVE_Z)), Vector((max(ROOF_RIB_X_VALUES), y, EAVE_Z)), RAIL_RADIUS, MAT_FRAME, vertices=12)


def add_foundation():
    cube("concrete_slab_textured", (0, 0, 0.05), (SLAB_LENGTH, SLAB_WIDTH, 0.10), MAT_CONCRETE)
    cube("front_curb", (0, -SLAB_WIDTH / 2, 0.28), (SLAB_LENGTH, 0.18, 0.36), MAT_CONCRETE)
    cube("rear_curb", (0, SLAB_WIDTH / 2, 0.28), (SLAB_LENGTH, 0.18, 0.36), MAT_CONCRETE)
    cube("left_curb", (-SLAB_LENGTH / 2, 0, 0.28), (0.18, SLAB_WIDTH, 0.36), MAT_CONCRETE)
    cube("right_curb", (SLAB_LENGTH / 2, 0, 0.28), (0.18, SLAB_WIDTH, 0.36), MAT_CONCRETE)


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
        add_leaf("simple_industrial_hemp_leaf", (x + math.cos(angle) * 0.06, y + math.sin(angle) * 0.06, 1.03), angle, random.uniform(0.65, 0.86))


def add_beds_and_details():
    for y in [-1.45, 0.0, 1.45]:
        cube("raised_hemp_grow_bed_frame", (0, y, 0.45), (6.8, 0.72, 0.32), MAT_FRAME)
        cube("soil_surface", (0, y, 0.64), (6.55, 0.55, 0.06), MAT_SOIL)
        for x in [-2.8, -2.0, -1.2, -0.4, 0.4, 1.2, 2.0, 2.8]:
            add_hemp_plant(x, y)

    # Front door scale reference.
    front_x = GREENHOUSE_LENGTH / 2 + 0.08
    cube("front_double_door_left_glass", (front_x, -0.25, 1.24), (0.04, 0.42, 1.65), MAT_GLASS)
    cube("front_double_door_right_glass", (front_x, 0.25, 1.24), (0.04, 0.42, 1.65), MAT_GLASS)
    cylinder_between("front_door_left_post", Vector((front_x, -0.50, 0.40)), Vector((front_x, -0.50, 2.20)), POST_RADIUS, MAT_FRAME, vertices=12)
    cylinder_between("front_door_right_post", Vector((front_x, 0.50, 0.40)), Vector((front_x, 0.50, 2.20)), POST_RADIUS, MAT_FRAME, vertices=12)
    cylinder_between("front_door_top_rail", Vector((front_x, -0.56, 2.20)), Vector((front_x, 0.56, 2.20)), RAIL_RADIUS, MAT_FRAME, vertices=12)

    cylinder("blue_water_storage_tank", (-3.35, 2.05, 1.05), 0.42, 1.55, MAT_WATER, vertices=40)
    cube("nutrient_control_box", (-3.2, -2.45, 1.15), (0.62, 0.12, 0.82), MAT_FRAME)
    cube("grow_light_strip_1", (0, -1.45, 2.42), (6.8, 0.08, 0.06), MAT_LIGHT)
    cube("grow_light_strip_2", (0, 0.0, 2.42), (6.8, 0.08, 0.06), MAT_LIGHT)
    cube("grow_light_strip_3", (0, 1.45, 2.42), (6.8, 0.08, 0.06), MAT_LIGHT)


def add_preview_lighting_and_camera():
    bpy.ops.object.light_add(type="AREA", location=(0, -7, 6))
    light = bpy.context.object
    light.name = "large_softbox_preview_light"
    light.data.energy = 700
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
    add_foundation()
    add_wall_frame()
    add_roof_frame()
    add_beds_and_details()
    add_preview_lighting_and_camera()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_FILE))
    print(f"Saved frame-first greenhouse approval model: {OUTPUT_FILE}")
    print("Roof panels are intentionally disabled. Approve the arch/ribs before adding panels back.")


if __name__ == "__main__":
    build_model()
