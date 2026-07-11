# Green Horizon Industries - Hemp Greenhouse Blender Generator
# Blender 4.2 LTS
#
# Phase 2.19 user-facing entry point. The shared core keeps material generation,
# helper hierarchy, and base geometry in one maintained module; this file applies
# the current Green Horizon refinement pass and saves the final .blend.

from __future__ import annotations

import math
import importlib.util
import sys
from pathlib import Path

import bpy

SCRIPT_DIR = Path(__file__).resolve().parent
CORE_PATH = SCRIPT_DIR / "greenhouse_generator_core.py"
if not CORE_PATH.exists():
    raise FileNotFoundError(f"Missing greenhouse generator core: {CORE_PATH}")

core_spec = importlib.util.spec_from_file_location("greenhouse_generator_core", CORE_PATH)
if core_spec is None or core_spec.loader is None:
    raise ImportError(f"Could not load greenhouse generator core: {CORE_PATH}")
core = importlib.util.module_from_spec(core_spec)
sys.modules[core_spec.name] = core
core_spec.loader.exec_module(core)


# Refined proportions requested after the first textured export.
core.SLAB_LENGTH = 9.4
core.SLAB_WIDTH = 6.0
core.ROOF_RIB_X_VALUES = [-4.55, -4.20, -2.80, -1.40, 0.0, 1.40, 2.80, 4.20, 4.55]
WALL_FRAME_X_VALUES = [-4.20, -2.80, -1.40, 0.0, 1.40, 2.80, 4.20]
ROOF_OVERHANG = 0.35
DOOR_HALF_WIDTH = 0.68
DOOR_BOTTOM_Z = 0.10
DOOR_TOP_Z = 2.48
DOOR_HEIGHT = DOOR_TOP_Z - DOOR_BOTTOM_Z
DOOR_CENTER_Z = (DOOR_TOP_Z + DOOR_BOTTOM_Z) / 2.0


def normalize_blender_texture_paths() -> None:
    """Store generated texture paths relative to the saved blend file.

    The GIANTS exporter can otherwise combine an absolute source path with its
    export folder and create duplicated paths. The post-export validator still
    performs a final i3d normalization to ../textures/<filename>.
    """
    for image in bpy.data.images:
        if not image.name.startswith("GHI_") or not image.filepath_raw:
            continue

        absolute_path = Path(bpy.path.abspath(image.filepath_raw)).resolve()
        if not absolute_path.exists():
            continue

        image.filepath_raw = bpy.path.relpath(
            str(absolute_path),
            start=str(core.OUTPUT_DIR),
        )


