# FS25 / Blender Test Checklist

Use this after pulling the latest repo.

## 0. Start From The Windows Test Menu

Preferred helper menu:

```text
tools/windows/green_horizon_test_menu.bat
```

Recommended order:

```text
1. Preflight check repo files
3. Package and install to FS25 mods folder
4. Check FS25 log after running game
```

## 1. Preflight Check

Before packaging, run from the menu or double-click:

```text
tools/windows/preflight_check.bat
```

This checks:

```text
modDesc.xml parses
mod version is 0.2.5.0
descVersion is 91
store item target exists
fillTypes target exists
greenhouse category is productionPoints
zip root is correct if dist zip exists
```

## 2. Package the Mod

Preferred Windows test method:

```text
tools/windows/package_and_install_mod.bat
```

This builds and installs the zip into the default FS25 mods folder. It also removes old loose mod folders and old zips for the Green Horizon test names.

If you only want to create the zip:

```text
tools/windows/package_mod.bat
```

Expected zip:

```text
dist/FS25_GreenHorizonIndustries.zip
```

Open the zip and confirm this is true:

```text
modDesc.xml is visible immediately at the top of the zip
```

## 3. Start FS25

In the mod list, confirm the current version is visible:

```text
0.2.5.0
```

If FS25 still shows `0.2.2.0`, `0.2.3.0`, or `0.2.4.0`, an old zip or loose folder is still being loaded.

Current descriptor test value:

```text
descVersion="91"
```

## 4. Confirm Phase 1 Still Works

Search the FS25 log for:

```text
Loaded 3 fill types from mod
```

Easy Windows option:

```text
tools/windows/check_fs25_log.bat
```

This creates a filtered report from the FS25 log so you do not have to scroll the whole file.

## 5. Check Greenhouse Visibility

Look in the construction menu, not the vehicle/equipment store:

```text
Construction > Production > Factories / Production Points
```

Expected store item name:

```text
Hemp Greenhouse
```

Note: the current active XML is still a `productionPoint` shell. A true greenhouse tab/category test probably needs the later `PlaceableGreenhouse` / greenhouse plant schema instead of only changing the store category text.

## 6. If It Does Not Show

Run:

```text
tools/windows/check_fs25_log.bat
```

Or manually search the FS25 log for these exact strings:

```text
FS25_GreenHorizonIndustries
placeables/greenhouses/hempGreenhouse.xml
storeItem_ghi_hempGreenhouse
production_ghi_hempGreenhouseBasic
Invalid store item
Invalid placeable
Unknown category
Invalid category
No categories defined
Can't load resource
```

Copy the matching log section or the generated report for debugging.

## 7. Blender Greenhouse Test

Use Blender 4.2 LTS for the current FS25/GIANTS workflow.

Run:

```text
tools/blender/create_green_horizon_greenhouse.py
```

Expected output:

```text
assets/blender/green_horizon_hemp_greenhouse.blend
```

Visual checks:

- Slab sits flat on the Blender grid.
- Roof uses the restored tall original arch/rib shape.
- Ribs are adjustable from constants near the top of the script.
- Roof is not flipped into the building.
- No top/front signs are present.
- Materials show in Material Preview or Rendered view.

## 8. Optional GIANTS Helper Marker Test

Only run this after the greenhouse shape looks right:

```text
tools/blender/add_giants_editor_helpers.py
```

Expected output:

```text
assets/blender/green_horizon_hemp_greenhouse_giants_helpers.blend
```

Visual checks:

- New collection exists: `GHI_GIANTS_EDITOR_HELPERS`.
- Collision placeholder surrounds the greenhouse footprint.
- Player trigger is near the front door.
- Water and seed unload markers are on the side/back service area.
- Pallet spawn area is visible and not inside the grow beds.
- Helper labels/placeholders are understood as layout markers, not final visible game signs.

## 9. Blender Pallet Test

Run:

```text
tools/blender/create_green_horizon_pallets.py
```

Expected output:

```text
assets/blender/green_horizon_product_pallets.blend
```

Visual checks:

- Front labels are readable.
- No top pallet signs are present.
- Materials show in Material Preview or Rendered view.

## 10. GIANTS Editor Prep

Do not export to `.i3d` until the Blender model shape is approved.

After the model looks right, the next step is:

```text
Blender 4.2 LTS -> GIANTS Exporter -> .i3d -> connect i3d in hempGreenhouse.xml
```

Do not upload GIANTS base-game files or extracted assets to this repository.
