import bpy
import math


def material(name, color):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.72
    return mat


def cube(name, location, scale, mat, parent):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    obj.parent = parent
    obj.matrix_parent_inverse = parent.matrix_world.inverted()
    obj["i3D_castsShadows"] = False
    obj["i3D_receiveShadows"] = True
    return obj


root = bpy.data.objects.get("greenHorizonHempGreenhouse")
spawner = bpy.data.objects.get("palletSpawner")
start = bpy.data.objects.get("spawnPlaceStart01")
end = bpy.data.objects.get("spawnPlaceEnd01")
marker = bpy.data.objects.get("warningStripes")

if not all((root, spawner, start, end, marker)):
    raise RuntimeError("Required greenhouse pallet-area nodes were not found")

# Put the entire pallet line outside the rear wall of the greenhouse.
spawner.location = (2.65, -3.75, 0.05)
start.location = (-1.5, 0.0, 0.0)
end.location = (3.0, 0.0, 0.0)

# Keep the visible marker centered on the actual Blender-side pallet spawner.
marker.location = (spawner.location.x, spawner.location.y, 0.018)

for obj in list(bpy.data.objects):
    if obj.name.startswith("GHI_PalletStripe"):
        bpy.data.objects.remove(obj, do_unlink=True)

black = material("GHI_WarningStripeBlack", (0.025, 0.025, 0.018))
yellow = material("GHI_WarningStripeYellow", (0.95, 0.62, 0.015))

# Thin ground backing, border, and alternating diagonal hazard bars.
cube("GHI_PalletStripeBase", marker.location, (1.55, 1.15, 0.006), black, marker)
for index, x in enumerate((-1.05, -0.70, -0.35, 0.0, 0.35, 0.70, 1.05), 1):
    bar = cube(
        f"GHI_PalletStripeYellow{index:02d}",
        (marker.location.x + x, marker.location.y, marker.location.z + 0.009),
        (0.10, 1.00, 0.004),
        yellow,
        marker,
    )
    bar.rotation_euler[2] = math.radians(32)

cube("GHI_PalletStripeBorderFront", (marker.location.x, marker.location.y - 1.10, marker.location.z + 0.011), (1.55, 0.045, 0.005), yellow, marker)
cube("GHI_PalletStripeBorderRear", (marker.location.x, marker.location.y + 1.10, marker.location.z + 0.011), (1.55, 0.045, 0.005), yellow, marker)
cube("GHI_PalletStripeBorderLeft", (marker.location.x - 1.50, marker.location.y, marker.location.z + 0.011), (0.045, 1.10, 0.005), yellow, marker)
cube("GHI_PalletStripeBorderRight", (marker.location.x + 1.50, marker.location.y, marker.location.z + 0.011), (0.045, 1.10, 0.005), yellow, marker)

bpy.context.scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print("Updated greenhouse pallet nodes and added visible warning stripes")
