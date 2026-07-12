# Codex Handoff — Green Horizon Industries

## Repository and working copy

- Repository: `flynhigh20/FS25-Hemp-Industries`
- Protected base branch: `main`
- Local working copy: `C:\Users\user\Desktop\FS25-Hemp-Industries-main`
- Active mod folder: `FS25_GreenHorizonIndustries/`
- Current version: `0.3.0.0`

## Active scope

1. Hemp Greenhouse: `placeables/greenhouses/hempGreenhouse.xml`
2. CBD Plant: `placeables/productions/cbdPlantSmall.xml`

Field crops, unfinished custom pallets, cutter effects, and the larger processing chain remain inactive.

## Confirmed working

- Greenhouse store registration and placement.
- Manual water unloading.
- Water requires `exactFillRootNode shapeId="6"`; preserve it.
- Greenhouse model, shapes file, and sliding door.
- Base-game `SEEDS` is the temporary boosted-recipe input.
- CBD plant wrench/player interaction.
- CBD plant store registration.

## Prepared fixes awaiting in-game confirmation

### Greenhouse wrench

The player trigger previously occupied the same location and shape geometry as `door1Trigger`. It is now relocated two meters sideways from the doorway in the exported I3D and Blender generator. The visible wrench marker moved with it.

### Seed bags

Adding `SEEDS` to the water-style exact-fill trigger was insufficient for normal seed bags. The greenhouse now has a separate `seedPalletTrigger` using the stock FS25 pallet-trigger pattern:

- kinematic and compound trigger
- collision group `0x20000000`
- pallet collision mask `0x10000`
- `<palletTrigger fillTypes="SEEDS" autoUnload="true">`

The working water exact-fill trigger was not changed.

## Immediate test order

1. Run preflight and package/install.
2. Restart FS25 and place a fresh greenhouse.
3. Confirm water still unloads.
4. Confirm the relocated wrench opens production management.
5. Confirm the sliding door still works independently.
6. Put a normal base-game seed bag inside the seed marker/trigger area.
7. Confirm `SEEDS` enter greenhouse storage.
8. Test both greenhouse recipes.
9. Confirm no unsupported `HEMP_FLOWER` warning.
10. Test both CBD recipes and CBD-oil pallet output.
11. Exit and inspect `log.txt`.

## Do not change yet

- Do not replace `shapeId="6"` on the working water fill root.
- Do not switch the booster to `GHI_HEMP_SEED` before its custom pallet is active.
- Do not activate unfinished field-crop or custom-pallet systems to hide warnings.
- Do not treat an obsolete `hempProcessingFacility.xml` savegame entry as a current store-registration problem.
