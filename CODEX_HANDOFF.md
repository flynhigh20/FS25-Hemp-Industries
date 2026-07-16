# Codex Handoff - Green Horizon Industries

## Start here

- Repository: `flynhigh20/FS25-Hemp-Industries`
- Protected base branch: `main`
- Current working folder: `C:\Users\user\Desktop\FS25-Hemp-Industries`
- Do not switch to older Codex workspaces, the separate Git clone, or the installed mod ZIP.
- Active mod folder: `FS25_GreenHorizonIndustries/`
- Current test version: `0.3.0.0`
- The user requested that current progress be synchronized to GitHub after this handoff update.
- Current branch: `agent/document-confirmed-fixes`; ready-for-review PR: `#10`. PR #9 is merged into `main`.

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
- Greenhouse pallet XML uses the same nested contract as the CBD factory: `palletSpawner -> palletAreaStart -> palletAreaEnd`; water and seed unloading remain separate. Industrial Hemp and Flower pallets are confirmed colored, movable, and collidable in game. The active Biomass pallet capacity is 5,700 L; its final label/color/tension-belt check remains pending.
- Greenhouse warning stripes are confirmed correctly positioned in game. The front door and building/pallet collisions are confirmed working.
- Greenhouse status-screen emissives are restored and confirmed working in game.
- Custom pallet texture paths are normalized to `../textures/...`; the active-production validator now rejects pallet textures that resolve outside the mod.
- CBD factory custom model loads.
- CBD factory internal production wrench works.
- CBD factory accepts the two existing recipes: `HEMP` and `HEMP_FLOWER` to `GHI_CBD_OIL`.
- Industrial hemp and `HEMP_FLOWER` distribution from greenhouse to CBD factory are confirmed.
- The former base-game lettuce greenhouse visual has been removed. `hempGreenhousePlant.xml` and `i3d/hempGreenhousePlant.i3d` provide dedicated custom hemp foliage, confirmed visible in game.
- The CBD factory now has a separate `palletTrigger` shape at mapping `0>1|23`. It uses `trigger="true"`, collision group `0x20000000`, and pallet collision mask `0x10000`, matching official FS25 production-point pallet triggers. Physical HEMP/HEMP_FLOWER auto-unload is pending in-game confirmation.
- Greenhouse pallet spawning is capacity-gated. Current full-pallet thresholds are 3,800 L HEMP, 7,500 L HEMP_FLOWER, and 5,700 L biomass; lower stored amounts are not a spawn failure.

## Current CBD factory build

- Decorative interior includes an industrial screw press, hopper, motor, press-cake tote, oil tank, filter vessel, piping, controls, benches, scale, bottles, and tool chest.
- Factory has a two-tone metal-panel wall finish and wall/door collisions.
- Production wrench is inside near the personnel entrance.
- Material unloading is outside for vehicle access.
- The large door uses absolute closed position `-1.20804 1.75 4.11` and open position `-5.60804 1.75 4.11`; zero-based translation teleports it to the building center.
- CBD output must be set to `Storing` to create physical pallets.
- CBD pallet capacity: 1,000 L.
- CBD oil price: `$4.80/L`; full pallet value: about `$4,800`.
- Physical CBD pallets are confirmed working. Roughly 7,000 L stored now represents about seven full pallets rather than the former 28-pallet flood.
- The CBD factory pallet output/drop fix is confirmed working in game.
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
- `palletTrigger`: `0>1|23`
- Door visual paths depend on export order and must be recalculated if the Blender hierarchy changes.

## Immediate user test

1. Move physical HEMP and HEMP_FLOWER pallets into the CBD marker and confirm each auto-unloads into the factory. This input system is still unconfirmed and is separate from the confirmed CBD-oil pallet output/drop.
2. Confirm the 5,700 L Biomass pallet label, color, collisions, fork handling, and tension-belt behavior.
3. Test the rebuilt HEMP, HEMP_FLOWER, and BIOMASS pallets for fork entry, stacking, trailer loading, and tension belts.
4. Exit and inspect `log.txt` specifically for pallet-intake, collision, or tension-belt errors.

## Next implementation work while the user tests

1. Test the rebuilt HEMP, HEMP_FLOWER, and BIOMASS pallets on a forklift and trailer. They were recovered from `greenhorizonproductpallets.i3d`, retain the complete visual/helper hierarchy, and now include stock-style left/right fork rails plus tension-belt mappings.
2. Confirm pallet stacking, fork entry, trailer loading, and tension belts with the package at `dist/FS25_GreenHorizonIndustries.zip`.
3. Continue Phase 3 with controlled runtime registration of `foliage/hemp/hemp.xml`, then test sowing with the stock Great Plains seeder and harvesting with the MF 8570/header.
4. Inspect `log.txt`, then validate seasonal growth, save/reload, cutter transition, and delivery.

## Phase 3 outdoor crop preparation

- `foliage/hemp/hemp.i3d` contains nine exported state roots. The state objects intentionally overlap at the field origin in Blender; that is the correct export layout, not a damaged preview layout.
- `foliage/hemp/hemp.xml` is a real FS25 `foliageType` definition and its near/distance `blockShape` paths match the exported alphabetical child order.
- Runtime registration remains deliberately inactive in `modDesc.xml`. Do not install it as a live fruit type until a controlled loader/map registration path is validated.
- First equipment targets are the stock Great Plains seeder (`SOWINGMACHINE`) and MF 8570 grain combine/header (`GRAINHEADER`).

## Do not change casually

- Do not remove or simplify greenhouse water `exactFillRootNode` collision attributes.
- Do not remove the proven greenhouse seed pallet trigger.
- Do not activate field fruit types until the controlled-map test is ready.
- Use the protected-branch workflow for GitHub updates; never force-push `main`.
