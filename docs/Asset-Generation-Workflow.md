# Green Horizon Industries Asset Generation Workflow

## Goal

This workflow lets one Windows menu generate every project-owned Blender source asset, keep inactive expansion work separated from gameplay XML, repair malformed texture paths after export, validate the greenhouse, and block packaging when the old placeholder or an incomplete model is still present.

## Start Here

Open:

```text
tools/windows/green_horizon_test_menu.bat
```

The most useful options are:

```text
 9  Generate greenhouse model and materials
10  Generate field foliage, icons, and cutter assets
11  Generate product pallet source assets
12  Generate ALL Blender source assets
13  Repair texture paths and validate greenhouse i3d
14  Open this workflow
15  Show project status and next action
```

## Blender Detection

The generation pipeline looks for Blender in this order:

1. `blender.exe` available through Windows PATH.
2. Blender 4.2 under the normal Program Files location.
3. Blender 4.2 under Local AppData.
4. Another installed Blender version under the Blender Foundation folders.

Blender 4.2 LTS remains the tested target. Another detected version produces a warning but the generator still attempts to run.

Advanced direct usage:

```powershell
powershell -ExecutionPolicy Bypass -File tools/windows/generate_project_assets.ps1 -Target all
```

With an explicit Blender path:

```powershell
powershell -ExecutionPolicy Bypass -File tools/windows/generate_project_assets.ps1 `
  -Target all `
  -BlenderExe "C:\Program Files\Blender Foundation\Blender 4.2\blender.exe"
```

## Generation Targets

### Greenhouse

Menu option `9` runs:

```text
tools/blender/create_green_horizon_greenhouse.py
```

It verifies the generated blend file and all greenhouse material textures. The current entrance top is `2.53 m`, and the generated blend stores texture paths relative to its own location.

### Field Assets

Menu option `10` runs these in order:

```text
tools/blender/create_hemp_foliage.py
tools/blender/create_hemp_crop_icons.py
tools/blender/create_hemp_cutter_effects.py
```

It verifies:

- The nine-state foliage source blend.
- Near and distance foliage textures.
- Six fill-type icons.
- Crop and calendar icons.
- Chaff, stem-shard, leaf-fragment, and dust textures.
- The cutter-effect preview blend.

All of these files remain inactive after generation.

### Product Pallets

Menu option `11` runs:

```text
tools/blender/create_green_horizon_pallets.py
```

It verifies the combined pallet blend and the first required pallet material textures. Individual pallet i3d exports remain later manual work.

### Everything

Menu option `12` runs greenhouse, field, and pallet generators in one pass.

Blender runs in background mode using a clean factory startup. Generator output is written to:

```text
build/logs/blender/
```

A failed generator stops the sequence and names the log file to inspect.

## Greenhouse Manual Export

The source generation can be automated, but the GIANTS i3d export still requires the installed GIANTS Blender exporter and visual inspection.

After option `9` or `12` succeeds:

1. Open:

```text
assets/blender/green_horizon_hemp_greenhouse.blend
```

2. Use Material Preview and confirm the peaked glass roof, frame, slab, grow beds, plants, tank, control box, lights, doorway, and trigger pads look correct.
3. Select/export the root:

```text
greenHorizonHempGreenhouse
```

4. Save **directly** to this exact path:

```text
FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d
```

Do not export into `assets/blender` and move the files afterward.

5. Choose:

```text
Save relative paths: Yes
Save game paths: No
```

6. Confirm this file sits beside the i3d:

```text
greenHorizonHempGreenhouse.i3d.shapes
```

7. Before opening GIANTS Editor, run menu option `13`.
8. Option `13` normalizes every known greenhouse texture path to:

```text
../textures/<texture filename>
```

For example:

```xml
<File fileId="14" filename="../textures/greenhouse_light_diffuse.png"/>
```

9. After option `13` passes, open that exact i3d in GIANTS Editor.
10. Inspect the scene, materials, collisions, trigger nodes, and helper hierarchy.
11. Save over the same i3d.
12. Run option `13` again to confirm GIANTS Editor did not alter or remove the corrected references.

## Texture-Path Recovery

A malformed path such as:

```text
../placeables/greenhouses/i3d/../FS25_GreenHorizonIndustries/placeables/greenhouses/textures/greenhouse_light_diffuse.png
```

is automatically rewritten by option `13` to:

```text
../textures/greenhouse_light_diffuse.png
```

The repair tool creates this backup before changing the i3d:

```text
greenHorizonHempGreenhouse.i3d.pathfix.bak
```

When an i3d has already been saved in GIANTS Editor after all texture references were lost, re-export from the corrected Blender file. A path repair cannot restore `<File>` entries that no longer exist.

## Strict Export Validation

Option `13` repairs known greenhouse texture paths first, then checks:

- The i3d and shapes files exist and contain real data.
- The old placeholder markers are gone.
- No absolute Windows or `file:///` paths are embedded.
- No duplicated `FS25_GreenHorizonIndustries` path remains.
- The expected greenhouse root and gameplay helper nodes were exported.
- The export contains a reasonable number of shapes, materials, and file references.
- Most or all generated greenhouse textures use `../textures/<filename>`.

Packaging is blocked automatically when this validator fails.

## Recommended Working Order

```text
1. Pull latest repository files.
2. Run menu option 15 to see the current next action.
3. Run option 9 for the greenhouse, or option 12 for all source assets.
4. Inspect the generated greenhouse blend.
5. Export directly into the mod's greenhouse i3d folder.
6. Run option 13 to repair paths and validate before GIANTS Editor.
7. Open/save the same i3d in GIANTS Editor.
8. Run option 13 again.
9. Run option 1 for the full repository preflight.
10. Run option 3 to package and install the clean ZIP.
11. Start FS25 and test the greenhouse.
12. Run option 4 to inspect the filtered game log.
```

## What Remains Inactive

Generating assets does not activate any of these systems:

```text
field hemp fruit registration
map foliage and density-map integration
crop and product icon links
cutter effects on vehicles
custom product pallet links
hemp processing recipes
```

Those links stay excluded until their exact FS25 XML schema, model nodes, vehicle workflow, and test-map behavior are verified.
