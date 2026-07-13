# FS25 Hemp Industries Roadmap

## Current Test Snapshot

- Active mod version: `0.3.0.0`.
- Work only from `C:\Users\user\Desktop\FS25-Hemp-Industries-main`.
- Active placeables: Hemp Greenhouse and CBD Processing Factory.
- Greenhouse water, base-game seed bags, wrench, materials, and both recipes are confirmed working in game.
- The custom CBD factory loads and its internal production wrench works.
- Factory materials were corrected after Blender exported every material as fully emissive.
- CBD oil uses a provisional 250 L pallet worth $1,200 (`$4.80/L`).
- Hemp distribution is confirmed; seeded greenhouse output now lists `HEMP_FLOWER` first so its production-menu output toggle can target flower separately.
- CBD pallet vehicle is registered and the spawn hierarchy now matches the proven greenhouse pattern.
- Full recovery and workflow context is in `CODEX_HANDOFF.md`.

## Phase 1 / Alpha 0.1 - Foundation

- [x] Repository and protected-branch workflow
- [x] Active `FS25_GreenHorizonIndustries/` mod folder
- [x] Branding, roadmap, and `modDesc.xml`
- [x] Initial fill types and mod icon
- [x] Confirm fill types load in FS25
- [x] Confirm `descVersion` against the installed FS25 build

---

## Phase 2 / Alpha 0.2 - Greenhouse and CBD Loop

### Greenhouse confirmed

- [x] Greenhouse store item and custom model
- [x] Water-only and base-game `SEEDS` boosted recipes
- [x] Seeded recipe outputs `HEMP_FLOWER`
- [x] Water unloading with `exactFillRootNode shapeId="6"`
- [x] Dedicated seed pallet trigger and auto-unload
- [x] Production wrench separated from door trigger
- [x] Door animation and collision
- [x] Both recipes consume inputs and produce outputs
- [x] No unsupported `HEMP_FLOWER` output warning
- [x] Standardize greenhouse pallet contract as `palletSpawner -> palletAreaStart -> palletAreaEnd`, separate from unload triggers

### CBD factory completed in code

- [x] Preserve the proven bulk-hemp and flower CBD recipes
- [x] Replace temporary base-game building with custom factory I3D
- [x] Add industrial oil press, tanks, filter, piping, benches, and props
- [x] Add two-tone industrial wall finish
- [x] Add wall and closed-door collisions
- [x] Move production wrench inside
- [x] Separate personnel-door, large-door, wrench, and unloading triggers
- [x] Repair mod-root I3D path and all I3D index mappings
- [x] Repair exported logo path
- [x] Disable accidental full material emission
- [x] Configure large door to slide 4.4 m left
- [x] Reduce CBD pallet capacity to 250 L
- [x] Rebalance CBD oil to `$4.80/L`
- [x] Register `cbdOilPallet.xml` as a hidden vehicle store item
- [x] Nest CBD pallet nodes as `palletSpawner -> palletAreaStart -> palletAreaEnd`
- [x] Align visible pallet safety stripes with the real spawn footprint
- [x] Add clear, level, paint, indoor, and AI-update placement areas
- [x] Remove the invalid optional test area rather than retain a direct-child warning
- [x] Put `HEMP_FLOWER` first in the seeded greenhouse outputs for independent distribution control

### CBD factory test next

- [x] Confirm factory colors render normal
- [x] Confirm large door slides left and clears the opening
- [x] Confirm personnel door opens and closes cleanly
- [x] Confirm industrial hemp distributes from greenhouse to CBD factory
- [ ] Re-toggle the seeded greenhouse recipe to `Distributing` and confirm `HEMP_FLOWER` transfers
- [x] Confirm both recipes activate from the internal wrench
- [x] Set CBD output mode to `Storing`
- [x] Confirm 250 L CBD-oil pallets instantiate and spawn
- [x] Confirm pallet spawn footprint/location is acceptable
- [ ] Prevent a large stored backlog from flooding the area with many 250 L pallets at once
- [ ] Review `log.txt` after exiting
- [x] Confirm the registered 250 L pallet loads and spawns without a log error

### Remaining Phase 2 polish

- [ ] Fresh-save regression test for placement, access, and collisions
- [ ] Final greenhouse and CBD economy pass after measured gameplay
- [ ] Final store and production icons
- [ ] Convert logo and final textures to power-of-two mipmapped DDS
- [ ] Remove obsolete savegame references only if they still appear

---

## Phase 3 / Alpha 0.3 - Outdoor Hemp Crop

- [ ] Generate and approve final crop texture atlas
- [ ] Validate all nine visible foliage/growth states
- [ ] Activate HEMP fruit-type registration on a controlled test map
- [ ] Validate seasonal growth, density channels, destruction, and save/reload
- [ ] Configure yield, mature-to-cut transition, windrow, and cutter effects
- [ ] Adapt one base-game planter and harvester for the first field test
- [ ] Run the first plant-to-harvest-to-delivery test
- [ ] Precision Farming and multiplayer experiments

---

## Later Industry and Equipment

- [ ] Biomass mill or energy destination
- [ ] Fiber textile/tailor destination
- [ ] CBD-edibles bakery chain
- [ ] Decide whether a custom harvester is necessary after base-equipment testing
- [ ] Console performance and compatibility pass

## Version 1.0

- [ ] Full regression and multiplayer testing
- [ ] Performance and economy balance
- [ ] Localization pass
- [ ] ModHub-ready package
