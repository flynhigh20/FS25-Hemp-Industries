"""Prepare the existing outdoor hemp foliage source for GIANTS I3D export.

Run this from Blender 4.2's Scripting workspace while
green_horizon_hemp_foliage.blend is open.  Unlike the full generator, this
script does not rebuild any PNG atlases; it only fixes the field origins and
saves the existing source.
"""

from pathlib import Path

import bpy


REPO_ROOT = Path(r"C:\Users\user\Desktop\FS25-Hemp-Industries")
BLEND_FILE = REPO_ROOT / "assets" / "blender" / "green_horizon_hemp_foliage.blend"


root = bpy.data.objects.get("hempFoliageSource")
if root is None:
    raise RuntimeError(
        "hempFoliageSource was not found. Open green_horizon_hemp_foliage.blend first."
    )

states = [
    obj
    for obj in bpy.data.objects
    if obj.name.startswith("growthState") and obj.parent == root
]
if len(states) != 9:
    raise RuntimeError(f"Expected 9 outdoor hemp growth states, found {len(states)}")

for state in states:
    # All foliage block shapes must share the field origin.  The old source
    # spread these objects along X for previewing the stages in Blender.
    state.location.x = 0.0
    state.location.y = 0.0

bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_FILE))

print("Prepared hemp foliage export: 9 states aligned at the field origin")
print(f"Saved: {BLEND_FILE}")
print("Select hempFoliageSource and export selected as foliage/hemp/hemp.i3d")
