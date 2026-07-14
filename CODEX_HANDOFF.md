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

- Greenhouse placement, model, and materials are confirmed. The repaired front-door position is confirmed in game.
- Greenhouse manual water unloading.
- Preserve the proven greenhouse `exactFillRootNode` kinematic/compound collision flags; do not replace it with a plain renderable mesh.
- Base-game seed bags auto-unload through the dedicated pallet trigger.
- Greenhouse production wrench works independently from the door.
- Both greenhouse recipes consume their inputs and produce outputs.
- Greenhouse pallet XML uses the same nested contract as the CBD factory: `palletSpawner -> palletAreaStart -> palletAreaEnd`; water and seed unloading remain separate. A lettuce placeholder spawned successfully, proving the spawner. HEMP, BIOMASS, and FLOWER now load isolated custom Green Horizon I3Ds generated from `greenhorizonproductpallets.i3d`; distinct visuals await in-game confirmation.
- CBD factory custom model loads.
- CBD factory internal production wrench works.
- CBD factory accepts the two existing recipes: `HEMP` and `HEMP_FLOWER` to `GHI_CBD_OIL`.
- Industrial hemp and `HEMP_FLOWER` distribution from greenhouse to CBD factory are confirmed.

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
- The seeded greenhouse recipe is now a dedicated `HEMP_FLOWER` + biomass route; the basic recipe remains the Industrial Hemp route. Flower auto-delivery is confirmed working.
- Greenhouse store image is now a 512x512 building thumbnail rather than the badge logo.
- CBD factory `GHI_BrandLogo` now has an explicit relative file reference and texture binding; fresh placement/reload is pending confirmation.
- Greenhouse floating pallet marker was removed. Visible warning-stripe geometry is exported and both stripes and spawn line are positioned outside the rear wall; seed and water markers were not changed.

## Exporter pitfalls that already caused failures

1. Blender may export the factory as lowercase `greenhorizonhempprocessingfacility.i3d`; keep XML and shapes names synchronized.
2. The `<base><filename>` path is resolved from the mod root and must include `placeables/productions/i3d/`.
3. FS25 I3D mappings use `0>` for the exported scene root. Do not add another root `0|`. Current trigger hierarchy begins at `0>1`.
4. Blender exported the logo with too many `../` segments. After every export, normalize it to:
   `../../../branding/green_horizon_industries_main_logo.png`
5. Blender initially exported `emissiveColor="1 1 1 1"` on all factory materials, making the game view white. The Blender source now has emission disabled on all 19 materials. Verify a new I3D contains no full-white emissive values.
6. GIANTS export crashes in Blender background mode on this machine; the user exports from the Blender UI.
7. Blender exports animated door parts at their real absolute positions. Never use `translation="0 0 0"` as the closed keyframe or the pieces teleport to the greenhouse center.
8. Blender may omit trigger/collision flags. After export, validate and restore `static`/`kinematic`, `trigger`, collision groups/masks, `compound`, and `nonRenderable` attributes before packaging.

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
6. `HEMP_FLOWER` distribution is confirmed; retain the dedicated seeded flower route.
7. Set CBD oil output to `Storing`.
8. Physical 250 L pallet spawning is confirmed.
9. Set each greenhouse output to `Storing` and confirm the distinct HEMP, BIOMASS, and FLOWER custom pallets spawn on the rear warning stripes.
10. Decide whether to retain 250 L CBD pallets or use a larger batch to avoid backlog floods.
11. Exit and inspect `log.txt`.

## Next implementation work while the user tests

1. Confirm all three custom greenhouse pallet models, capacities, collisions, and tension-belt behavior.
2. Export the saved greenhouse Blender source through the GUI exporter to carry the restored restrained status-screen emissives into the game I3D; background export crashes Blender 4.2.
3. Choose a backlog-safe CBD pallet capacity; the current spawn location itself is accepted.
4. Preserve the nested CBD pallet hierarchy in Blender before the next export; the current I3D was repaired directly.
5. Inspect `log.txt`, then begin Phase 3 only after the remaining Phase 2 tests pass.

## Do not change casually

- Do not remove or simplify greenhouse water `exactFillRootNode` collision attributes.
- Do not remove the proven greenhouse seed pallet trigger.
- Do not activate field fruit types until the controlled-map test is ready.
- Use the protected-branch workflow for GitHub updates; never force-push `main`.
