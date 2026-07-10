# Green Horizon Industries - Hemp Greenhouse Blender Generator
# Run in Blender 4.2 LTS:
#   blender --background --python tools/blender/create_green_horizon_greenhouse.py
#
# Phase 2.12 all-in-one game model source.
# Builds the greenhouse visuals, polycarbonate panels, light wiring, and a
# deterministic FS25 helper hierarchy in one script. No follow-up patch scripts.

from __future__ import annotations

import math
import random
from pathlib import Path

import bpy
from mathutils import Vector


random.seed(42025)

GREENHOUSE_LENGTH = 8.4
GREENHOUSE_WIDTH = 5.2
SLAB_LENGTH = 9.0
SLAB_WIDTH = 5.9
WALL_HEIGHT = 2.25
WALL_CENTER_Z = 1.43
EAVE_Z = 2.55
ROOF_RISE = 1.22
ROOF_STEPS = 18
ROOF_HALF_WIDTH = GREENHOUSE_WIDTH / 2.0

HOOP_RADIUS = 0.045
RAIL_RADIUS = 0.032
POST_RADIUS = 0.04
ROOF_RIB_X_VALUES = [-4.05, -2.7, -1.35, 0.0, 1.35, 2.7, 4.05]
ROOF_LONG_RAIL_T_VALUES = [0.18, 0.36, 0.50, 0.64, 0.82]

ADD_PREVIEW_CAMERA = False


def find_repo_root() -> Path:
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
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def get_bsdf(mat):
    if not mat.use_nodes:
        mat.use_nodes = True
    return mat.node_tree.nodes.get("Principled BSDF")


def set_input(node, names, value) -> None:
    if isinstance(names, str):
        names = [names]
    for name in names:
        if node is not None and name in node.inputs:
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
        if hasattr(mat, "surface_render_method"):
            mat.surface_render_method = "DITHERED"
        elif hasattr(mat, "blend_method"):
            mat.blend_method = "BLEND"
        if hasattr(mat, "show_transparent_back"):
            mat.show_transparent_back = True
    return mat


def make_emission_mat(name: str, color, strength: float = 1.2):
    mat = make_mat(name, color, roughness=0.25)
    bsdf = get_bsdf(mat)
    set_input(bsdf, ["Emission Color", "Emission"], color)
    set_input(bsdf, "Emission Strength", strength)
    return mat


