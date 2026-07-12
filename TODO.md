# FS25 Hemp Industries Roadmap

## Current Test Snapshot

- Active mod version: `0.3.0.0`.
- Active placeables: Hemp Greenhouse and CBD Plant.
- Water unloading is confirmed working with `exactFillRootNode shapeId="6"`.
- Greenhouse wrench and generic seed-bag intake were confirmed broken in the previous test.
- The wrench trigger is now separated from the door trigger in code and awaits retest.
- A dedicated stock-pattern `seedPalletTrigger` is now present and awaits retest.
- CBD plant is configured for separate `HEMP` and `HEMP_FLOWER` recipes.
- Full context and safety constraints are in `CODEX_HANDOFF.md`.

## Phase 1 / Alpha 0.1 — Foundation

- [x] Repository and protected-branch workflow
- [x] Active `FS25_GreenHorizonIndustries/` mod folder
- [x] Branding, roadmap, and `modDesc.xml`
- [x] Initial fill types and mod icon
- [x] Confirm fill types load in FS25
- [ ] Reconfirm `descVersion` against the installed FS25 build before release

---

## Phase 2 / Alpha 0.2 — Greenhouse and CBD Loop

### Completed

- [x] Greenhouse store item and custom model
- [x] Water-only greenhouse recipe
- [x] Base-game `SEEDS` boosted recipe
- [x] Seeded recipe outputs `HEMP_FLOWER`
- [x] Water unload confirmed with `shapeId="6"`
- [x] Greenhouse door animation and collision
- [x] CBD plant store item
- [x] CBD bulk-hemp recipe
- [x] CBD flower recipe with improved efficiency
- [x] CBD storage/unloading configured for both hemp inputs
- [x] Export validation and clean package/install tools

### Fixes prepared — test next

- [x] Separate greenhouse wrench/player trigger from the door trigger volume
- [x] Add dedicated `seedPalletTrigger` with pallet collision mask `0x10000`
- [x] Add `<palletTrigger fillTypes="SEEDS" autoUnload="true">` to the greenhouse selling station
- [x] Preserve the confirmed water trigger and `shapeId="6"`
- [ ] Confirm the relocated wrench opens the production menu
- [ ] Confirm the door action still works independently
- [ ] Confirm a normal base-game seed bag auto-unloads at the seed marker
- [ ] Confirm water unloading still works after the changes
- [ ] Confirm both greenhouse recipes consume inputs and produce outputs
- [ ] Confirm `HEMP_FLOWER` produces no unsupported output warning
- [ ] Confirm CBD plant displays both recipes
- [ ] Confirm CBD plant accepts both `HEMP` and `HEMP_FLOWER`
- [ ] Confirm CBD oil pallet output
- [ ] Review `log.txt` for bad mappings, missing shapes, or unsupported fill types

### Remaining Phase 2 work

- [ ] Fresh-save regression test for placement, leveling, access, and collisions
- [ ] Remove or retest obsolete savegame `hempProcessingFacility.xml` references
- [ ] Final greenhouse and CBD economy balance
- [ ] Final store and production icons
- [ ] Convert final textures to mipmapped DDS where appropriate
- [ ] Export and activate custom product pallets only after gameplay is stable

---

## Phase 3 / Alpha 0.3 — Outdoor Hemp Crop

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

---

## Version 1.0

- [ ] Full regression and multiplayer testing
- [ ] Performance and economy balance
- [ ] Localization pass
- [ ] ModHub-ready package
