# Green Horizon Industries - Hemp Greenhouse Blender Generator
# Blender 4.2 LTS
#
# Phase 2.14 all-in-one game model source.
# Builds a peaked glass gable greenhouse, image-based materials, lighting,
# and a deterministic FS25 helper hierarchy. No follow-up patch scripts.

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
WALL_HEIGHT = 2.70
WALL_CENTER_Z = 1.45
EAVE_Z = 2.80
ROOF_RISE = 1.25
RIDGE_Z = EAVE_Z + ROOF_RISE
ROOF_HALF_WIDTH = GREENHOUSE_WIDTH / 2.0

POST_RADIUS = 0.040
RAFTER_RADIUS = 0.045
RAIL_RADIUS = 0.032
ROOF_RIB_X_VALUES = [-4.05, -2.70, -1.35, 0.0, 1.35, 2.70, 4.05]
ROOF_PURLIN_FACTORS = [0.25, 0.50, 0.75]

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
                seam = 0.16 if x % 32 < 2 or y % 32 < 2 else 0.0
                highlight = 0.10 if (x + y) % 47 < 2 else 0.0
                rgba = (
                    0.42 + highlight,
                    0.72 + highlight,
                    0.66 + highlight,
                    0.20 + seam,
                )

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


def make_helper_material():
    material = bpy.data.materials.new("helperNonRenderable")
    material.use_nodes = True
    material.diffuse_color = (1.0, 0.15, 0.02, 0.12)
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    set_input(bsdf, "Base Color", (1.0, 0.15, 0.02, 1.0))
    set_input(bsdf, "Alpha", 0.12)
    set_input(bsdf, "Roughness", 0.9)
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
    end_v = Vector(end)
    direction = end_v - start_v
    length = direction.length
    if length <= 0.0001:
        return None

    obj = cylinder(name, (start_v + end_v) * 0.5, radius, length, material, parent, vertices)
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    return obj


