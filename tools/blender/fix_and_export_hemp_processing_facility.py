import bpy
from pathlib import Path


ROOT = Path(r"C:\Users\user\Desktop\FS25-Hemp-Industries-main")
OUTPUT = ROOT / "FS25_GreenHorizonIndustries" / "placeables" / "productions" / "i3d" / "greenHorizonHempProcessingFacility.i3d"


def configure_physics(obj, *, static=False, kinematic=False, compound=False,
                      trigger=False, group="255", mask="255"):
    obj["i3D_static"] = static
    obj["i3D_kinematic"] = kinematic
    obj["i3D_compound"] = compound
    obj["i3D_trigger"] = trigger
    obj["i3D_collision"] = True
    obj["i3D_cpuMesh"] = True
    obj["i3D_nonRenderable"] = True
    obj["i3D_collisionFilterGroup"] = group
    obj["i3D_collisionFilterMask"] = mask
    obj.hide_render = True
    obj.display_type = "WIRE"


def remove_object(name):
    obj = bpy.data.objects.get(name)
    if obj is not None:
        bpy.data.objects.remove(obj, do_unlink=True)


def add_box(name, location, size, material, parent):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    obj.parent = parent
    return obj


visuals = bpy.data.objects["visuals"]
collisions = bpy.data.objects["collisions"]
game_nodes = bpy.data.objects["facilityGameNodes"]
panel = bpy.data.materials["GHI_LightMetalPanel"]
concrete = bpy.data.materials["GHI_Concrete"]

# Preserve the original factory wall geometry. Door animation helpers must not
# alter the accepted model silhouette or create gaps around the front panels.
for obsolete_name in (
    "frontWallDoorTop",
    "frontWallFarRight",
    "collisionFrontDoorTop",
    "collisionFrontFarRight",
):
    remove_object(obsolete_name)
if bpy.data.objects.get("frontWallRight") is None:
    add_box("frontWallRight", (4.55, -4.0, 2.0), (2.9, 0.16, 4.0), panel, visuals)
if bpy.data.objects.get("collisionFrontRight") is None:
    add_box("collisionFrontRight", (4.55, -4.0, 2.0), (2.9, 0.18, 4.0), concrete, collisions)

# Animated physical door panels.
personnel_collision = bpy.data.objects.get("collisionPersonnelDoor")
if personnel_collision is None:
    personnel_collision = add_box("collisionPersonnelDoor", (4.45, -4.0, 1.15), (1.25, 0.18, 2.30), concrete, collisions)
rollup_collision = bpy.data.objects.get("collisionRollupDoor")
if rollup_collision is None:
    rollup_collision = add_box("collisionRollupDoor", (0.9, -4.0, 1.75), (4.35, 0.18, 3.45), concrete, collisions)

# Separate hand-tool trigger for each factory door.
personnel_trigger = bpy.data.objects.get("personnelDoorTrigger")
if personnel_trigger is None:
    personnel_trigger = add_box("personnelDoorTrigger", (4.45, -5.0, 1.0), (1.7, 0.65, 2.0), concrete, game_nodes)
rollup_trigger = bpy.data.objects.get("rollupDoorTrigger")
if rollup_trigger is None:
    rollup_trigger = add_box("rollupDoorTrigger", (0.9, -5.0, 1.0), (4.6, 0.65, 2.0), concrete, game_nodes)


configure_physics(
    bpy.data.objects["playerTrigger"],
    static=True,
    trigger=True,
    group="536870912",
    mask="1048576",
)
for trigger_obj in (personnel_trigger, rollup_trigger):
    configure_physics(
        trigger_obj,
        static=True,
        trigger=True,
        group="536870912",
        mask="1048576",
    )
configure_physics(
    bpy.data.objects["unloadTrigger"],
    kinematic=True,
    compound=True,
    group="1073741824",
    mask="536870912",
)

for name in (
    "collisionFrontLeft",
    "collisionFrontRight",
    "collisionLeft",
    "collisionRear",
    "collisionRight",
):
    configure_physics(
        bpy.data.objects[name],
        static=True,
        group="4148",
        mask="4294966271",
    )

for moving_collision in (personnel_collision, rollup_collision):
    configure_physics(
        moving_collision,
        kinematic=True,
        group="62",
        mask="4294966271",
    )

bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)

settings = bpy.context.scene.I3D_UIexportSettings
settings.i3D_exportUseSoftwareFileName = False
settings.i3D_exportFileLocation = str(OUTPUT)
settings.i3D_exportRelativePaths = True
bpy.ops.i3d.panelexport_buttonexport(state=1)

print(f"Exported corrected processing facility to {OUTPUT}")
