# Green Horizon Industries — FS25 Hemp Expansion

🚧 Alpha Development  
🖥️ PC test target  
🎮 Console/crossplay design goal  
🌱 Industrial hemp greenhouse, field crop, products, and processing

## Current Build

```text
0.2.18.0
```

The active mod folder and final zip root are:

```text
FS25_GreenHorizonIndustries/
```

The **Hemp Greenhouse** remains the only active placeable under test. Field-crop registration, crop icons, cutter effects, custom product pallets, and the processing facility are prepared but intentionally inactive.

## Active Test Scope

- Six registered fill types:
  - `HEMP`
  - `GHI_HEMP_SEED`
  - `GHI_HEMP_BIOMASS`
  - `GHI_HEMP_FIBER`
  - `GHI_HEMP_FLOWER`
  - `GHI_HEMP_OIL`
- Hemp Greenhouse placeable XML.
- Water-only and water-plus-seed greenhouse recipes.
- Peaked glass gable-roof greenhouse Blender generator.
- Script-generated greenhouse material textures.
- Deterministic helper hierarchy for placement, storage, triggers, plant nodes, and collisions.
- Windows preflight, package/install, log, field-foundation, source-generation, export-validation, and project-status tools.

## Prepared but Inactive Expansion Work

### Field Hemp and Foliage

- Expanded `fruitTypes.xml` draft.
- Twelve-period seasonal growth calendar.
- Nine foliage states from emerged through cut.
- Blender foliage source generator with near and distance cards.
- Map-registration contract synchronizing four channels and states 7, 8, and 9.
- Map, density-channel, destruction, vehicle, save/reload, and multiplayer gates.

### Crop and Product Icons

- Transparent source-icon generator for all six fill types.
- Dedicated crop-menu and crop-calendar icons.
- An icon manifest that keeps every icon unlinked until the exact FS25 XML keys and final image formats are verified.

### Cutter Effects

- Source generator for hemp chaff, stem shards, leaf fragments, and dust.
- Mature-state harvesting route from state 7 to cut state 9.
- Initial combine-style profile and future forage/biomass profile.
- Particle budgets and console-performance targets.

### Product Pallets

- Six inactive pallet XML templates.
- One Blender generator for hemp, seed, biomass, fiber, flower, and oil pallets.
- Export-oriented helper nodes for fill units, discharge, dynamic mounting, collisions, and tension belts.
- Script-generated pallet material textures.

### Hemp Processing

Inactive recipe foundations are prepared for decortication, flower sorting, seed cleaning, and cold-pressed hemp oil.

Nothing in these inactive sections is registered through `modDesc.xml` yet.

## Blender Scripts

```text
tools/blender/create_green_horizon_greenhouse.py
tools/blender/create_hemp_foliage.py
tools/blender/create_hemp_crop_icons.py
tools/blender/create_hemp_cutter_effects.py
tools/blender/create_green_horizon_pallets.py
```

Detailed Blender instructions:

```text
tools/blender/README.md
```

## One-Command Windows Workflow

Open:

```text
tools/windows/green_horizon_test_menu.bat
```

Useful workflow options:

```text
 9  Generate greenhouse model and materials
10  Generate field foliage, icons, and cutter assets
11  Generate product pallet source assets
12  Generate ALL Blender source assets
13  Validate exported greenhouse i3d
14  Open asset generation workflow
15  Show project status and next action
```

The generator pipeline automatically finds Blender, runs the selected scripts in background mode, verifies their expected outputs, and stores logs under:

```text
build/logs/blender/
```

Full workflow guide:

```text
docs/Asset-Generation-Workflow.md
```

## Export Protection

The repository can still contain the old tiny placeholder i3d until the real greenhouse is exported. Packaging now calls a strict validator and refuses to create/install the ZIP when:

- The i3d or shapes file is missing.
- Placeholder markers remain.
- Required helper nodes are absent.
- Absolute Windows paths were embedded.
- The export contains too few shapes, materials, or texture references.

Validator:

```text
tools/windows/validate_greenhouse_export.bat
```

## Other Windows Checks

Field-hemp cross-file validator:

```text
tools/windows/check_hemp_field_foundation.bat
```

Direct package/install helper:

```text
tools/windows/package_and_install_mod.bat
```

Filtered log helper:

```text
tools/windows/check_fs25_log.bat
```

## Recommended Test Order

```text
1. Pull latest repository files.
2. Run menu option 15 to see the next action.
3. Run option 12 to generate all current source assets.
4. Open and inspect the generated greenhouse blend.
5. Export greenHorizonHempGreenhouse to the mod i3d folder.
6. Use relative paths Yes and game paths No.
7. Open/save the export in GIANTS Editor.
8. Run option 13 to validate the export.
9. Run option 1 for full preflight.
10. Run option 3 to package and install.
11. Start FS25 and test the greenhouse.
12. Run option 4 to inspect the filtered game log.
```

## Immediate Test Goal

Confirm FS25 shows:

```text
Green Horizon Industries 0.2.18.0
```

Then confirm the greenhouse appears, places correctly, remains walkable, loads its materials, exposes its triggers and recipes, and produces no missing i3d, shapes, texture, mapping, or fill-type errors.

## Important Inactive Files

```text
FS25_GreenHorizonIndustries/xml/fruitTypes.xml
FS25_GreenHorizonIndustries/xml/growth/hempGrowth.xml
FS25_GreenHorizonIndustries/xml/productions/hempProcessingRecipes.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempFoliagePlan.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempFieldIntegrationPlan.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempMapRegistrationDraft.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempCutterEffectsPlan.xml
FS25_GreenHorizonIndustries/ui/hempIconManifest.xml
FS25_GreenHorizonIndustries/pallets/xml/*.xml
```

These files are packaged as development foundations but are not loaded by the active mod descriptor.

## Future Mod Concept Saved

The separate **Contractor Equipment Rental Yard** concept is documented in:

```text
docs/Future-Mods.md
```

## Development Rule

Do not upload GIANTS base-game files or extracted game assets to this repository. Base-game files may be used locally as references only.
