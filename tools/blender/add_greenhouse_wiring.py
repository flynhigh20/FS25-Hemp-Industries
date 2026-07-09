# Green Horizon Industries - Add Greenhouse Light Wiring Helper
# Run after tools/blender/create_green_horizon_greenhouse.py in Blender 4.2 LTS.
#
# Simple pass only:
# - wires for the grow lights
# - no connector cubes
# - no irrigation hoses
# - no extra detail clutter

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
BLEND_FILE = REPO_ROOT / "assets" / "blender" / "green_horizon_hemp_greenhouse.blend"


def make_mat(name: str, color, roughness: float = 0.82):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        if "Base Color" in bsdf.inputs:
            bsdf.inputs["Base Color"].default_value = color
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = roughness
    return mat


def clear_old_wiring() -> None:
    prefixes = ("GHI_wire_", "GHI_hose_", "GHI_connector_")
    for obj in list(bpy.context.scene.objects):
        if obj.name.startswith(prefixes):
            bpy.data.objects.remove(obj, do_unlink=True)


def cable_curve(name: str, points, radius: float, mat):
    curve = bpy.data.curves.new(name, type="CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 2
    curve.bevel_depth = radius
    curve.bevel_resolution = 3

    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, co in zip(spline.points, points):
        point.co = (co[0], co[1], co[2], 1.0)

    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def add_light_wires() -> None:
    clear_old_wiring()
    mat_cable = make_mat("black_electrical_cable_detail", (0.004, 0.004, 0.003, 1.0), 0.82)

    # Main wire run along the side/eave area.
    cable_curve(
        "GHI_wire_main_light_power_run",
        [
            (-3.20, -2.52, 1.55),
            (-3.20, -2.52, 2.24),
            (-3.20, -2.28, 2.36),
            (-1.40, -2.28, 2.36),
            (0.00, -2.28, 2.36),
            (1.40, -2.28, 2.36),
            (2.80, -2.28, 2.36),
        ],
        0.016,
        mat_cable,
    )

    # Simple feeds/drops to the three grow light strips.
    for idx, y in enumerate([-1.45, 0.0, 1.45], start=1):
        cable_curve(
            f"GHI_wire_light_feed_{idx}",
            [
                (-2.65, -2.28, 2.36),
                (-2.50, y, 2.38),
                (-2.20, y, 2.46),
                (-2.20, y, 2.34),
            ],
            0.011,
            mat_cable,
        )

        # A thin backbone directly above each light so the bars do not look like floating pieces.
        cable_curve(
            f"GHI_wire_light_backbone_{idx}",
            [
                (-3.05, y, 2.47),
                (-1.00, y, 2.47),
                (1.00, y, 2.47),
                (3.05, y, 2.47),
            ],
            0.008,
            mat_cable,
        )


def main() -> None:
    if not BLEND_FILE.exists():
        raise FileNotFoundError(f"Run create_green_horizon_greenhouse.py first. Missing: {BLEND_FILE}")

    bpy.ops.wm.open_mainfile(filepath=str(BLEND_FILE))
    add_light_wires()
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_FILE))
    print(f"Added simple grow-light wires: {BLEND_FILE}")


if __name__ == "__main__":
    main()
