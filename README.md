# Green Horizon Industries — FS25 Hemp Expansion

Green Horizon Industries is an alpha-stage Farming Simulator 25 hemp greenhouse, production, and future field-crop expansion.

## Current Build

```text
Version: 0.3.0.0
Active mod folder: FS25_GreenHorizonIndustries/
Target: Farming Simulator 25 on PC
```

## Active Store Items

### Hemp Greenhouse

- Custom glass greenhouse model and exported collision shapes.
- Confirmed working manual `WATER` unloading.
- Basic recipe: `WATER` → `HEMP` + `GHI_HEMP_BIOMASS`.
- Boosted recipe: `WATER` + base-game `SEEDS` → more `HEMP`, `HEMP_FLOWER`, and biomass.
- Sliding door, pallet area, water marker, seed marker, and production wrench.

### CBD Plant

- Uses the stable base-game small oil-plant placeable.
- Bulk recipe: `40 HEMP` → `10 GHI_CBD_OIL`.
- Flower recipe: `20 HEMP_FLOWER` → `10 GHI_CBD_OIL`.
- Storage and unloading accept both hemp inputs.

## Current Test Fixes

Two fixes are prepared and require a fresh in-game test:

1. The greenhouse production/player trigger was moved away from the sliding-door trigger so the door action cannot intercept the wrench action.
2. A dedicated `seedPalletTrigger` was added using the stock FS25 pallet-trigger collision pattern. The confirmed water trigger and its required `shapeId="6"` were left unchanged.

The seed marker is now paired with a real pallet trigger instead of relying on the water-style exact-fill trigger alone.

## Test Procedure

1. Run `tools/windows/preflight_check.bat`.
2. Run `tools/windows/package_and_install_mod.bat`.
3. Fully restart FS25 and use a fresh save or place a fresh greenhouse.
4. Confirm water still unloads at the water icon.
5. Stand at the relocated wrench icon and confirm the production menu opens.
6. Confirm the sliding door still opens independently.
7. Place a normal base-game seed bag inside the seed/unload marker area.
8. Confirm seeds transfer into greenhouse storage.
9. Activate each greenhouse recipe separately and confirm input consumption and output production.
10. Deliver both `HEMP` and `HEMP_FLOWER` to the CBD plant.
11. Confirm both CBD recipes and CBD-oil pallet output.
12. Exit the game and inspect `log.txt` with `tools/windows/check_fs25_log.bat`.

## Important Savegame Note

An old save may still contain a removed `hempProcessingFacility.xml` placeable reference. For a clean test, use a fresh save or back up the save and remove only that obsolete entry from `placeables.xml`.

## Prepared but Inactive Work

- Field-crop registration and seasonal growth XML.
- Nine hemp foliage states.
- Crop and calendar icons.
- Cutter effects and mature-to-cut transition planning.
- Custom product pallet sources.
- Larger hemp-processing and equipment concepts.

These systems must not be activated merely to hide warnings. The greenhouse and CBD production loop must pass first.

## Useful Files

```text
CODEX_HANDOFF.md
TODO.md
FS25_GreenHorizonIndustries/modDesc.xml
FS25_GreenHorizonIndustries/xml/fillTypes.xml
FS25_GreenHorizonIndustries/placeables/greenhouses/hempGreenhouse.xml
FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d
FS25_GreenHorizonIndustries/placeables/productions/cbdPlantSmall.xml
tools/windows/preflight_check.ps1
tools/windows/package_and_install_mod.ps1
tools/windows/validate_greenhouse_export.ps1
```

## Development Rules

- Preserve the working greenhouse `exactFillRootNode shapeId="6"` configuration.
- Keep the booster on base-game `SEEDS` until the custom hemp-seed pallet is active.
- Keep unfinished field crop and custom pallets inactive.
- Do not upload GIANTS base-game files or extracted game assets.
- Use the protected-branch pull-request workflow for repository changes.
