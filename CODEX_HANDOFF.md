# Codex Handoff — Green Horizon Industries

## Repository and branch

- Repository: `flynhigh20/FS25-Hemp-Industries`
- Branch: `main`
- Active mod folder: `FS25_GreenHorizonIndustries/`
- Current mod version in `modDesc.xml`: `0.3.0.0`
- User's local working copy: `C:\Users\user\Desktop\FS25-Hemp-Industries-main`

## Current active scope

Two active store items are registered:

1. `placeables/greenhouses/hempGreenhouse.xml`
2. `placeables/productions/cbdPlantSmall.xml`

The field crop, custom product pallets, cutter effects, and larger processing chain remain incomplete or inactive unless explicitly registered elsewhere.

## Confirmed working

- Hemp Greenhouse appears in the FS25 Greenhouses category.
- Water unloading works.
- The greenhouse unload shape required `exactFillRootNode` to use `shapeId="6"` in `greenHorizonHempGreenhouse.i3d`.
- Greenhouse model, shapes file, doorway, helpers, and corrected I3D mapping work have been merged into `main`.
- Temporary booster input uses base-game `SEEDS` rather than `GHI_HEMP_SEED`.
- CBD plant is active in the store.

## Current greenhouse design

### Basic recipe

- Input: `WATER`
- Outputs: `HEMP` and `GHI_HEMP_BIOMASS`

### Seeded upgraded recipe

- Inputs: `WATER` and base-game `SEEDS`
- Outputs: increased `HEMP`, `HEMP_FLOWER`, and `GHI_HEMP_BIOMASS`

The upgraded recipe exists specifically to create flower as the more efficient CBD-processing route.

## Current CBD plant design

The CBD plant must accept both greenhouse products through two separate recipes:

1. `HEMP` -> `GHI_CBD_OIL`
2. `HEMP_FLOWER` -> `GHI_CBD_OIL`

The flower recipe should be more efficient than the bulk-hemp recipe. The current intended balance is:

- `40 HEMP` -> `10 GHI_CBD_OIL`
- `20 HEMP_FLOWER` -> `10 GHI_CBD_OIL`

Its storage and unloading station must accept both `HEMP` and `HEMP_FLOWER`.

## Current issues found during FS25 testing

### Seed unloading

The user has not yet confirmed that normal base-game `SEEDS` unload into the greenhouse.

The greenhouse currently has four visible markers:

- water marker
- wrench/player-production marker
- unload marker
- pallet marker

The separate `seedUnloadMarker` is only a visual marker in the current setup. There is one actual `exactFillRootNode`, configured for `WATER SEEDS`. Test seeds at the same physical unloading trigger that accepts water before adding a second trigger shape.

### Flower output warning

FS25 reported:

```text
Output filltype 'GHI_HEMP_FLOWER' is not supported by loading station or pallet spawner
```

The active greenhouse was changed to use `HEMP_FLOWER`, and the loading/storage declarations were updated. Verify the warning is gone after a fresh package/install.

No custom flower pallet is active yet. Flower may remain stored internally until the flower pallet I3D/XML is finished and activated.

### Old savegame warning

FS25 reported:

```text
Placeable '.../placeables/productions/hempProcessingFacility.xml' not defined in store items
```

That path is from an older savegame entry. The currently active production is `placeables/productions/cbdPlantSmall.xml`. Use a fresh save for clean testing, or back up and remove the obsolete placeable entry from `savegame1/placeables.xml`.

## Important current files

- `FS25_GreenHorizonIndustries/modDesc.xml`
- `FS25_GreenHorizonIndustries/xml/fillTypes.xml`
- `FS25_GreenHorizonIndustries/placeables/greenhouses/hempGreenhouse.xml`
- `FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d`
- `FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d.shapes`
- `FS25_GreenHorizonIndustries/placeables/productions/cbdPlantSmall.xml`
- `tools/windows/preflight_check.ps1`
- `tools/windows/package_and_install_mod.ps1`
- `tools/windows/validate_greenhouse_export.ps1`
- `TODO.md`

## Immediate next steps

1. Pull `main` into the user's local working copy.
2. Run preflight and package/install tools.
3. Test generic `SEEDS` at the same unloading trigger where water works.
4. Confirm both greenhouse recipes consume inputs and produce the intended outputs.
5. Confirm `HEMP_FLOWER` no longer generates the loading-station/pallet-spawner warning.
6. Confirm the CBD plant shows two recipes and accepts both `HEMP` and `HEMP_FLOWER`.
7. Test CBD oil pallet output.
8. Review the log for missing shapes, bad I3D child mappings, unsupported output fill types, or stale savegame placeables.
9. Update `TODO.md` with confirmed results.

## Do not change yet

- Do not switch the greenhouse booster back to `GHI_HEMP_SEED` until the custom hemp-seed pallet is exported and active.
- Do not activate unfinished field-crop registration or custom product pallets merely to silence warnings.
- Do not replace the working greenhouse I3D/shapes export without preserving the current node hierarchy and `shapeId="6"` unload fix.
- Do not assume the old `hempProcessingFacility.xml` warning is caused by the current `modDesc.xml`; it is a stale savegame reference.
