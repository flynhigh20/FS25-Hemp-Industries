# Green Horizon Industries - Add Greenhouse Roof/Window Panels Helper
# Run after tools/blender/create_green_horizon_greenhouse.py in Blender 4.2 LTS.
#
# This keeps the approved frame shape and adds missing finish pieces:
# - segmented transparent polycarbonate roof panels
# - side wall window/panel sections
# - front/rear greenhouse panel sections
#
# Run order:
#   1) tools/blender/create_green_horizon_greenhouse.py
#   2) tools/blender/add_greenhouse_panels.py
#   3) tools/blender/add_greenhouse_wiring.py

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector

GREENHOUSE_LENGTH = 8.4
GREENHOUSE_WIDTH = 5.2
EAVE_Z = 2.55
ROOF_RISE = 1.22
ROOF_STEPS = 18
ROOF_HALF_WIDTH = GREENHOUSE_WIDTH / 2.0
ROOF_RIB_X_VALUES = [-4.05, -2.7, -1.35, 0.0, 1.35, 2.7, 4.05]


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


def make_mat(name: str, color, roughness: float = 0.18, alpha: float = 0.32):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = get_bsdf(mat)
    set_input(bsdf, "Base Color", color)
    set_input(bsdf, "Roughness", roughness)
    set_input(bsdf, "Alpha", alpha)
    mat.blend_method = "BLEND"
    mat.show_transparent_back = True
    if hasattr(mat, "use_screen_refraction"):
        mat.use_screen_refraction = True
    return mat


def clear_old_panels() -> None:
    prefixes = ("GHI_roof_panel_", "GHI_window_panel_", "GHI_end_panel_")
    for obj in list(bpy.context.scene.objects):
        if obj.name.startswith(prefixes):
            bpy.data.objects.remove(obj, do_unlink=True)


def roof_points(steps: int = ROOF_STEPS):
    points = []
    for i in range(steps + 1):
        t = math.pi * i / steps
        y = math.cos(t) * ROOF_HALF_WIDTH
        z = EAVE_Z + math.sin(t) * ROOF_RISE
        points.append(Vector((0.0, y, z)))
    return points


def mesh_panel(name: str, verts, mat):
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata([(v.x, v.y, v.z) for v in verts], [], [(0, 1, 2, 3)])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
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


def add_roof_panels(mat_panel):
    pts = roof_points()
    # Step by 2 so it reads like panel sheets, not dozens of tiny shards.
    for bay_index, (x0, x1) in enumerate(zip(ROOF_RIB_X_VALUES, ROOF_RIB_X_VALUES[1:]), start=1):
        for panel_index in range(0, len(pts) - 1, 2):
            p0 = pts[panel_index]
            p1 = pts[min(panel_index + 2, len(pts) - 1)]
            verts = [
                Vector((x0, p0.y, p0.z)),
                Vector((x1, p0.y, p0.z)),
                Vector((x1, p1.y, p1.z)),
                Vector((x0, p1.y, p1.z)),
            ]
            mesh_panel(f"GHI_roof_panel_bay{bay_index:02d}_{panel_index:02d}", verts, mat_panel)


def add_side_window_panels(mat_panel):
    x_pairs = list(zip(ROOF_RIB_X_VALUES, ROOF_RIB_X_VALUES[1:]))
    z_bands = [(0.58, 1.25), (1.25, 1.92), (1.92, 2.45)]

    for side_name, y in [("left", -GREENHOUSE_WIDTH / 2.0 - 0.006), ("right", GREENHOUSE_WIDTH / 2.0 + 0.006)]:
        for bay_index, (x0, x1) in enumerate(x_pairs, start=1):
            x_mid = (x0 + x1) * 0.5
            x_size = abs(x1 - x0) - 0.10
            for z_index, (z0, z1) in enumerate(z_bands, start=1):
                z_mid = (z0 + z1) * 0.5
                z_size = abs(z1 - z0) - 0.04
                cube(
                    f"GHI_window_panel_{side_name}_bay{bay_index:02d}_z{z_index}",
                    (x_mid, y, z_mid),
                    (x_size, 0.018, z_size),
                    mat_panel,
                )


def add_end_window_panels(mat_panel):
    y_edges = [-2.35, -1.18, 0.0, 1.18, 2.35]
    z_bands = [(0.58, 1.35), (1.35, 2.20)]

    for end_name, x in [("rear", -GREENHOUSE_LENGTH / 2.0 - 0.006), ("front", GREENHOUSE_LENGTH / 2.0 + 0.006)]:
        for bay_index, (y0, y1) in enumerate(zip(y_edges, y_edges[1:]), start=1):
            y_mid = (y0 + y1) * 0.5
            y_size = abs(y1 - y0) - 0.08
            for z_index, (z0, z1) in enumerate(z_bands, start=1):
                z_mid = (z0 + z1) * 0.5
                z_size = abs(z1 - z0) - 0.05
                cube(
                    f"GHI_end_panel_{end_name}_bay{bay_index:02d}_z{z_index}",
                    (x, y_mid, z_mid),
                    (0.018, y_size, z_size),
                    mat_panel,
                )


def add_panels() -> None:
    clear_old_panels()
    mat_panel = make_mat("clear_green_polycarbonate_panels", (0.62, 0.92, 0.74, 0.34), 0.16, 0.34)
    add_roof_panels(mat_panel)
    add_side_window_panels(mat_panel)
    add_end_window_panels(mat_panel)


def main() -> None:
    if not BLEND_FILE.exists():
        raise FileNotFoundError(f"Run create_green_horizon_greenhouse.py first. Missing: {BLEND_FILE}")

    bpy.ops.wm.open_mainfile(filepath=str(BLEND_FILE))
    add_panels()
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_FILE))
    print(f"Added greenhouse roof/window panels: {BLEND_FILE}")


if __name__ == "__main__":
    main()
