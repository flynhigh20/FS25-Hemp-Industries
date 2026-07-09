# Next Local Test Plan

This is the quick plan for the next Thursday/Friday test session.

## Main Goal

Confirm two things:

1. FS25 loads the current mod package as version `0.2.4.0` with `descVersion="91"`.
2. Blender 4.2 LTS generates the greenhouse with the corrected curved roof and procedural materials.

## Best Windows Flow

Start here:

```text
tools/windows/green_horizon_test_menu.bat
```

Recommended order from the menu:

```text
1. Preflight check repo files
3. Package and install to FS25 mods folder
```

Then open FS25.

After FS25 has run, come back to the menu and run:

```text
4. Check FS25 log after running game
```

## FS25 Things To Confirm

In the FS25 mod list:

```text
Green Horizon Industries
Version: 0.2.4.0
```

In the construction menu:

```text
Construction > Production > Factories / Production Points
```

Look for:

```text
Hemp Greenhouse
```

## FS25 Things To Report Back

Send these results:

```text
Did mod show 0.2.4.0? yes/no
Did the log checker find Loaded 3 fill types from mod? yes/no
Did Hemp Greenhouse appear in Production Points? yes/no
Any warnings/errors from the log checker report?
```

If something fails, send the report created by:

```text
tools/windows/check_fs25_log.bat
```

## Blender 4.2 Test

Use Blender 4.2 LTS.

Run:

```text
tools/blender/create_green_horizon_greenhouse.py
```

Expected save:

```text
assets/blender/green_horizon_hemp_greenhouse.blend
```

Check:

```text
roof is curved
roof is not flipped
roof is not floating as a flat panel
slab sits flat on grid
materials show in Material Preview or Rendered view
no top/front signs
```

## Optional Blender Helper Test

Only after the greenhouse shape looks good, run:

```text
tools/blender/add_giants_editor_helpers.py
```

Expected save:

```text
assets/blender/green_horizon_hemp_greenhouse_giants_helpers.blend
```

Check:

```text
collection exists: GHI_GIANTS_EDITOR_HELPERS
player trigger is near front door
water/seed unload markers are on the service side/back
pallet spawn area is visible
collision placeholder surrounds greenhouse footprint
```

## Stop Points

Stop and send results if:

```text
FS25 does not show 0.2.4.0
FS25 log has Invalid category, Invalid placeable, Invalid store item, or Can't load resource
Hemp Greenhouse still does not appear
Blender roof is still wrong
Blender script errors
```

## Do Not Do Yet

Do not export the greenhouse to `.i3d` until the Blender shape is approved.

Do not upload GIANTS base-game assets to the repo.