def add_walls_and_frame(visuals, glass_material, frame_material):
    """Keep wall framing at the wall ends while the roof extends past both ends."""
    core.cube(
        "wallPanelLeft",
        (0, -core.GREENHOUSE_WIDTH / 2, core.WALL_CENTER_Z),
        (core.GREENHOUSE_LENGTH, 0.035, core.WALL_HEIGHT),
        glass_material,
        visuals,
    )
    core.cube(
        "wallPanelRight",
        (0, core.GREENHOUSE_WIDTH / 2, core.WALL_CENTER_Z),
        (core.GREENHOUSE_LENGTH, 0.035, core.WALL_HEIGHT),
        glass_material,
        visuals,
    )
    core.cube(
        "wallPanelRear",
        (-core.GREENHOUSE_LENGTH / 2, 0, core.WALL_CENTER_Z),
        (0.035, core.GREENHOUSE_WIDTH, core.WALL_HEIGHT),
        glass_material,
        visuals,
    )

    front_x = core.GREENHOUSE_LENGTH / 2
    side_width = (core.GREENHOUSE_WIDTH - DOOR_HALF_WIDTH * 2.0) / 2.0
    side_center = DOOR_HALF_WIDTH + side_width / 2.0
    core.cube(
        "frontGlazingLeft",
        (front_x, -side_center, core.WALL_CENTER_Z),
        (0.035, side_width, core.WALL_HEIGHT),
        glass_material,
        visuals,
    )
    core.cube(
        "frontGlazingRight",
        (front_x, side_center, core.WALL_CENTER_Z),
        (0.035, side_width, core.WALL_HEIGHT),
        glass_material,
        visuals,
    )

    for x in WALL_FRAME_X_VALUES:
        core.cylinder_between(
            f"postLeft_x{x:.2f}",
            (x, -core.ROOF_HALF_WIDTH, 0.10),
            (x, -core.ROOF_HALF_WIDTH, core.EAVE_Z),
            core.POST_RADIUS,
            frame_material,
            visuals,
            vertices=12,
        )
        core.cylinder_between(
            f"postRight_x{x:.2f}",
            (x, core.ROOF_HALF_WIDTH, 0.10),
            (x, core.ROOF_HALF_WIDTH, core.EAVE_Z),
            core.POST_RADIUS,
            frame_material,
            visuals,
            vertices=12,
        )

    wall_min = -core.GREENHOUSE_LENGTH / 2
    wall_max = core.GREENHOUSE_LENGTH / 2
    for y in [-core.ROOF_HALF_WIDTH, core.ROOF_HALF_WIDTH]:
        for label, z in (("Lower", 0.75), ("Middle", 1.60), ("Upper", core.EAVE_Z)):
            core.cylinder_between(
                f"sideRail{label}_y{y:.2f}",
                (wall_min, y, z),
                (wall_max, y, z),
                core.RAIL_RADIUS,
                frame_material,
                visuals,
                vertices=12,
            )

    for y in [-core.GREENHOUSE_WIDTH / 2 - 0.012, core.GREENHOUSE_WIDTH / 2 + 0.012]:
        for x in WALL_FRAME_X_VALUES:
            core.cylinder_between(
                f"windowMullion_{x:.2f}_{y:.2f}",
                (x, y, 0.10),
                (x, y, core.EAVE_Z),
                0.020,
                frame_material,
                visuals,
                vertices=8,
            )

    # Rear wall framing: a modest grid that matches the side bays while keeping
    # the greenhouse transparent and uncluttered.
    rear_x = -core.GREENHOUSE_LENGTH / 2 - 0.012
    for index, y in enumerate((-1.30, 0.0, 1.30), start=1):
        core.cylinder_between(
            f"rearWallMullion{index}",
            (rear_x, y, 0.10),
            (rear_x, y, core.EAVE_Z),
            0.025,
            frame_material,
            visuals,
            vertices=10,
        )
    for index, z in enumerate((0.95, 1.80, core.EAVE_Z), start=1):
        core.cylinder_between(
            f"rearWallRail{index}",
            (rear_x, -core.ROOF_HALF_WIDTH, z),
            (rear_x, core.ROOF_HALF_WIDTH, z),
            core.RAIL_RADIUS,
            frame_material,
            visuals,
            vertices=12,
        )


def add_beds_and_details(visuals, materials):
    """Add simple planting beds and one clean, centered greenhouse door."""
    for bed_index, y in enumerate([-1.45, 0.0, 1.45], start=1):
        core.cube(
            f"raisedGrowBed{bed_index}",
            (0, y, 0.45),
            (6.8, 0.72, 0.32),
            materials["frame"],
            visuals,
        )
        core.cube(
            f"growBedSoil{bed_index}",
            (0, y, 0.64),
            (6.55, 0.55, 0.06),
            materials["soil"],
            visuals,
        )
        for x in [-2.8, -2.0, -1.2, -0.4, 0.4, 1.2, 2.0, 2.8]:
            core.add_hemp_plant(x, y, materials["stem"], materials["plant"], visuals)

    front_x = core.GREENHOUSE_LENGTH / 2 + 0.04
    door_width = DOOR_HALF_WIDTH * 2.0 - 0.10
    core.cube(
        "frontDoorGlass",
        (front_x, 0.0, DOOR_CENTER_Z),
        (0.045, door_width, DOOR_HEIGHT),
        materials["glass"],
        visuals,
    )
    for name, y in (
        ("frontDoorLeftPost", -DOOR_HALF_WIDTH),
        ("frontDoorRightPost", DOOR_HALF_WIDTH),
    ):
        core.cylinder_between(
            name,
            (front_x, y, DOOR_BOTTOM_Z),
            (front_x, y, DOOR_TOP_Z),
            core.POST_RADIUS,
            materials["frame"],
            visuals,
            vertices=12,
        )
    core.cylinder_between(
        "frontDoorTopRail",
        (front_x, -DOOR_HALF_WIDTH, DOOR_TOP_Z),
        (front_x, DOOR_HALF_WIDTH, DOOR_TOP_Z),
        core.RAIL_RADIUS,
        materials["frame"],
        visuals,
        vertices=12,
    )

    # A glass transom closes the front wall exactly up to the eave.
    transom_height = max(core.EAVE_Z - DOOR_TOP_Z, 0.12)
    core.cube(
        "frontDoorTransomGlass",
        (front_x, 0.0, DOOR_TOP_Z + transom_height * 0.5),
        (0.045, DOOR_HALF_WIDTH * 2.0, transom_height),
        materials["glass"],
        visuals,
    )
    core.cylinder_between(
        "frontDoorHeader",
        (front_x, -DOOR_HALF_WIDTH - 0.08, core.EAVE_Z),
        (front_x, DOOR_HALF_WIDTH + 0.08, core.EAVE_Z),
        core.RAIL_RADIUS * 1.35,
        materials["frame"],
        visuals,
        vertices=12,
    )

    core.cube(
        "frontDoorKickPlate",
        (front_x + 0.028, 0.0, DOOR_BOTTOM_Z + 0.15),
        (0.025, door_width - 0.08, 0.28),
        materials["frame"],
        visuals,
    )
    core.cylinder_between(
        "frontDoorMidRail",
        (front_x + 0.035, -door_width * 0.47, 1.12),
        (front_x + 0.035, door_width * 0.47, 1.12),
        core.RAIL_RADIUS,
        materials["frame"],
        visuals,
        vertices=12,
    )
    core.cube(
        "frontDoorHandle",
        (front_x + 0.075, 0.42, 1.45),
        (0.035, 0.05, 0.38),
        materials["frame"],
        visuals,
    )


