# Green Horizon Industries - Add Greenhouse Wiring Helper
# Run after tools/blender/create_green_horizon_greenhouse.py in Blender 4.2 LTS.
#
# This keeps the approved frame-first greenhouse shape and adds only small utility details:
# - black power conduit from the control box
# - side power run
# - short drops to each grow light
# - small connector blocks
# - irrigation hose lines along grow beds

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


def make_mat(name: str, color, roughness: float = 0.75):
    """Create/reuse material after the target .blend is already open."""
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        if "Base Color" in bsdf.inputs:
            bsdf.inputs["Base Color"].default_value = color
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = roughness
    return mat


def get_detail_materials():
    """Do not store material globals before open_mainfile; Blender invalidates them."""
    return {
        "cable": make_mat("black_electrical_cable_detail", (0.004, 0.004, 0.003, 1.0), 0.82),
        "hose": make_mat("matte_black_irrigation_hose_detail", (0.006, 0.007, 0.005, 1.0), 0.88),
        "box": make_mat("dark_connector_box_detail", (0.015, 0.015, 0.012, 1.0), 0.70),
    }


def clear_old_wiring() -> None:
    for obj in list(bpy.context.scene.objects):
        if obj.name.startswith("GHI_wire_") or obj.name.startswith("GHI_hose_") or obj.name.startswith("GHI_connector_"):
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


def cube(name: str, loc, scale, mat):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return obj


def add_wiring() -> None:
    clear_old_wiring()
    materials = get_detail_materials()
    mat_cable = materials["cable"]
    mat_hose = materials["hose"]
    mat_box = materials["box"]

    # Main conduit: up from the side control box, then along the left wall/eave.
    cable_curve(
        "GHI_wire_main_conduit_from_control_box",
        [
            (-3.20, -2.52, 1.55),
            (-3.20, -2.52, 2.24),
            (-3.20, -2.28, 2.36),
            (-2.60, -2.28, 2.36),
            (-1.40, -2.28, 2.36),
            (0.00, -2.28, 2.36),
            (1.40, -2.28, 2.36),
            (2.60, -2.28, 2.36),
        ],
        0.018,
        mat_cable,
    )

    # Feeder wires across to the three light strips.
    for idx, y in enumerate([-1.45, 0.0, 1.45], start=1):
        cable_curve(
            f"GHI_wire_light_feed_{idx}",
            [
                (-2.60, -2.28, 2.36),
                (-2.45, y, 2.37),
                (-2.20, y, 2.46),
            ],
            0.012,
            mat_cable,
        )
        cable_curve(
            f"GHI_wire_light_drop_{idx}",
            [
                (-2.20, y, 2.46),
                (-2.20, y, 2.34),
            ],
            0.011,
            mat_cable,
        )
        cube(f"GHI_connector_light_junction_{idx}", (-2.20, y, 2.36), (0.16, 0.10, 0.08), mat_box)

    # Small cross jumpers so the light strips do not look like floating bars.
    for y in [-1.45, 0.0, 1.45]:
        cable_curve(
            f"GHI_wire_light_backbone_y{y:.2f}",
            [(-3.10, y, 2.47), (-1.20, y, 2.47), (1.20, y, 2.47), (3.10, y, 2.47)],
            0.010,
            mat_cable,
        )

    # Irrigation hoses tucked low beside the grow beds.
    for idx, y in enumerate([-1.45, 0.0, 1.45], start=1):
        cable_curve(
            f"GHI_hose_irrigation_bed_{idx}",
            [(-3.25, y - 0.32, 0.73), (-1.40, y - 0.32, 0.73), (0.0, y - 0.32, 0.73), (1.40, y - 0.32, 0.73), (3.25, y - 0.32, 0.73)],
            0.014,
            mat_hose,
        )

    # Water feed from tank to first hose run.
    cable_curve(
        "GHI_hose_water_tank_feed",
        [
            (-3.35, 2.05, 0.78),
            (-3.55, 1.40, 0.72),
            (-3.55, 0.30, 0.72),
            (-3.45, -1.77, 0.73),
        ],
        0.020,
        mat_hose,
    )


def main() -> None:
    if not BLEND_FILE.exists():
        raise FileNotFoundError(f"Run create_green_horizon_greenhouse.py first. Missing: {BLEND_FILE}")

    bpy.ops.wm.open_mainfile(filepath=str(BLEND_FILE))
    add_wiring()
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_FILE))
    print(f"Added greenhouse wiring and hose details: {BLEND_FILE}")


if __name__ == "__main__":
    main()