def add_empty(name: str, loc=(0, 0, 0), parent=None, display_type="PLAIN_AXES", size=0.20):
    bpy.ops.object.empty_add(type=display_type, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.empty_display_size = size
    if parent is not None:
        obj.parent = parent
    return obj


def cube(name: str, loc, scale, mat=None, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if mat is not None:
        obj.data.materials.append(mat)
    if parent is not None:
        obj.parent = parent
    return obj


def cylinder(name: str, loc, radius: float, depth: float, mat=None, parent=None, vertices: int = 24, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    if mat is not None:
        obj.data.materials.append(mat)
    if parent is not None:
        obj.parent = parent
    try:
        for polygon in obj.data.polygons:
            polygon.use_smooth = True
    except Exception:
        pass
    return obj


def cylinder_between(name: str, start, end, radius: float, mat=None, parent=None, vertices: int = 16):
    start_v = Vector(start)
    end_v = Vector(end)
    direction = end_v - start_v
    length = direction.length
    if length <= 0.0001:
        return None
    obj = cylinder(name, (start_v + end_v) * 0.5, radius, length, mat, parent, vertices)
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    return obj


def cable_curve(name: str, points, bevel_depth: float, mat, parent=None):
    curve_data = bpy.data.curves.new(name + "Curve", type="CURVE")
    curve_data.dimensions = "3D"
    curve_data.resolution_u = 1
    curve_data.bevel_depth = bevel_depth
    curve_data.bevel_resolution = 2
    spline = curve_data.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, co in zip(spline.points, points):
        point.co = (*co, 1.0)
    obj = bpy.data.objects.new(name, curve_data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    if parent is not None:
        obj.parent = parent
    return obj


def mesh_panel(name: str, verts, mat, parent=None):
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata([(v.x, v.y, v.z) for v in verts], [], [(0, 1, 2, 3)])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    if parent is not None:
        obj.parent = parent
    return obj


def make_trigger_box(name: str, loc, scale, helper_mat, parent):
    obj = cube(name, loc, scale, helper_mat, parent)
    obj.display_type = "WIRE"
    obj.hide_render = True
    obj["static"] = True
    obj["trigger"] = True
    obj["collisionFilterGroup"] = "0x20000000"
    obj["collisionFilterMask"] = "0x100000"
    obj["nonRenderable"] = True
    obj["castsShadows"] = False
    obj["receiveShadows"] = False
    return obj


def make_exact_fill_root(name: str, loc, scale, helper_mat, parent):
    obj = cube(name, loc, scale, helper_mat, parent)
    obj.display_type = "WIRE"
    obj.hide_render = True
    obj["kinematic"] = True
    obj["compound"] = True
    obj["collisionFilterGroup"] = "0x40000000"
    obj["collisionFilterMask"] = "0x20000000"
    obj["nonRenderable"] = True
    obj["castsShadows"] = False
    obj["receiveShadows"] = False
    return obj


def make_static_collision(name: str, loc, scale, helper_mat, parent):
    obj = cube(name, loc, scale, helper_mat, parent)
    obj.display_type = "WIRE"
    obj.hide_render = True
    obj["static"] = True
    obj["collisionFilterGroup"] = "0x8"
    obj["collisionFilterMask"] = "0x1"
    obj["nonRenderable"] = True
    obj["castsShadows"] = False
    obj["receiveShadows"] = False
    return obj


def roof_points(steps: int = ROOF_STEPS):
    points = []
    for i in range(steps + 1):
        t = math.pi * i / steps
        y = math.cos(t) * ROOF_HALF_WIDTH
        z = EAVE_Z + math.sin(t) * ROOF_RISE
        points.append(Vector((0.0, y, z)))
    return points


def create_area_helpers(root):
    clear_group = add_empty("clearAreas", parent=root)
    clear_start = add_empty("clearAreaStart01", (-4.7, -3.1, 0.0), clear_group)
    add_empty("clearAreaHeight01", (0.0, 6.2, 0.0), clear_start)
    add_empty("clearAreaWidth01", (9.4, 0.0, 0.0), clear_start)

    level_group = add_empty("levelAreas", parent=root)
    level_start = add_empty("levelAreaStart01", (-4.7, -3.1, 0.0), level_group)
    add_empty("levelAreaWidth01", (9.4, 0.0, 0.0), level_start)
    add_empty("levelAreaHeight01", (0.0, 6.2, 0.0), level_start)

    indoor_group = add_empty("indoorAreas", parent=root)
    indoor_start = add_empty("indoorArea01Start", (-4.1, -2.4, 0.0), indoor_group)
    add_empty("indoorAreaWidth01", (8.2, 0.0, 0.0), indoor_start)
    add_empty("indoorArea1Height", (0.0, 4.8, 0.0), indoor_start)

    test_group = add_empty("testAreas", parent=root)
    test_start = add_empty("testAreaStart01", (-4.7, -3.1, 0.0), test_group)
    add_empty("testAreaEnd01", (9.4, 6.2, 4.2), test_start)

    tip_group = add_empty("tipOcclusionUpdateAreas", parent=root)
    tip_start = add_empty("tipOcclusionUpdateAreaStart01", (-4.7, -3.1, 0.0), tip_group)
    add_empty("tipOcclusionUpdateAreaEnd01", (9.4, 6.2, 4.2), tip_start)


def create_gameplay_helpers(root, helper_mat):
    game_nodes = add_empty("greenhouseGameNodes", parent=root)

    plant_parent = add_empty("plantNodes", (0.0, 0.0, 0.75), game_nodes, size=0.3)
    idx = 1
    for y in [-1.45, 0.0, 1.45]:
        for x in [-2.8, -1.4, 0.0, 1.4, 2.8]:
            add_empty(f"plantNode{idx}", (x, y, 0.0), plant_parent, size=0.08)
            idx += 1

    pallet = add_empty("palletSpawner", (3.15, 2.25, 0.05), game_nodes, size=0.3)
    spawn_start = add_empty("spawnPlaceStart01", (-0.55, -0.35, 0.0), pallet, size=0.12)
    add_empty("spawnPlaceEnd01", (1.10, 0.70, 0.0), spawn_start, size=0.12)

    selling = add_empty("sellingStation", parent=game_nodes)
    make_exact_fill_root("exactFillRootNode", (-3.75, 2.55, 0.65), (1.6, 1.15, 1.25), helper_mat, selling)
    add_empty("unloadTriggerMarker", (-3.75, 2.55, 0.05), selling, size=0.22)
    add_empty("unloadTriggerAINode", (-3.75, 3.25, 0.05), selling, size=0.22)

    add_empty("storage", parent=game_nodes)
    make_trigger_box("playerTrigger", (3.55, -2.20, 1.0), (1.35, 1.0, 1.9), helper_mat, game_nodes)
    add_empty("playerTriggerMarker", (3.55, -2.20, 0.05), game_nodes, size=0.18)
    add_empty("teleportNode", (3.15, -1.55, 0.05), game_nodes, size=0.18)

    make_trigger_box("infoTrigger", (3.25, -2.10, 1.0), (1.0, 0.8, 1.8), helper_mat, root)
    add_empty("warningStripes", (-3.75, 2.55, 0.02), root, size=0.22)

    collisions = add_empty("collisions", parent=root)
    wall_height = 2.70
    make_static_collision("collisionSideLeft", (0.0, -2.62, 1.35), (8.45, 0.12, wall_height), helper_mat, collisions)
    make_static_collision("collisionSideRight", (0.0, 2.62, 1.35), (8.45, 0.12, wall_height), helper_mat, collisions)
    make_static_collision("collisionRear", (-4.22, 0.0, 1.35), (0.12, 5.25, wall_height), helper_mat, collisions)
    make_static_collision("collisionFrontLeft", (4.22, -1.72, 1.35), (0.12, 1.80, wall_height), helper_mat, collisions)
    make_static_collision("collisionFrontRight", (4.22, 1.72, 1.35), (0.12, 1.80, wall_height), helper_mat, collisions)

    return add_empty("visuals", parent=root)


def add_roof_frame(visuals, frame_mat, rubber_mat):
    pts = roof_points()
    for x in ROOF_RIB_X_VALUES:
        for idx, (p, q) in enumerate(zip(pts, pts[1:])):
            cylinder_between(f"roofHoop_x{x:.2f}_{idx:02d}", (x, p.y, p.z), (x, q.y, q.z), HOOP_RADIUS, frame_mat, visuals, vertices=12)

    x_min = min(ROOF_RIB_X_VALUES)
    x_max = max(ROOF_RIB_X_VALUES)
    for t in ROOF_LONG_RAIL_T_VALUES:
        y = math.cos(math.pi * t) * ROOF_HALF_WIDTH
        z = EAVE_Z + math.sin(math.pi * t) * ROOF_RISE
        cylinder_between(f"roofLongRail_t{t:.2f}", (x_min, y, z), (x_max, y, z), RAIL_RADIUS, rubber_mat, visuals, vertices=12)

    for y in [-ROOF_HALF_WIDTH, ROOF_HALF_WIDTH]:
        cylinder_between(f"roofEaveRail_y{y:.2f}", (x_min, y, EAVE_Z), (x_max, y, EAVE_Z), RAIL_RADIUS, frame_mat, visuals, vertices=12)


def add_roof_panels(visuals, glass_mat):
    pts = roof_points()
    for bay_index, (x0, x1) in enumerate(zip(ROOF_RIB_X_VALUES, ROOF_RIB_X_VALUES[1:]), start=1):
        for panel_index in range(0, len(pts) - 1, 2):
            p0 = pts[panel_index]
            p1 = pts[min(panel_index + 2, len(pts) - 1)]
            verts = [Vector((x0, p0.y, p0.z)), Vector((x1, p0.y, p0.z)), Vector((x1, p1.y, p1.z)), Vector((x0, p1.y, p1.z))]
            mesh_panel(f"roofPolycarbonate_bay{bay_index:02d}_{panel_index:02d}", verts, glass_mat, visuals)


def add_walls_and_frame(visuals, glass_mat, frame_mat):
    cube("wallPanelLeft", (0, -GREENHOUSE_WIDTH / 2, WALL_CENTER_Z), (GREENHOUSE_LENGTH, 0.035, WALL_HEIGHT), glass_mat, visuals)
    cube("wallPanelRight", (0, GREENHOUSE_WIDTH / 2, WALL_CENTER_Z), (GREENHOUSE_LENGTH, 0.035, WALL_HEIGHT), glass_mat, visuals)
    cube("wallPanelRear", (-GREENHOUSE_LENGTH / 2, 0, WALL_CENTER_Z), (0.035, GREENHOUSE_WIDTH, WALL_HEIGHT), glass_mat, visuals)

    front_x = GREENHOUSE_LENGTH / 2
    cube("frontGlazingLeft", (front_x, -1.65, WALL_CENTER_Z), (0.035, 1.90, WALL_HEIGHT), glass_mat, visuals)
    cube("frontGlazingRight", (front_x, 1.65, WALL_CENTER_Z), (0.035, 1.90, WALL_HEIGHT), glass_mat, visuals)

    for x in ROOF_RIB_X_VALUES:
        cylinder_between(f"postLeft_x{x:.2f}", (x, -ROOF_HALF_WIDTH, 0.38), (x, -ROOF_HALF_WIDTH, EAVE_Z), POST_RADIUS, frame_mat, visuals, vertices=12)
        cylinder_between(f"postRight_x{x:.2f}", (x, ROOF_HALF_WIDTH, 0.38), (x, ROOF_HALF_WIDTH, EAVE_Z), POST_RADIUS, frame_mat, visuals, vertices=12)

    for y in [-ROOF_HALF_WIDTH, ROOF_HALF_WIDTH]:
        cylinder_between(f"sideRailLower_y{y:.2f}", (min(ROOF_RIB_X_VALUES), y, 0.75), (max(ROOF_RIB_X_VALUES), y, 0.75), RAIL_RADIUS, frame_mat, visuals, vertices=12)
        cylinder_between(f"sideRailMiddle_y{y:.2f}", (min(ROOF_RIB_X_VALUES), y, 1.60), (max(ROOF_RIB_X_VALUES), y, 1.60), RAIL_RADIUS, frame_mat, visuals, vertices=12)
        cylinder_between(f"sideRailUpper_y{y:.2f}", (min(ROOF_RIB_X_VALUES), y, EAVE_Z), (max(ROOF_RIB_X_VALUES), y, EAVE_Z), RAIL_RADIUS, frame_mat, visuals, vertices=12)

    for y in [-GREENHOUSE_WIDTH / 2 - 0.012, GREENHOUSE_WIDTH / 2 + 0.012]:
        for x in ROOF_RIB_X_VALUES:
            cylinder_between(f"windowMullion_{x:.2f}_{y:.2f}", (x, y, 0.38), (x, y, 2.45), 0.020, frame_mat, visuals, vertices=8)


def add_foundation(visuals, concrete_mat):
    cube("concreteSlab", (0, 0, 0.05), (SLAB_LENGTH, SLAB_WIDTH, 0.10), concrete_mat, visuals)
    cube("curbFront", (0, -SLAB_WIDTH / 2, 0.28), (SLAB_LENGTH, 0.18, 0.36), concrete_mat, visuals)
    cube("curbRear", (0, SLAB_WIDTH / 2, 0.28), (SLAB_LENGTH, 0.18, 0.36), concrete_mat, visuals)
    cube("curbLeft", (-SLAB_LENGTH / 2, 0, 0.28), (0.18, SLAB_WIDTH, 0.36), concrete_mat, visuals)
    cube("curbRight", (SLAB_LENGTH / 2, 0, 0.28), (0.18, SLAB_WIDTH, 0.36), concrete_mat, visuals)


def add_leaf(name: str, loc, angle: float, scale: float, plant_mat, parent):
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=loc, rotation=(math.radians(65), 0, angle))
    obj = bpy.context.object
    obj.name = name
    obj.scale = (0.10 * scale, 0.32 * scale, 1.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(plant_mat)
    obj.parent = parent
    return obj


def add_hemp_plant(x: float, y: float, stem_mat, plant_mat, parent):
    cylinder("hempStem", (x, y, 0.78), 0.018, 0.62, stem_mat, parent, vertices=8)
    for i in range(6):
        angle = math.radians(i * 60)
        add_leaf("hempLeaf", (x + math.cos(angle) * 0.06, y + math.sin(angle) * 0.06, 1.03), angle, random.uniform(0.65, 0.86), plant_mat, parent)


def add_beds_and_details(visuals, frame_mat, soil_mat, stem_mat, plant_mat, glass_mat, water_mat, light_mat):
    for y in [-1.45, 0.0, 1.45]:
        cube("raisedGrowBed", (0, y, 0.45), (6.8, 0.72, 0.32), frame_mat, visuals)
        cube("growBedSoil", (0, y, 0.64), (6.55, 0.55, 0.06), soil_mat, visuals)
        for x in [-2.8, -2.0, -1.2, -0.4, 0.4, 1.2, 2.0, 2.8]:
            add_hemp_plant(x, y, stem_mat, plant_mat, visuals)

    front_x = GREENHOUSE_LENGTH / 2 + 0.04
    cube("frontDoorLeftGlass", (front_x, -0.34, 1.24), (0.04, 0.58, 1.65), glass_mat, visuals)
    cube("frontDoorRightGlass", (front_x, 0.34, 1.24), (0.04, 0.58, 1.65), glass_mat, visuals)
    cylinder_between("frontDoorLeftPost", (front_x, -0.66, 0.40), (front_x, -0.66, 2.20), POST_RADIUS, frame_mat, visuals, vertices=12)
    cylinder_between("frontDoorRightPost", (front_x, 0.66, 0.40), (front_x, 0.66, 2.20), POST_RADIUS, frame_mat, visuals, vertices=12)
    cylinder_between("frontDoorTopRail", (front_x, -0.70, 2.20), (front_x, 0.70, 2.20), RAIL_RADIUS, frame_mat, visuals, vertices=12)

    cylinder("waterStorageTank", (-3.35, 2.05, 1.05), 0.42, 1.55, water_mat, visuals, vertices=40)
    cube("nutrientControlBox", (-3.2, -2.45, 1.15), (0.62, 0.12, 0.82), frame_mat, visuals)

    for idx, y in enumerate([-1.45, 0.0, 1.45], start=1):
        cube(f"growLightStrip{idx}", (0, y, 2.42), (6.8, 0.08, 0.06), light_mat, visuals)


def add_light_wires(visuals, wire_mat):
    cable_curve("mainLightPowerRun", [(-3.20, -2.52, 1.55), (-3.20, -2.52, 2.24), (-3.20, -2.28, 2.36), (-1.40, -2.28, 2.36), (0.0, -2.28, 2.36), (1.40, -2.28, 2.36), (2.80, -2.28, 2.36)], 0.016, wire_mat, visuals)
    for idx, y in enumerate([-1.45, 0.0, 1.45], start=1):
        cable_curve(f"lightFeedDrop{idx}", [(-2.65, -2.28, 2.36), (-2.50, y, 2.38), (-2.20, y, 2.46), (-2.20, y, 2.34)], 0.011, wire_mat, visuals)
        cable_curve(f"lightBackbone{idx}", [(-3.05, y, 2.47), (-1.00, y, 2.47), (1.00, y, 2.47), (3.05, y, 2.47)], 0.008, wire_mat, visuals)


def add_preview_camera():
    if not ADD_PREVIEW_CAMERA:
        return
    bpy.ops.object.light_add(type="AREA", location=(0, -7, 6))
    bpy.context.object.data.energy = 700
    bpy.context.object.data.size = 5
    bpy.ops.object.camera_add(location=(8, -8, 5.2), rotation=(math.radians(62), 0, math.radians(44)))
    bpy.context.scene.camera = bpy.context.object


def build_model() -> None:
    clear_scene()

    mat_glass = make_mat("clearPolycarbonate", (0.55, 0.85, 0.70, 0.24), 0.18, alpha=0.24)
    mat_frame = make_mat("blackPowderCoatedFrame", (0.025, 0.028, 0.025, 1.0), 0.45, 0.25)
    mat_concrete = make_mat("pouredConcrete", (0.45, 0.45, 0.40, 1.0), 0.85)
    mat_soil = make_mat("darkGrowBedSoil", (0.075, 0.045, 0.025, 1.0), 0.95)
    mat_plant = make_mat("industrialHempGreen", (0.09, 0.42, 0.15, 1.0), 0.65)
    mat_stem = make_mat("hempStemGreenBrown", (0.13, 0.30, 0.10, 1.0), 0.72)
    mat_water = make_mat("blueWaterTank", (0.04, 0.20, 0.55, 1.0), 0.38)
    mat_rubber = make_mat("blackRubberGasket", (0.008, 0.008, 0.007, 1.0), 0.72)
    mat_wire = make_mat("blackElectricalCable", (0.012, 0.012, 0.012, 1.0), 0.80)
    mat_light = make_emission_mat("warmAmberGrowLight", (1.0, 0.70, 0.22, 1.0), 1.6)
    mat_helper = make_mat("helperNonRenderable", (1.0, 0.20, 0.05, 0.10), 0.9, alpha=0.10)

    root = add_empty("greenHorizonHempGreenhouse", display_type="PLAIN_AXES", size=0.5)
    create_area_helpers(root)
    visuals = create_gameplay_helpers(root, mat_helper)

    add_foundation(visuals, mat_concrete)
    add_walls_and_frame(visuals, mat_glass, mat_frame)
    add_roof_frame(visuals, mat_frame, mat_rubber)
    add_roof_panels(visuals, mat_glass)
    add_beds_and_details(visuals, mat_frame, mat_soil, mat_stem, mat_plant, mat_glass, mat_water, mat_light)
    add_light_wires(visuals, mat_wire)
    add_preview_camera()

    bpy.context.scene.unit_settings.system = "METRIC"
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_FILE))
    print(f"Saved Green Horizon all-in-one game model: {OUTPUT_FILE}")
    print("Export the root greenHorizonHempGreenhouse to the mod i3d folder with relative paths.")


if __name__ == "__main__":
    build_model()
