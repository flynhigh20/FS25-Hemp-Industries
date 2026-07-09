# Green Horizon Industries - GIANTS Editor Helper Markers
# Run after create_green_horizon_greenhouse.py in Blender 4.2 LTS.
#
# This does not export an i3d. It adds named placeholder objects/empties so the
# Blender scene is easier to wire later in GIANTS Editor.

from __future__ import annotations

from pathlib import Path

import bpy


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
OUTPUT_FILE = OUTPUT_DIR / "green_horizon_hemp_greenhouse_giants_helpers.blend"


def make_mat(name: str, color):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        mat.diffuse_color = color
    return mat


MAT_TRIGGER = make_mat("GHI_helper_trigger_blue", (0.1, 0.35, 1.0, 0.30))
MAT_COLLISION = make_mat("GHI_helper_collision_orange", (1.0, 0.45, 0.05, 0.25))
MAT_SPAWN = make_mat("GHI_helper_spawn_green", (0.1, 0.85, 0.2, 0.35))


HELPER_COLLECTION_NAME = "GHI_GIANTS_EDITOR_HELPERS"


def get_helper_collection():
    collection = bpy.data.collections.get(HELPER_COLLECTION_NAME)
    if collection is None:
        collection = bpy.data.collections.new(HELPER_COLLECTION_NAME)
        bpy.context.scene.collection.children.link(collection)
    return collection


def unlink_from_other_collections(obj):
    for collection in list(obj.users_collection):
        collection.objects.unlink(obj)


def add_empty(name: str, loc, display_type="CUBE", display_size=0.35):
    bpy.ops.object.empty_add(type=display_type, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.empty_display_size = display_size
    collection = get_helper_collection()
    unlink_from_other_collections(obj)
    collection.objects.link(obj)
    return obj


def add_helper_box(name: str, loc, scale, mat):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.display_type = "WIRE"
    obj.show_wire = True
    obj.show_in_front = True
    obj.data.materials.append(mat)
    collection = get_helper_collection()
    unlink_from_other_collections(obj)
    collection.objects.link(obj)
    return obj


def add_text_label(name: str, text: str, loc):
    bpy.ops.object.text_add(location=loc, rotation=(1.5708, 0, 0))
    obj = bpy.context.object
    obj.name = name
    obj.data.body = text
    obj.data.align_x = "CENTER"
    obj.data.align_y = "CENTER"
    obj.data.size = 0.18
    obj.show_in_front = True
    collection = get_helper_collection()
    unlink_from_other_collections(obj)
    collection.objects.link(obj)
    return obj


def build_helpers():
    collection = get_helper_collection()

    # Clear old helper objects only, not the actual greenhouse model.
    for obj in list(collection.objects):
        bpy.data.objects.remove(obj, do_unlink=True)

    # Main reference empties.
    add_empty("GHI_ROOT_export_reference", (0, 0, 0), "ARROWS", 0.75)
    add_empty("GHI_CAMERA_preview_reference", (8, -8, 5.2), "PLAIN_AXES", 0.45)

    # Placement / player / store helper positions.
    add_helper_box("GHI_placeable_collision_placeholder", (0, 0, 1.25), (8.8, 5.6, 2.5), MAT_COLLISION)
    add_helper_box("GHI_player_interaction_trigger_placeholder", (4.9, 0, 1.0), (0.8, 1.4, 1.8), MAT_TRIGGER)
    add_helper_box("GHI_unload_water_trigger_placeholder", (-3.9, 2.65, 0.8), (1.1, 0.75, 1.0), MAT_TRIGGER)
    add_helper_box("GHI_unload_seed_trigger_placeholder", (-2.65, 2.65, 0.8), (1.1, 0.75, 1.0), MAT_TRIGGER)
    add_helper_box("GHI_pallet_spawn_area_placeholder", (2.55, 2.15, 0.35), (1.6, 1.0, 0.35), MAT_SPAWN)
    add_helper_box("GHI_buy_marker_placeholder", (4.95, -1.45, 0.2), (0.45, 0.45, 0.25), MAT_SPAWN)

    # Text labels are just Blender helpers and should not be exported as final visible signage.
    add_text_label("GHI_label_player_trigger", "player trigger", (4.95, 0, 2.05))
    add_text_label("GHI_label_water", "water unload", (-3.9, 2.95, 1.45))
    add_text_label("GHI_label_seed", "seed unload", (-2.65, 2.95, 1.45))
    add_text_label("GHI_label_pallet_spawn", "pallet spawn", (2.55, 2.75, 0.8))

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_FILE))
    print(f"Saved GIANTS helper scene: {OUTPUT_FILE}")


if __name__ == "__main__":
    build_helpers()
