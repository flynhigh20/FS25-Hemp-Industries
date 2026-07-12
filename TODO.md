# FS25 Hemp Industries Roadmap

## Current Test Snapshot

- Active working folder: `FS25_GreenHorizonIndustries/`
- Current mod version: `0.3.0.0`
- The Hemp Greenhouse appears in the FS25 **Greenhouses** category.
- Water unloading is confirmed working after correcting `exactFillRootNode` to use `shapeId="6"` in the exported I3D.
- The current booster test uses the base-game generic fill type `SEEDS`.
- `GHI_HEMP_SEED` remains reserved for the later custom hemp-seed pallet and production chain.
- The seeded greenhouse recipe produces `HEMP_FLOWER` as the more efficient CBD-processing input.
- The CBD plant is intended to accept both `HEMP` and `HEMP_FLOWER` through separate recipes.
- Current handoff details are in `CODEX_HANDOFF.md`.

## Phase 1 / Alpha 0.1 — Foundation

- [x] GitHub repository
- [x] Folder structure
- [x] Rename active mod folder to `FS25_GreenHorizonIndustries/`
- [x] Project branding
- [x] Roadmap
- [x] Initial `modDesc.xml`
- [x] Initial fill types
- [x] Verify `fillTypes.xml` loads in FS25
- [x] Add `icon_mod.dds`
- [x] First successful fill-type load
- [ ] Reconfirm `descVersion` against the installed FS25 build before release

---

## Phase 2 / Alpha 0.2 — Hemp Greenhouse Systems

### Completed

- [x] Greenhouse production test XML
- [x] Store-item wiring in `modDesc.xml`
- [x] Greenhouse appears in the FS25 Greenhouses category
- [x] Production inputs/outputs draft
- [x] Water-only recipe
- [x] Seed-boosted recipe foundation
- [x] Base-game `SEEDS` booster input merged into the active greenhouse XML
- [x] Seeded recipe produces `HEMP_FLOWER`
- [x] Recipe balance notes
- [x] Peaked glass greenhouse Blender generator
- [x] Front/rear roof overhang refinement
- [x] Door top raised to approximately `2.53 m`
- [x] Grow lights, conduit, irrigation, tank, control box, and grow beds
- [x] Placement, clear-area, level-area, indoor-area, test-area, and collision helpers
- [x] Player, unload, storage, pallet-spawn, and marker helper nodes
- [x] Visible trigger pads for test identification
- [x] Texture-path normalizer
- [x] I3D shapes filename/reference normalizer
- [x] Export validator and package blocker
- [x] Package/install cleanup for legacy loose folders and ZIP names
- [x] Water unload trigger confirmed working with `exactFillRootNode shapeId="6"`
- [x] CBD plant active in `modDesc.xml`
- [x] CBD plant configured with separate `HEMP` and `HEMP_FLOWER` recipes

### Current test work

- [ ] Confirm generic `SEEDS` unload at the same trigger where water works
- [ ] Confirm both greenhouse recipes start, consume inputs, and produce outputs
- [ ] Confirm `HEMP_FLOWER` no longer reports an unsupported loading-station or pallet-spawner warning
- [ ] Confirm the CBD plant shows both recipes
- [ ] Confirm the CBD plant accepts both `HEMP` and `HEMP_FLOWER`
- [ ] Confirm CBD oil pallet output works
- [ ] Confirm the packaged ZIP contains `xml/fillTypes.xml` and both active placeable XML files
- [ ] Confirm FS25 loads the shapes file without a filename-case error
- [ ] Confirm all corrected I3D mappings resolve without child-index errors
- [ ] Confirm placement, leveling, walking access, collisions, and trigger positions in game
- [ ] Test using a fresh save or remove the obsolete `hempProcessingFacility.xml` entry from a backed-up old save
- [ ] Convert final PNG textures to mipmapped DDS files where appropriate
- [ ] Replace or refine the temporary static hemp visuals after gameplay is stable
- [ ] Final greenhouse and CBD economy balancing

### Later Phase 2 work

- [ ] Export and activate the custom Hemp Seed pallet
- [ ] Switch booster input from `SEEDS` back to `GHI_HEMP_SEED`
- [ ] Export and activate the flower and other custom product pallets
- [ ] Add dedicated sell points
- [ ] Complete final store and production icons

---

## Phase 3 / Alpha 0.3 — Field Crop Extension

- [ ] Activate fruit-type registration
- [ ] Register Industrial Hemp as a field crop
- [ ] Finalize crop textures
- [ ] Finalize all growth stages
- [ ] Complete harvest setup
- [ ] Validate destruction, density channels, save/reload, and multiplayer behavior
- [ ] Precision Farming experiments

---

## Beta

- [ ] Custom harvester
- [ ] New equipment
- [ ] Custom processing buildings
- [ ] Console testing and optimization

---

## Version 1.0

- [ ] Full regression test
- [ ] Multiplayer test
- [ ] Performance pass
- [ ] Localization pass
- [ ] ModHub-ready package
