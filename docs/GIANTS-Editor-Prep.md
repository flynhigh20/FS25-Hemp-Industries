# GIANTS Editor Export and Validation

## Current Status

The active greenhouse XML already points to the project-owned model path:

```text
FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d
```

The repository may still contain the small Phase 2.6 placeholder i3d until a fresh Blender/GIANTS export overwrites it. Packaging now refuses to continue when that placeholder or an incomplete export is detected.

## Source Model

Use Blender 4.2 LTS and generate the latest source with either:

```text
tools/windows/green_horizon_test_menu.bat
Option 9 - Generate greenhouse model and materials
```

or run:

```text
tools/blender/create_green_horizon_greenhouse.py
```

The generated source file is:

```text
assets/blender/green_horizon_hemp_greenhouse.blend
```

The main script already creates the model, materials, placement areas, triggers, storage nodes, plant nodes, spawn area, collision objects, and visual hierarchy. No separate helper or post-export patch script is used.

## Expected Root and Helper Nodes

Export the sole root:

```text
greenHorizonHempGreenhouse
```

Important child nodes include:

```text
clearAreaStart01
levelAreaStart01
indoorArea01Start
testAreaStart01
plantNodes
palletSpawner
sellingStation
exactFillRootNode
storage
playerTrigger
infoTrigger
collisions
visuals
```

The placeable XML mappings depend on these names and the deterministic hierarchy created by the Blender script.

## Before Exporting

Confirm in Blender Material Preview:

- The concrete slab sits flat on the grid.
- The greenhouse has a straight peaked glass gable roof.
- The ridge, rafters, purlins, and glazing are seated correctly.
- The center front doorway remains open.
- Grow beds, plants, water tank, control box, lights, and wiring are visible.
- Transparent glass and leaf materials display correctly.
- No preview camera or light is under the exported root.

## Blender to i3d Export

1. Select the root `greenHorizonHempGreenhouse`.
2. Export that root and all of its children.
3. Save directly to:

```text
FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d
```

4. Choose:

```text
Save relative paths: Yes
Save game paths: No
```

5. Confirm the exporter also creates:

```text
greenHorizonHempGreenhouse.i3d.shapes
```

## GIANTS Editor Pass

Open the exported i3d in GIANTS Editor and inspect:

- Model orientation and scale.
- Peaked roof and glass materials.
- Texture paths.
- Perimeter collisions.
- Open front doorway.
- Trigger and helper-node locations.
- Scenegraph node names.

Save over the same i3d after inspection.

## Export Validator

Run:

```text
tools/windows/validate_greenhouse_export.bat
```

or menu option `13`.

The validator blocks the package when:

- The i3d or shapes file is missing.
- The file is still the placeholder.
- Absolute Windows paths were embedded.
- Required helper nodes are missing.
- Too few shapes, materials, or file references were exported.
- Generated greenhouse textures are not referenced.

## Packaging and Game Test

After validation passes:

```text
1. Run menu option 1 for full preflight.
2. Run menu option 3 to package and install.
3. Start FS25.
4. Confirm Green Horizon Industries loads.
5. Place the Hemp Greenhouse.
6. Test walking, collisions, triggers, unloading, and recipes.
7. Run menu option 4 to inspect the game log.
```

## Do Not Upload Base-Game Assets

Original project scripts, XML, Blender sources, textures, and exports are allowed. Do not commit copied GIANTS base-game meshes, textures, i3d files, or full extracted XML files. Base-game content may be used locally as a schema and layout reference only.