def cable_curve(name: str, points, bevel_depth: float, material, parent=None):
    curve_data = bpy.data.curves.new(name + "Curve", type="CURVE")
    curve_data.dimensions = "3D"
    curve_data.resolution_u = 1
    curve_data.bevel_depth = bevel_depth
    curve_data.bevel_resolution = 2

    spline = curve_data.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, coordinate in zip(spline.points, points):
        point.co = (*coordinate, 1.0)

    obj = bpy.data.objects.new(name, curve_data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    if parent is not None:
        obj.parent = parent
    return obj


def mesh_face(name: str, vertices, material, parent=None):
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata([tuple(vertex) for vertex in vertices], [], [tuple(range(len(vertices)))])
    mesh.update()

    uv_layer = mesh.uv_layers.new(name="UVMap")
    if len(vertices) == 3:
        uv_values = ((0.0, 0.0), (1.0, 0.0), (0.5, 1.0))
    else:
        uv_values = ((0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0))

    for loop, uv in zip(mesh.loops, uv_values):
        uv_layer.data[loop.index].uv = uv

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    if parent is not None:
        obj.parent = parent
    return obj


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
    obj["receiveShadows"] = False
    obj["i3D_static"] = True
    obj["i3D_trigger"] = True
    obj["i3D_collision"] = True
    obj["i3D_collisionFilterGroup"] = "536870912"
    obj["i3D_collisionFilterMask"] = "1048576"
    obj["i3D_nonRenderable"] = True
    obj["i3D_cpuMesh"] = True
    return obj


def make_exact_fill_root(name: str, loc, dimensions, helper_material, parent):
    obj = cube(name, loc, dimensions, helper_material, parent)
    obj.display_type = "WIRE"
    obj.hide_render = True
    obj["kinematic"] = True
    obj["compound"] = True
    obj["collisionFilterGroup"] = "0x40000000"
    obj["collisionFilterMask"] = "0x20000000"
    obj["nonRenderable"] = True
    obj["castsShadows"] = False
    obj["receiveShadows"] = False
    obj["i3D_kinematic"] = True
    obj["i3D_compound"] = True
    obj["i3D_collision"] = True
    obj["i3D_collisionFilterGroup"] = "1073741824"
    obj["i3D_collisionFilterMask"] = "536870912"
    obj["i3D_nonRenderable"] = True
    obj["i3D_cpuMesh"] = True
    return obj


def make_static_collision(name: str, loc, dimensions, helper_material, parent):
    obj = cube(name, loc, dimensions, helper_material, parent)
    obj.display_type = "WIRE"
    obj.hide_render = True
    obj["static"] = True
    obj["collisionFilterGroup"] = "0x8"
    obj["collisionFilterMask"] = "0x1"
    obj["nonRenderable"] = True
    obj["castsShadows"] = False
    obj["receiveShadows"] = False
    obj["i3D_static"] = True
    obj["i3D_collision"] = True
    obj["i3D_collisionFilterGroup"] = "4148"
    obj["i3D_collisionFilterMask"] = "4294966271"
    obj["i3D_staticFriction"] = 0.5
    obj["i3D_dynamicFriction"] = 0.5
    obj["i3D_density"] = 1.0
    obj["i3D_nonRenderable"] = True
    obj["i3D_cpuMesh"] = True
    return obj


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


def create_gameplay_helpers(root, helper_material):
    game_nodes = add_empty("greenhouseGameNodes", parent=root)

    plant_parent = add_empty("plantNodes", (0.0, 0.0, 0.75), game_nodes, size=0.3)
    index = 1
    for y in [-1.45, 0.0, 1.45]:
        for x in [-2.8, -1.4, 0.0, 1.4, 2.8]:
            add_empty(f"plantNode{index}", (x, y, 0.0), plant_parent, size=0.08)
            index += 1

    # Keep produced goods clear of the greenhouse and reachable by a loader.
    pallet = add_empty("palletSpawner", (2.65, -3.75, 0.05), game_nodes, size=0.3)
    spawn_start = add_empty("spawnPlaceStart01", (-0.55, -0.35, 0.0), pallet, size=0.12)
    add_empty("spawnPlaceEnd01", (1.10, 0.70, 0.0), spawn_start, size=0.12)

    selling = add_empty("sellingStation", parent=game_nodes)
    make_exact_fill_root(
        "exactFillRootNode",
        (-2.50, 4.50, 1.00),
        (8.00, 8.00, 4.00),
        helper_material,
        selling,
    )
    add_empty("unloadTriggerMarker", (-2.50, 4.50, 0.05), selling, size=0.22)
    add_empty("unloadTriggerAINode", (-2.50, 6.00, 0.05), selling, size=0.22)

    pallet_trigger = make_trigger_box(
        "palletTrigger",
        (-2.50, -4.50, 0.90),
        (4.00, 3.00, 1.80),
        helper_material,
        selling,
    )
    pallet_trigger["static"] = False
    pallet_trigger["kinematic"] = True
    pallet_trigger["compound"] = True
    pallet_trigger["collisionFilterMask"] = "0x10000"
    add_empty("seedUnloadMarker", (-2.50, -4.50, 0.05), selling, size=0.22)

    add_empty("storage", parent=game_nodes)
    make_trigger_box(
        "playerTrigger",
        (4.75, -2.0, 1.0),
        (1.20, 1.60, 1.9),
        helper_material,
        game_nodes,
    )
    add_empty("playerTriggerMarker", (4.75, -2.0, 0.05), game_nodes, size=0.18)
    add_empty("teleportNode", (4.90, 0.0, 0.05), game_nodes, size=0.18)

    make_trigger_box(
        "infoTrigger",
        (4.75, 0.0, 1.0),
        (1.20, 1.60, 1.8),
        helper_material,
        root,
    )
    add_empty("warningStripes", (-2.50, 4.50, 0.02), root, size=0.22)

    collisions = add_empty("collisions", parent=root)
    wall_height = 2.70
    make_static_collision("collisionSideLeft", (0.0, -2.62, 1.35), (8.45, 0.12, wall_height), helper_material, collisions)
    make_static_collision("collisionSideRight", (0.0, 2.62, 1.35), (8.45, 0.12, wall_height), helper_material, collisions)
    make_static_collision("collisionRear", (-4.22, 0.0, 1.35), (0.12, 5.25, wall_height), helper_material, collisions)
    make_static_collision("collisionFrontLeft", (4.22, -1.72, 1.35), (0.12, 1.80, wall_height), helper_material, collisions)
    make_static_collision("collisionFrontRight", (4.22, 1.72, 1.35), (0.12, 1.80, wall_height), helper_material, collisions)
    make_static_collision("collisionFrontDoor", (4.26, 0.0, 1.35), (0.12, 1.35, wall_height), helper_material, collisions)

    return add_empty("visuals", parent=root)


def roof_point(side: int, factor: float) -> Vector:
    # side -1 is the left slope; side +1 is the right slope.
    y = side * ROOF_HALF_WIDTH * (1.0 - factor)
    z = EAVE_Z + ROOF_RISE * factor
    return Vector((0.0, y, z))


def add_gable_roof_frame(visuals, frame_material, rubber_material):
    for x in ROOF_RIB_X_VALUES:
        left_eave = Vector((x, -ROOF_HALF_WIDTH, EAVE_Z))
        ridge = Vector((x, 0.0, RIDGE_Z))
        right_eave = Vector((x, ROOF_HALF_WIDTH, EAVE_Z))
        cylinder_between(f"gableRafterLeft_x{x:.2f}", left_eave, ridge, RAFTER_RADIUS, frame_material, visuals, vertices=12)
        cylinder_between(f"gableRafterRight_x{x:.2f}", ridge, right_eave, RAFTER_RADIUS, frame_material, visuals, vertices=12)

    x_min = min(ROOF_RIB_X_VALUES)
    x_max = max(ROOF_RIB_X_VALUES)

    cylinder_between("ridgeBeam", (x_min, 0.0, RIDGE_Z), (x_max, 0.0, RIDGE_Z), RAFTER_RADIUS, frame_material, visuals, vertices=12)
    cylinder_between("leftEaveBeam", (x_min, -ROOF_HALF_WIDTH, EAVE_Z), (x_max, -ROOF_HALF_WIDTH, EAVE_Z), RAIL_RADIUS, frame_material, visuals, vertices=12)
    cylinder_between("rightEaveBeam", (x_min, ROOF_HALF_WIDTH, EAVE_Z), (x_max, ROOF_HALF_WIDTH, EAVE_Z), RAIL_RADIUS, frame_material, visuals, vertices=12)

    for side, label in [(-1, "Left"), (1, "Right")]:
        for factor in ROOF_PURLIN_FACTORS:
            point = roof_point(side, factor)
            cylinder_between(
                f"roofPurlin{label}_{factor:.2f}",
                (x_min, point.y, point.z),
                (x_max, point.y, point.z),
                RAIL_RADIUS,
                rubber_material,
                visuals,
                vertices=12,
            )


def add_gable_roof_panels(visuals, glass_material):
    """Build two continuous overlapping roof sheets instead of disconnected faces.

    The older bay-by-bay single polygons exposed tiny seams and could disappear
    from shallow viewing angles. Thin solid sheets overlap the eave/ridge frame,
    remain visible from both sides, and read as installed polycarbonate panels.
    """
    slope_length = math.sqrt(ROOF_HALF_WIDTH ** 2 + ROOF_RISE ** 2)
    roof_length = max(ROOF_RIB_X_VALUES) - min(ROOF_RIB_X_VALUES) + 0.16
    slope_angle = math.atan2(ROOF_RISE, ROOF_HALF_WIDTH)
    center_z = (EAVE_Z + RIDGE_Z) * 0.5

    for side, label in [(-1, "left"), (1, "right")]:
        panel = cube(
            f"roofGlass_{label}_continuous",
            (0.0, side * ROOF_HALF_WIDTH * 0.5, center_z),
            (roof_length, slope_length + 0.12, 0.045),
            glass_material,
            visuals,
        )
        panel.rotation_euler.x = -side * slope_angle

    # Solid ridge and eave flashing hide panel edges and rain gaps.
    cylinder_between(
        "ridgeWeatherCap",
        (min(ROOF_RIB_X_VALUES) - 0.08, 0.0, RIDGE_Z + 0.04),
        (max(ROOF_RIB_X_VALUES) + 0.08, 0.0, RIDGE_Z + 0.04),
        RAFTER_RADIUS * 1.35,
        glass_material,
        visuals,
        vertices=12,
    )


def add_gable_end_glazing(visuals, glass_material, frame_material):
    for x, label in [(-GREENHOUSE_LENGTH / 2, "rear"), (GREENHOUSE_LENGTH / 2, "front")]:
        mesh_face(
            f"gableGlass_{label}",
            [
                Vector((x, -ROOF_HALF_WIDTH, EAVE_Z)),
                Vector((x, ROOF_HALF_WIDTH, EAVE_Z)),
                Vector((x, 0.0, RIDGE_Z)),
            ],
            glass_material,
            visuals,
        )
        cylinder_between(f"gableBeamLeft_{label}", (x, -ROOF_HALF_WIDTH, EAVE_Z), (x, 0.0, RIDGE_Z), RAFTER_RADIUS, frame_material, visuals, vertices=12)
        cylinder_between(f"gableBeamRight_{label}", (x, 0.0, RIDGE_Z), (x, ROOF_HALF_WIDTH, EAVE_Z), RAFTER_RADIUS, frame_material, visuals, vertices=12)
        cylinder_between(f"gableCenterPost_{label}", (x, 0.0, EAVE_Z), (x, 0.0, RIDGE_Z), POST_RADIUS, frame_material, visuals, vertices=12)


def add_walls_and_frame(visuals, glass_material, frame_material):
    cube("wallPanelLeft", (0, -GREENHOUSE_WIDTH / 2, WALL_CENTER_Z), (GREENHOUSE_LENGTH, 0.035, WALL_HEIGHT), glass_material, visuals)
    cube("wallPanelRight", (0, GREENHOUSE_WIDTH / 2, WALL_CENTER_Z), (GREENHOUSE_LENGTH, 0.035, WALL_HEIGHT), glass_material, visuals)
    cube("wallPanelRear", (-GREENHOUSE_LENGTH / 2, 0, WALL_CENTER_Z), (0.035, GREENHOUSE_WIDTH, WALL_HEIGHT), glass_material, visuals)

    front_x = GREENHOUSE_LENGTH / 2
    cube("frontGlazingLeft", (front_x, -1.65, WALL_CENTER_Z), (0.035, 1.90, WALL_HEIGHT), glass_material, visuals)
    cube("frontGlazingRight", (front_x, 1.65, WALL_CENTER_Z), (0.035, 1.90, WALL_HEIGHT), glass_material, visuals)

    for x in ROOF_RIB_X_VALUES:
        cylinder_between(f"postLeft_x{x:.2f}", (x, -ROOF_HALF_WIDTH, 0.38), (x, -ROOF_HALF_WIDTH, EAVE_Z), POST_RADIUS, frame_material, visuals, vertices=12)
        cylinder_between(f"postRight_x{x:.2f}", (x, ROOF_HALF_WIDTH, 0.38), (x, ROOF_HALF_WIDTH, EAVE_Z), POST_RADIUS, frame_material, visuals, vertices=12)

    for y in [-ROOF_HALF_WIDTH, ROOF_HALF_WIDTH]:
        for label, z in (("Lower", 0.75), ("Middle", 1.60), ("Upper", EAVE_Z)):
            cylinder_between(
                f"sideRail{label}_y{y:.2f}",
                (min(ROOF_RIB_X_VALUES), y, z),
                (max(ROOF_RIB_X_VALUES), y, z),
                RAIL_RADIUS,
                frame_material,
                visuals,
                vertices=12,
            )

    for y in [-GREENHOUSE_WIDTH / 2 - 0.012, GREENHOUSE_WIDTH / 2 + 0.012]:
        for x in ROOF_RIB_X_VALUES:
            cylinder_between(f"windowMullion_{x:.2f}_{y:.2f}", (x, y, 0.38), (x, y, 2.45), 0.020, frame_material, visuals, vertices=8)


def add_foundation(visuals, concrete_material):
    cube("concreteSlab", (0, 0, 0.05), (SLAB_LENGTH, SLAB_WIDTH, 0.10), concrete_material, visuals)
    cube("curbFront", (0, -SLAB_WIDTH / 2, 0.28), (SLAB_LENGTH, 0.18, 0.36), concrete_material, visuals)
    cube("curbRear", (0, SLAB_WIDTH / 2, 0.28), (SLAB_LENGTH, 0.18, 0.36), concrete_material, visuals)
    cube("curbLeft", (-SLAB_LENGTH / 2, 0, 0.28), (0.18, SLAB_WIDTH, 0.36), concrete_material, visuals)
    # Split the front curb around the centered door so the entrance meets the
    # slab instead of sitting behind a raised concrete threshold.
    door_clear_half = 0.82
    side_length = SLAB_WIDTH / 2.0 - door_clear_half
    side_center = door_clear_half + side_length / 2.0
    cube(
        "curbFrontDoorLeft",
        (SLAB_LENGTH / 2, -side_center, 0.28),
        (0.18, side_length, 0.36),
        concrete_material,
        visuals,
    )
    cube(
        "curbFrontDoorRight",
        (SLAB_LENGTH / 2, side_center, 0.28),
        (0.18, side_length, 0.36),
        concrete_material,
        visuals,
    )


def add_leaf(name: str, loc, angle: float, scale: float, plant_material, parent):
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=loc, rotation=(math.radians(65), 0, angle))
    obj = bpy.context.object
    obj.name = name
    obj.scale = (0.10 * scale, 0.32 * scale, 1.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(plant_material)
    obj.parent = parent
    return obj


def add_hemp_plant(x: float, y: float, stem_material, plant_material, parent):
    cylinder("hempStem", (x, y, 0.78), 0.018, 0.62, stem_material, parent, vertices=8)
    for index in range(6):
        angle = math.radians(index * 60)
        add_leaf(
            "hempLeaf",
            (x + math.cos(angle) * 0.06, y + math.sin(angle) * 0.06, 1.03),
            angle,
            random.uniform(0.65, 0.86),
            plant_material,
            parent,
        )


def add_beds_and_details(visuals, materials):
    for y in [-1.45, 0.0, 1.45]:
        cube("raisedGrowBed", (0, y, 0.45), (6.8, 0.72, 0.32), materials["frame"], visuals)
        cube("growBedSoil", (0, y, 0.64), (6.55, 0.55, 0.06), materials["soil"], visuals)
        for x in [-2.8, -2.0, -1.2, -0.4, 0.4, 1.2, 2.0, 2.8]:
            add_hemp_plant(x, y, materials["stem"], materials["plant"], visuals)

    front_x = GREENHOUSE_LENGTH / 2 + 0.04
    cube("frontDoorLeftGlass", (front_x, -0.34, 1.24), (0.04, 0.58, 1.65), materials["glass"], visuals)
    cube("frontDoorRightGlass", (front_x, 0.34, 1.24), (0.04, 0.58, 1.65), materials["glass"], visuals)
    cylinder_between("frontDoorLeftPost", (front_x, -0.66, 0.40), (front_x, -0.66, 2.20), POST_RADIUS, materials["frame"], visuals, vertices=12)
    cylinder_between("frontDoorRightPost", (front_x, 0.66, 0.40), (front_x, 0.66, 2.20), POST_RADIUS, materials["frame"], visuals, vertices=12)
    cylinder_between("frontDoorTopRail", (front_x, -0.70, 2.20), (front_x, 0.70, 2.20), RAIL_RADIUS, materials["frame"], visuals, vertices=12)

    cylinder("waterStorageTank", (-3.35, 2.05, 1.05), 0.42, 1.55, materials["water"], visuals, vertices=40)
    cube("nutrientControlBox", (-3.2, -2.45, 1.15), (0.62, 0.12, 0.82), materials["frame"], visuals)

    for index, y in enumerate([-1.45, 0.0, 1.45], start=1):
        cube(f"growLightStrip{index}", (0, y, 2.42), (6.8, 0.08, 0.06), materials["light"], visuals)


def add_light_wires(visuals, wire_material):
    cable_curve(
        "mainLightPowerRun",
        [
            (-3.20, -2.52, 1.55),
            (-3.20, -2.52, 2.24),
            (-3.20, -2.28, 2.36),
            (-1.40, -2.28, 2.36),
            (0.0, -2.28, 2.36),
            (1.40, -2.28, 2.36),
            (2.80, -2.28, 2.36),
        ],
        0.016,
        wire_material,
        visuals,
    )

    for index, y in enumerate([-1.45, 0.0, 1.45], start=1):
        cable_curve(
            f"lightFeedDrop{index}",
            [(-2.65, -2.28, 2.36), (-2.50, y, 2.38), (-2.20, y, 2.46), (-2.20, y, 2.34)],
            0.011,
            wire_material,
            visuals,
        )
        cable_curve(
            f"lightBackbone{index}",
            [(-3.05, y, 2.47), (-1.00, y, 2.47), (1.00, y, 2.47), (3.05, y, 2.47)],
            0.008,
            wire_material,
            visuals,
        )


def add_preview_camera():
    if not ADD_PREVIEW_CAMERA:
        return

    bpy.ops.object.light_add(type="AREA", location=(0, -7, 6))
    bpy.context.object.data.energy = 700
    bpy.context.object.data.size = 5
    bpy.ops.object.camera_add(location=(8, -8, 5.2), rotation=(math.radians(62), 0, math.radians(44)))
    bpy.context.scene.camera = bpy.context.object


def build_materials():
    return {
        "glass": make_image_material("clearPolycarbonate", "glass", "greenhouse_glass_diffuse.png", 0.15, alpha_mode="BLEND"),
        "frame": make_image_material("blackPowderCoatedFrame", "frame", "greenhouse_frame_diffuse.png", 0.42, metallic=0.35),
        "concrete": make_image_material("pouredConcrete", "concrete", "greenhouse_concrete_diffuse.png", 0.88),
        "soil": make_image_material("darkGrowBedSoil", "soil", "greenhouse_soil_diffuse.png", 0.96),
        "plant": make_image_material("industrialHempLeaf", "leaf", "greenhouse_hemp_leaf_diffuse.png", 0.62, alpha_mode="CLIP"),
        "stem": make_image_material("hempStemGreenBrown", "stem", "greenhouse_stem_diffuse.png", 0.72),
        "water": make_image_material("blueWaterTank", "water", "greenhouse_water_tank_diffuse.png", 0.36),
        "rubber": make_image_material("blackRubberGasket", "rubber", "greenhouse_rubber_diffuse.png", 0.78),
        "wire": make_image_material("blackElectricalCable", "wire", "greenhouse_wire_diffuse.png", 0.82),
        "light": make_image_material("warmAmberGrowLight", "light", "greenhouse_light_diffuse.png", 0.22, emission_strength=2.0),
        "helper": make_helper_material(),
    }


def build_model() -> None:
    clear_scene()
    materials = build_materials()

    root = add_empty("greenHorizonHempGreenhouse", display_type="PLAIN_AXES", size=0.5)
    create_area_helpers(root)
    visuals = create_gameplay_helpers(root, materials["helper"])

    add_foundation(visuals, materials["concrete"])
    add_walls_and_frame(visuals, materials["glass"], materials["frame"])
    add_gable_roof_frame(visuals, materials["frame"], materials["rubber"])
    add_gable_roof_panels(visuals, materials["glass"])
    add_gable_end_glazing(visuals, materials["glass"], materials["frame"])
    add_beds_and_details(visuals, materials)
    add_light_wires(visuals, materials["wire"])
    add_preview_camera()

    bpy.context.scene.unit_settings.system = "METRIC"
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_FILE))

    print(f"Saved Green Horizon peaked-roof model: {OUTPUT_FILE}")
    print(f"Generated image textures: {TEXTURE_DIR}")
    print("Export root greenHorizonHempGreenhouse to the mod i3d folder.")
    print("Use relative paths: YES. Save game paths: NO.")


if __name__ == "__main__":
    build_model()
