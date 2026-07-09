# FS25 / Blender Test Checklist

Use this after pulling the latest repo.

## 1. Package the Mod

Preferred Windows test method:

```text
tools/windows/package_and_install_mod.bat
```

This builds and installs the zip into the default FS25 mods folder.

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

## 2. Start FS25

In the mod list, confirm the current version is visible:

```text
0.2.4.0
```

Current descriptor test value:

```text
descVersion="91"
```

## 3. Confirm Phase 1 Still Works

Search the FS25 log for:

```text
Loaded 3 fill types from mod
```

Easy Windows option:

```text
tools/windows/check_fs25_log.bat
```

This creates a filtered report from the FS25 log so you do not have to scroll the whole file.

## 4. Check Greenhouse Visibility

Look in the construction menu, not the vehicle/equipment store:

```text
Construction > Production > Factories / Production Points
```

Expected store item name:

```text
Hemp Greenhouse
```

## 5. If It Does Not Show

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

## 6. Blender Greenhouse Test

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
- Roof is curved, not flat.
- Roof sits on the wall tops.
- Roof is not flipped into the building.
- No top/front signs are present.
- Materials show in Material Preview or Rendered view.

## 7. Optional GIANTS Helper Marker Test

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

## 8. Blender Pallet Test

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

## 9. GIANTS Editor Prep

Do not export to `.i3d` until the Blender model shape is approved.

After the model looks right, the next step is:

```text
Blender 4.2 LTS -> GIANTS Exporter -> .i3d -> connect i3d in hempGreenhouse.xml
```

Do not upload GIANTS base-game files or extracted assets to this repository.
