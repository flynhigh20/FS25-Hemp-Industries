# Green Horizon Industries Asset Generation Workflow

## Goal

This workflow lets one Windows menu generate every project-owned Blender source asset, keep inactive expansion work separated from gameplay XML, validate the manually exported greenhouse, and block packaging when the old placeholder model is still present.

## Start Here

Open:

```text
tools/windows/green_horizon_test_menu.bat
```

The most useful new options are:

```text
 9  Generate greenhouse model and materials
10  Generate field foliage, icons, and cutter assets
11  Generate product pallet source assets
12  Generate ALL Blender source assets
13  Validate exported greenhouse i3d
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

It verifies the generated blend file and all greenhouse material textures.

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

2. Use Material Preview and confirm the peaked glass roof, frame, slab, grow beds, plants, tank, control box, lights, and doorway look correct.
3. Select/export the root:

```text
greenHorizonHempGreenhouse
```

4. Save directly to:

```text
FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d
```

5. Choose:

```text
Save relative paths: Yes
Save game paths: No
```

6. Open that i3d in GIANTS Editor.
7. Inspect the scene, materials, collisions, and helper nodes.
8. Save over the same i3d.
9. Confirm this file sits beside it:

```text
greenHorizonHempGreenhouse.i3d.shapes
```

## Strict Export Validation

Run menu option `13` after the manual export.

The validator checks:

- The i3d and shapes files exist and contain real data.
- The old Phase 2.6 placeholder markers are gone.
- No absolute Windows or `file:///` paths are embedded.
- The expected greenhouse root and gameplay helper nodes were exported.
- The export contains a reasonable number of shapes, materials, and file references.
- Most or all generated greenhouse textures are referenced.

Packaging is now blocked automatically when this validator fails. This prevents accidentally installing the empty placeholder greenhouse.

## Recommended Working Order

```text
1. Pull latest repository files.
2. Run menu option 15 to see the current next action.
3. Run option 12 once to generate all source assets.
4. Inspect and manually export the greenhouse.
5. Run option 13 to validate the export.
6. Run option 1 for the full repository preflight.
7. Run option 3 to package and install the clean ZIP.
8. Start FS25 and test the greenhouse.
9. Run option 4 to inspect the filtered game log.
10. Run option 15 again to see what remains.
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
