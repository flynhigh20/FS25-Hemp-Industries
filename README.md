# Green Horizon Industries — FS25 Hemp Expansion

🚧 Alpha Development  
🖥️ PC test target  
🎮 Console/crossplay design goal  
🌱 Industrial hemp greenhouse, field crop, products, and processing

## Current Build

```text
0.2.17.0
```

The active mod folder and final zip root are:

```text
FS25_GreenHorizonIndustries/
```

The **Hemp Greenhouse** remains the only active placeable under test. Field-crop registration, custom product pallets, and the processing facility are prepared but intentionally inactive.

## Active Test Scope

- Six registered fill types:
  - `HEMP`
  - `GHI_HEMP_SEED`
  - `GHI_HEMP_BIOMASS`
  - `GHI_HEMP_FIBER`
  - `GHI_HEMP_FLOWER`
  - `GHI_HEMP_OIL`
- Hemp Greenhouse placeable XML.
- Two greenhouse recipes:
  - Water-only basic production.
  - Water and hemp-seed higher-yield production.
- Peaked glass gable-roof greenhouse Blender generator.
- Script-generated greenhouse material textures.
- Deterministic helper hierarchy for placement, storage, triggers, plant nodes, and collisions.
- Windows preflight, package/install, and log-check tools.

## Prepared but Inactive Expansion Work

### Field Hemp

- Expanded `fruitTypes.xml` draft.
- Twelve-period seasonal growth calendar.
- Nine foliage states from emerged through cut.
- Blender foliage source generator with near and distance cards.
- Map, density-channel, cutter, destruction, and vehicle-integration gates.

### Product Pallets

- Six inactive pallet XML templates.
- One Blender generator that creates:
  - Industrial hemp pallet.
  - Hemp seed pallet.
  - Hemp biomass pallet.
  - Hemp fiber pallet.
  - Hemp flower pallet.
  - Hemp oil pallet.
- Export-oriented helper nodes for fill units, discharge, dynamic mounting, collisions, and tension belts.
- Script-generated pallet material textures.

### Hemp Processing

Inactive recipe foundations are prepared for:

- Hemp decortication into fiber and biomass.
- Flower sorting.
- Seed cleaning.
- Cold-pressed hemp oil.

Nothing in these inactive sections is registered through `modDesc.xml` yet.

## Blender Scripts

```text
tools/blender/create_green_horizon_greenhouse.py
tools/blender/create_hemp_foliage.py
tools/blender/create_green_horizon_pallets.py
```

Detailed instructions:

```text
tools/blender/README.md
```

## Quick Windows Testing

Start with:

```text
tools/windows/green_horizon_test_menu.bat
```

Recommended order:

```text
1. Pull the latest repository files.
2. Run the greenhouse Blender generator.
3. Export and save the greenhouse i3d into the mod folder.
4. Run the preflight check.
5. Package and install the clean zip.
6. Start FS25 and test the placeable.
7. Run the filtered FS25 log checker.
```

Direct package/install helper:

```text
tools/windows/package_and_install_mod.bat
```

Filtered log helper:

```text
tools/windows/check_fs25_log.bat
```

## Immediate Test Goal

Confirm FS25 shows:

```text
Green Horizon Industries 0.2.17.0
```

Then confirm:

- The mod loads without a stale loose-folder conflict.
- The greenhouse appears in the construction menu.
- The peaked-roof model and materials load.
- The model can be placed.
- The interior remains walkable.
- The player and unloading triggers work.
- The two greenhouse recipes appear.
- No missing i3d, shapes, texture, mapping, or fill-type errors appear in the log.

## Important Inactive Files

```text
FS25_GreenHorizonIndustries/xml/fruitTypes.xml
FS25_GreenHorizonIndustries/xml/growth/hempGrowth.xml
FS25_GreenHorizonIndustries/xml/productions/hempProcessingRecipes.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempFoliagePlan.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempFieldIntegrationPlan.xml
FS25_GreenHorizonIndustries/pallets/xml/*.xml
```

These files are packaged as development foundations but are not loaded by the active mod descriptor.

## Future Mod Concept Saved

The separate **Contractor Equipment Rental Yard** concept is documented in:

```text
docs/Future-Mods.md
```

It remains a future standalone project and is not part of Green Horizon Industries.

## Development Rule

Do not upload GIANTS base-game files or extracted game assets to this repository. Base-game files may be used locally as references only.
