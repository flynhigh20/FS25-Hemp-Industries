# Codex Handoff - Green Horizon Industries

## Start here

- Repository: `flynhigh20/FS25-Hemp-Industries`
- Protected base branch: `main`
- Current working folder: `C:\Users\user\Desktop\FS25-Hemp-Industries-main`
- Do not switch to older Codex workspaces, the separate Git clone, or the installed mod ZIP.
- Active mod folder: `FS25_GreenHorizonIndustries/`
- Current test version: `0.3.0.0`
- The user requested that current progress be synchronized to GitHub after this handoff update.

## Active placeables

1. Hemp Greenhouse: `placeables/greenhouses/hempGreenhouse.xml`
2. CBD Processing Factory XML: `placeables/productions/cbdPlantSmall.xml`
3. CBD factory I3D: `placeables/productions/i3d/greenhorizonhempprocessingfacility.i3d`
4. CBD factory shapes: `placeables/productions/i3d/greenhorizonhempprocessingfacility.i3d.shapes`
5. Blender source: `assets/blender/green_horizon_hemp_processing_facility.blend`

## Confirmed working in FS25

- Greenhouse placement, model, materials, collisions, and animated door.
- Greenhouse manual water unloading.
- Preserve greenhouse `exactFillRootNode shapeId="6"`.
- Base-game seed bags auto-unload through the dedicated pallet trigger.
- Greenhouse production wrench works independently from the door.
- Both greenhouse recipes consume their inputs and produce outputs.
- Greenhouse pallet XML uses the same nested contract as the CBD factory: `palletSpawner -> palletAreaStart -> palletAreaEnd`; water and seed unloading remain separate. HEMP, BIOMASS, and FLOWER pallet store items are now registered, and FLOWER uses a working stock pallet base. In-game spawn confirmation is pending.
- CBD factory custom model loads.
- CBD factory internal production wrench works.
- CBD factory accepts the two existing recipes: `HEMP` and `HEMP_FLOWER` to `GHI_CBD_OIL`.
- Industrial hemp distribution from greenhouse to CBD factory is confirmed.

## Current CBD factory build

- Decorative interior includes an industrial screw press, hopper, motor, press-cake tote, oil tank, filter vessel, piping, controls, benches, scale, bottles, and tool chest.
- Factory has a two-tone metal-panel wall finish and wall/door collisions.
- Production wrench is inside near the personnel entrance.
- Material unloading is outside for vehicle access.
- The large door uses absolute closed position `-1.20804 1.75 4.11` and open position `-5.60804 1.75 4.11`; zero-based translation teleports it to the building center.
- CBD output must be set to `Storing` to create physical pallets.
- CBD pallet capacity: 250 L.
- CBD oil price: `$4.80/L`; full pallet value: about `$1,200`.
- Physical CBD pallets are confirmed working. A save with roughly 7,000 L stored spawned about 28 pallets immediately.
- Pallet footprint/location is accepted; the visible grass came from the chosen factory placement site.
- `cbdOilPallet.xml` is registered in `modDesc.xml` as a hidden store item.
- Pallet spawn hierarchy is `palletSpawner -> palletAreaStart -> palletAreaEnd` and visible stripes are aligned to that footprint.
- Clear, level, paint, indoor, and AI-update areas are active. The optional invalid test area was removed.
- The seeded greenhouse recipe lists `HEMP_FLOWER` first. Existing saves still contain only `<autoDeliverFillType>HEMP</autoDeliverFillType>` until the user re-toggles the seeded recipe to `Distributing`.
- Existing tested greenhouses were confirmed to have `<autoDeliverFillType>HEMP</autoDeliverFillType>` persisted in `savegame1/placeables.xml`; deleting and freshly placing them is required for a clean flower-distribution test.
- Greenhouse store image is now a 512x512 building thumbnail rather than the badge logo.
- CBD factory `GHI_BrandLogo` now has an explicit relative file reference and texture binding; fresh placement/reload is pending confirmation.
- Greenhouse floating pallet marker was removed. The warning-stripe marker now uses the actual pallet-spawner position; seed and water markers were not changed.

## Exporter pitfalls that already caused failures

1. Blender may export the factory as lowercase `greenhorizonhempprocessingfacility.i3d`; keep XML and shapes names synchronized.
2. The `<base><filename>` path is resolved from the mod root and must include `placeables/productions/i3d/`.
3. FS25 I3D mappings use `0>` for the exported scene root. Do not add another root `0|`. Current trigger hierarchy begins at `0>1`.
4. Blender exported the logo with too many `../` segments. After every export, normalize it to:
   `../../../branding/green_horizon_industries_main_logo.png`
5. Blender initially exported `emissiveColor="1 1 1 1"` on all factory materials, making the game view white. The Blender source now has emission disabled on all 19 materials. Verify a new I3D contains no full-white emissive values.
6. GIANTS export crashes in Blender background mode on this machine; the user exports from the Blender UI.

## Current XML mapping contract

- `sellingStation`: `0>1`
- `palletSpawner`: `0>1|14`
- `palletAreaStart01`: `0>1|14|0`
- `palletAreaEnd01`: `0>1|14|0|0`
- `personnelDoorTrigger`: `0>1|15`
- `playerTrigger`: `0>1|16`
- `playerTriggerMarker`: `0>1|17`
- `rollupDoorTrigger`: `0>1|18`
- `unloadTrigger`: `0>1|21`
- `unloadTriggerMarker`: `0>1|22`
- Door visual paths depend on export order and must be recalculated if the Blender hierarchy changes.

## Immediate user test

1. Restart FS25 and place a fresh CBD factory.
2. Confirm factory colors are normal, not white.
3. Confirm the large door slides left and clears the opening.
4. Confirm the personnel door works.
5. Confirm internal wrench and both recipes.
6. On each greenhouse, select the seeded recipe and re-toggle it to `Distributing`; confirm `HEMP_FLOWER` appears in the CBD factory.
7. Set CBD oil output to `Storing`.
8. Physical 250 L pallet spawning is confirmed.
9. Set a greenhouse output to `Storing` and confirm HEMP, BIOMASS, or FLOWER pallets spawn in the marked area.
10. Decide whether to retain 250 L CBD pallets or use a larger batch to avoid backlog floods.
11. Exit and inspect `log.txt`.

## Next implementation work while the user tests

1. Confirm the repaired physical greenhouse output pallet spawning without changing the proven water, seed, or wrench setup.
2. Confirm flower auto-delivery after re-toggling the seeded greenhouse recipe.
3. Choose a backlog-safe CBD pallet capacity; the current spawn location itself is accepted.
4. Preserve the nested CBD pallet hierarchy in Blender before the next export; the current I3D was repaired directly.
5. Inspect `log.txt`, then begin Phase 3 only after the remaining Phase 2 tests pass.

## Do not change casually

- Do not replace greenhouse water `shapeId="6"`.
- Do not remove the proven greenhouse seed pallet trigger.
- Do not activate field fruit types until the controlled-map test is ready.
- Use the protected-branch workflow for GitHub updates; never force-push `main`.