def add_greenhouse_decorations(visuals, materials):
    """Add restrained functional details without changing the clean shell."""
    # One overhead irrigation main with short misting drops above the beds.
    core.cylinder_between(
        "irrigationHeaderPipe",
        (-3.35, 0.0, 2.55),
        (3.35, 0.0, 2.55),
        0.022,
        materials["rubber"],
        visuals,
        vertices=12,
    )
    for index, x in enumerate((-2.75, -1.65, -0.55, 0.55, 1.65, 2.75), start=1):
        core.cylinder_between(
            f"misterDrop{index}",
            (x, 0.0, 2.55),
            (x, 0.0, 2.37),
            0.010,
            materials["rubber"],
            visuals,
            vertices=10,
        )
        core.cylinder(
            f"misterNozzle{index}",
            (x, 0.0, 2.34),
            0.028,
            0.055,
            materials["water"],
            visuals,
            vertices=12,
        )

    # Slim gutters tucked beneath both eaves and one rear downspout.
    for side, label in ((-1, "Left"), (1, "Right")):
        y = side * (core.ROOF_HALF_WIDTH + 0.035)
        core.cylinder_between(
            f"roofGutter{label}",
            (-4.35, y, core.EAVE_Z - 0.055),
            (4.35, y, core.EAVE_Z - 0.055),
            0.035,
            materials["frame"],
            visuals,
            vertices=12,
        )
    core.cylinder_between(
        "rainDownspout",
        (-4.30, core.ROOF_HALF_WIDTH + 0.04, core.EAVE_Z - 0.05),
        (-4.30, core.ROOF_HALF_WIDTH + 0.04, 0.32),
        0.032,
        materials["frame"],
        visuals,
        vertices=12,
    )

    # Small wall instruments and a hose reel add believable scale.
    core.cube(
        "climateMonitorBox",
        (3.55, -core.ROOF_HALF_WIDTH + 0.035, 1.55),
        (0.32, 0.075, 0.42),
        materials["frame"],
        visuals,
    )
    core.cylinder(
        "hoseReel",
        (-3.35, -core.ROOF_HALF_WIDTH + 0.09, 0.92),
        0.24,
        0.12,
        materials["rubber"],
        visuals,
        vertices=24,
    ).rotation_euler.x = math.radians(90)

    # Three unobtrusive row labels at the front ends of the grow beds.
    for index, y in enumerate((-1.45, 0.0, 1.45), start=1):
        core.cube(
            f"plantRowLabel{index}",
            (3.48, y, 0.82),
            (0.05, 0.34, 0.18),
            materials["frame"],
            visuals,
        )


