# Green Horizon Industries — FS25 Hemp Expansion

🚧 Alpha development  
🖥️ PC test target  
🎮 Console/crossplay design goal  
🌱 Industrial hemp greenhouse, field crop, products, and processing

## Current Build

```text
0.2.18.0
```

The active mod folder and ZIP root are:

```text
FS25_GreenHorizonIndustries/
```

The **Hemp Greenhouse** is the only active placeable under test. Field-crop registration, crop icons, cutter effects, custom product pallets, and the processing facility remain prepared but intentionally inactive.

## Current Progress

The greenhouse now appears in the FS25 **Greenhouses** category. The current model includes:

- A straight peaked glass gable roof.
- Black powder-coated framing.
- Front and rear roof overhangs.
- A centered double entrance with the top raised to approximately `2.53 m`.
- A concrete slab and perimeter curbs.
- Three grow beds with irrigation.
- Static hemp plants for the current visual test.
- A water tank and nutrient-control box.
- Warm grow lights with conduit and junction boxes.
- Placement, clear-area, level-area, indoor-area, test-area, collision, storage, pallet-spawn, player-trigger, and unload-trigger helpers.

The latest local Blender/I3D export still needs to be merged from the user's main working copy before the repository model is considered final.

## Temporary Seed Booster Test

For the current gameplay test, use the base-game generic seed fill type:

```xml
<input fillType="SEEDS" amount="4"/>
```

This allows ordinary base-game seed bags, pallets, and seed tenders to supply the greenhouse.

`GHI_HEMP_SEED` remains registered for the later custom hemp-seed pallet and production chain. Once that pallet is exported and activated, the greenhouse booster can be switched back to:

```xml
<input fillType="GHI_HEMP_SEED" amount="4"/>
```

## Main Local Working Folder

The user's current local project is:

```text
C:\Users\user\Desktop\FS25-Hemp-Industries-main
```

GitHub cannot automatically inspect uncommitted files on that computer. Local model, XML, and shapes changes must be uploaded or committed before they can be merged safely.

## Recommended Test Workflow

```text
1. Pull the latest repository files.
2. Open tools/windows/green_horizon_test_menu.bat.
3. Run option 9 only when the greenhouse Blender source must be regenerated.
4. Open assets/blender/green_horizon_hemp_greenhouse.blend.
5. Inspect the roof, 2.53 m doorway, materials, beds, lights, and triggers.
6. Export greenHorizonHempGreenhouse directly to:
   FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/
   greenHorizonHempGreenhouse.i3d
7. Keep the generated .i3d.shapes file beside the i3d.
8. Run option 13 to normalize shapes/texture references and validate the export.
9. Open and save the same i3d in GIANTS Editor.
10. Run option 13 again.
11. Run option 1 for the full preflight check.
12. Run option 3 to package, clean old installs, and install the verified ZIP.
13. Confirm the mods folder contains only the intended Green Horizon ZIP.
14. Start FS25 and test the greenhouse.
15. Run option 4 afterward to inspect the filtered game log.
```

Do not leave old loose folders or legacy packages in the FS25 mods folder. The package installer removes these known conflicts:

```text
FS25_GreenHorizonIndustries
FS25_GreenHorizonIndustries.zip
FS25_Hemp_Industries
FS25_Hemp_Industries.zip
greenHorizonHempGreenhouse
greenHorizonHempGreenhouse.zip
```

## Current Validation Targets

A successful test should confirm:

- The mod and greenhouse XML files load from the installed package.
- The greenhouse appears in the Greenhouses category.
- The `.i3d.shapes` reference matches the actual shapes filename.
- No I3D mapping reports an invalid child index.
- Water and generic `SEEDS` unload correctly.
- Both greenhouse recipes run and produce outputs.
- Placement, leveling, walking access, collisions, and triggers behave correctly.
- No missing I3D, shapes, texture, fill-type, or placeable XML errors remain.

The `greenhouse_light_diffuse.png` CPU mip-generation message is currently a warning rather than a load failure. Final game textures should be converted to suitable mipmapped DDS files after the gameplay model is stable.

## Active Test Scope

- Registered fill types:
  - `HEMP`
  - `GHI_HEMP_SEED`
  - `GHI_HEMP_BIOMASS`
  - `GHI_HEMP_FIBER`
  - `GHI_HEMP_FLOWER`
  - `GHI_HEMP_OIL`
- Hemp Greenhouse placeable XML.
- Water-only and seed-boosted greenhouse recipes.
- Peaked glass greenhouse Blender generator.
- Script-generated greenhouse textures.
- Deterministic gameplay-helper hierarchy.
- Windows source generation, export repair, validation, packaging, installation, and log tools.

## Prepared but Inactive Work

### Field Hemp

- Expanded fruit-type draft.
- Twelve-period seasonal growth calendar.
- Nine foliage states from emerged through cut.
- Near and distance foliage source generation.
- Four-channel map-registration contract.

### Icons and Cutter Effects

- Source icons for all custom fill types.
- Crop-menu and crop-calendar icon concepts.
- Hemp chaff, stem-shard, leaf-fragment, and dust source textures.

### Product Pallets

- Inactive XML templates for hemp, seed, biomass, fiber, flower, and oil pallets.
- Blender pallet generator and helper hierarchy.
- The custom seed pallet is not store-active yet.

### Processing

Inactive recipe foundations exist for decortication, flower sorting, seed cleaning, and cold-pressed hemp oil.

None of these inactive systems should be linked through `modDesc.xml` until their models and FS25 behavior are verified.

## Main Tools

```text
tools/blender/create_green_horizon_greenhouse.py
tools/blender/create_hemp_foliage.py
tools/blender/create_hemp_crop_icons.py
tools/blender/create_hemp_cutter_effects.py
tools/blender/create_green_horizon_pallets.py
```

```text
tools/windows/green_horizon_test_menu.bat
tools/windows/validate_greenhouse_export.bat
tools/windows/package_and_install_mod.bat
tools/windows/verify_installed_mod.bat
tools/windows/check_fs25_log.bat
```

Detailed workflow documentation:

```text
docs/Asset-Generation-Workflow.md
tools/blender/README.md
TODO.md
```

## Development Rule

Do not upload GIANTS base-game files or extracted game assets to this repository. Base-game and third-party assets may be used locally as references only unless their license explicitly permits redistribution.
