"""Re-export the greenhouse and production pallets with FS25 CPU collisions.

Run with Blender 4.2 and the GIANTS I3D Exporter enabled::

    blender.exe --background --python tools/blender/reexport_collision_assets.py -- pallets
    blender.exe assets/blender/green_horizon_hemp_greenhouse.blend --background \
        --python tools/blender/reexport_collision_assets.py -- greenhouse
"""

from pathlib import Path
import math
import sys

import bpy


REPO_ROOT = Path(__file__).resolve().parents[2]
PALLET_OUTPUT = REPO_ROOT / "FS25_GreenHorizonIndustries" / "pallets" / "i3d"
GREENHOUSE_BLEND = REPO_ROOT / "assets" / "blender" / "green_horizon_hemp_greenhouse.blend"
GREENHOUSE_OUTPUT = (
    REPO_ROOT
    / "FS25_GreenHorizonIndustries"
    / "placeables"
    / "greenhouses"
    / "i3d"
    / "greenHorizonHempGreenhouse.i3d"
)


def decimal_mask(value):
    if isinstance(value, str):
        return str(int(value, 0))
    return str(int(value))


def enable_exporter():
    bpy.ops.preferences.addon_enable(module="io_export_i3d_10_0_2")
    # Registers the panel export operators when running without the Blender UI.
    bpy.ops.i3d.menuexport()


def copy_legacy_physics(obj):
    mapping = {
        "static": "i3D_static",
        "dynamic": "i3D_dynamic",
        "kinematic": "i3D_kinematic",
        "compound": "i3D_compound",
        "compoundChild": "i3D_compoundChild",
        "trigger": "i3D_trigger",
        "nonRenderable": "i3D_nonRenderable",
        "staticFriction": "i3D_staticFriction",
        "dynamicFriction": "i3D_dynamicFriction",
        "density": "i3D_density",
    }
    for old_name, new_name in mapping.items():
        if old_name in obj:
            obj[new_name] = obj[old_name]
    for old_name, new_name in (
        ("collisionFilterGroup", "i3D_collisionFilterGroup"),
        ("collisionFilterMask", "i3D_collisionFilterMask"),
    ):
        if old_name in obj:
            obj[new_name] = decimal_mask(obj[old_name])

    if obj.type == "MESH" and any(
        bool(obj.get(name, False))
        for name in ("static", "dynamic", "kinematic", "compoundChild", "trigger")
    ):
        obj["i3D_collision"] = True
        obj["i3D_cpuMesh"] = True


def select_root(root):
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    bpy.context.view_layer.objects.active = root


def export_selected(root, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    select_root(root)
    settings = bpy.context.scene.I3D_UIexportSettings
    settings.i3D_exportUseSoftwareFileName = False
    settings.i3D_exportFileLocation = str(destination)
    result = bpy.ops.i3d.panelexport_buttonexport(state=2)
    if "FINISHED" not in result:
        raise RuntimeError(f"GIANTS export failed for {root.name}: {result}")
    print(f"Exported {root.name}: {destination}")


def export_pallets():
    sys.path.insert(0, str(REPO_ROOT / "tools" / "blender"))
    import create_green_horizon_pallets

    # Direct headless exports do not need to rewrite the large multi-pallet
    # Blender source. Skipping that save also avoids a Blender 4.2 Windows
    # crash observed before the GIANTS exporter is initialized.
    create_green_horizon_pallets.build_model(save_source=False)
    enable_exporter()
    for root_name, filename in (
        ("pallet_hemp", "hempPallet.i3d"),
        ("pallet_flower", "flowerPallet.i3d"),
        ("pallet_biomass", "biomassPallet.i3d"),
    ):
        root = bpy.data.objects.get(root_name)
        if root is None:
            raise RuntimeError(f"Missing generated pallet root: {root_name}")
        export_selected(root, PALLET_OUTPUT / filename)


def prepare_greenhouse(do_export=True):
    root = bpy.data.objects.get("greenHorizonHempGreenhouse")
    if root is None:
        raise RuntimeError(f"Open the greenhouse source first: {GREENHOUSE_BLEND}")

    for obj in bpy.data.objects:
        copy_legacy_physics(obj)

    warning_stripes = bpy.data.objects.get("warningStripes")
    if warning_stripes is not None:
        warning_stripes.rotation_euler[2] = 0.0
    for stripe in bpy.data.objects:
        if stripe.name.startswith("GHI_PalletStripeYellow"):
            stripe.rotation_euler[2] = math.radians(122)

    # Use the stock FS25 BUILDING preset for player/vehicle wall collisions.
    for obj in bpy.data.objects:
        if not obj.name.startswith("collision") or obj.type != "MESH":
            continue
        obj["i3D_collision"] = True
        obj["i3D_cpuMesh"] = True
        obj["i3D_nonRenderable"] = True
        obj["i3D_collisionFilterGroup"] = "4148"
        obj["i3D_collisionFilterMask"] = "4294966271"
        if obj.name == "collisionFrontDoor":
            obj["i3D_static"] = False
            obj["i3D_kinematic"] = True
            obj["i3D_density"] = 0.0001
        else:
            obj["i3D_static"] = True

    bpy.ops.wm.save_as_mainfile(filepath=str(GREENHOUSE_BLEND))
    print(f"Saved CPU-collision greenhouse source: {GREENHOUSE_BLEND}")
    if do_export:
        enable_exporter()
        export_selected(root, GREENHOUSE_OUTPUT)


def main():
    args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    mode = args[0] if args else "pallets"
    if mode == "pallets":
        export_pallets()
    elif mode == "greenhouse":
        prepare_greenhouse(do_export=True)
    elif mode == "prepare-greenhouse":
        prepare_greenhouse(do_export=False)
    else:
        raise RuntimeError(f"Unknown export mode: {mode}")


if __name__ == "__main__":
    main()