def add_light_conduit(visuals, materials):
    """Use rigid black conduit with junction boxes and short flexible drops."""
    core.cylinder_between(
        "mainElectricalConduit",
        (-3.30, -2.34, 2.34),
        (3.25, -2.34, 2.34),
        0.022,
        materials["wire"],
        visuals,
        vertices=12,
    )
    core.cylinder_between(
        "controlBoxConduitRise",
        (-3.20, -2.45, 1.55),
        (-3.20, -2.45, 2.30),
        0.022,
        materials["wire"],
        visuals,
        vertices=12,
    )
    core.cylinder_between(
        "controlBoxConduitLink",
        (-3.20, -2.45, 2.30),
        (-3.20, -2.34, 2.34),
        0.022,
        materials["wire"],
        visuals,
        vertices=12,
    )

    for index, y in enumerate([-1.45, 0.0, 1.45], start=1):
        x = -2.45
        core.cube(
            f"lightJunctionBox{index}",
            (x, -2.34, 2.34),
            (0.16, 0.10, 0.14),
            materials["frame"],
            visuals,
        )
        core.cylinder_between(
            f"lightConduitCrossRun{index}",
            (x, -2.30, 2.36),
            (x, y, 2.36),
            0.016,
            materials["wire"],
            visuals,
            vertices=10,
        )
        core.cable_curve(
            f"lightFlexibleDrop{index}",
            [(x, y, 2.36), (x + 0.12, y, 2.46), (x + 0.24, y, 2.39)],
            0.010,
            materials["wire"],
            visuals,
        )


def make_color_material(name: str, color):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    core.set_input(bsdf, "Base Color", color)
    core.set_input(bsdf, "Roughness", 0.45)
    core.set_input(bsdf, ["Emission Color", "Emission"], color)
    core.set_input(bsdf, "Emission Strength", 0.10)
    return material


def add_trigger_visuals(visuals, materials):
    """Visible pads show where water/seed unloading and production interaction sit."""
    unload_material = make_color_material("unloadTriggerAmber", (0.95, 0.55, 0.04, 1.0))
    player_material = make_color_material("productionTriggerGreen", (0.08, 0.72, 0.24, 1.0))

    core.cube(
        "unloadTriggerPad",
        (-3.75, 2.55, 0.115),
        (1.55, 0.88, 0.025),
        unload_material,
        visuals,
    )
    for index, y in enumerate([2.32, 2.55, 2.78], start=1):
        core.cube(
            f"unloadTriggerPadStripe{index}",
            (-3.75, y, 0.132),
            (1.35, 0.07, 0.012),
            materials["frame"],
            visuals,
        )

    core.cube(
        "productionTriggerPad",
        (3.45, -2.15, 0.115),
        (1.10, 0.72, 0.025),
        player_material,
        visuals,
    )
    core.cube(
        "productionTriggerConsole",
        (3.55, -2.45, 1.05),
        (0.36, 0.18, 1.20),
        materials["frame"],
        visuals,
    )
    core.cube(
        "productionTriggerScreen",
        (3.55, -2.54, 1.20),
        (0.24, 0.025, 0.28),
        player_material,
        visuals,
    )


def build_model() -> None:
    core.clear_scene()
    materials = core.build_materials()

    root = core.add_empty("greenHorizonHempGreenhouse", display_type="PLAIN_AXES", size=0.5)
    core.create_area_helpers(root)
    visuals = core.create_gameplay_helpers(root, materials["helper"])

    core.add_foundation(visuals, materials["concrete"])
    add_walls_and_frame(visuals, materials["glass"], materials["frame"])
    core.add_gable_roof_frame(visuals, materials["frame"], materials["rubber"])
    core.add_gable_roof_panels(visuals, materials["glass"])
    core.add_gable_end_glazing(visuals, materials["glass"], materials["frame"])
    add_beds_and_details(visuals, materials)
    add_greenhouse_decorations(visuals, materials)
    core.add_preview_camera()

    bpy.context.scene.unit_settings.system = "METRIC"
    core.OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    normalize_blender_texture_paths()
    bpy.ops.wm.save_as_mainfile(filepath=str(core.OUTPUT_FILE))

    print(f"Saved Green Horizon refined greenhouse: {core.OUTPUT_FILE}")
    print(f"Generated image textures: {core.TEXTURE_DIR}")
    print(f"Roof extends {ROOF_OVERHANG:.2f} m beyond both end walls.")
    print(f"Door top is {DOOR_TOP_Z:.2f} m above the model origin.")
    print("Gameplay triggers are included as invisible helper shapes.")
    print("Export root greenHorizonHempGreenhouse directly to the mod i3d folder.")
    print("Run menu option 13 immediately after export to normalize and validate texture paths.")


if __name__ == "__main__":
    build_model()
