# FS25 Hemp Industries Roadmap

## Current Test Snapshot

- Active mod version: `0.3.0.0`.
- Work only from `C:\Users\user\Desktop\FS25-Hemp-Industries`.
- Active placeables: Hemp Greenhouse and CBD Processing Factory.
- Greenhouse water, base-game seed bags, wrench, materials, and both recipes are confirmed working in game.
- The custom CBD factory loads and its internal production wrench works.
- Factory materials were corrected after Blender exported every material as fully emissive.
- CBD oil uses a 1,000 L pallet worth about $4,800 (`$4.80/L`).
- Industrial hemp and `HEMP_FLOWER` distribution into the CBD factory are confirmed working in game.
- CBD pallet vehicle is registered and the spawn hierarchy now matches the proven greenhouse pattern.
- CBD oil pallets are confirmed spawning at the current 1,000 L capacity. HEMP, BIOMASS, and FLOWER point to distinct Green Horizon pallet I3Ds.
- Greenhouse store thumbnail now uses a building render instead of the badge logo. Greenhouse pallet stripes are exported and moved outside with the spawn line. The repaired door position is confirmed in game.
- The temporary lettuce greenhouse visual has been replaced by a dedicated three-stage custom hemp plant XML/I3D, and its foliage is confirmed visible in game.
- The CBD factory now has a dedicated physical pallet trigger using the official FS25 pallet collision mask. HEMP and HEMP_FLOWER pallet auto-unloading is built and validated; in-game confirmation is pending.
- Current greenhouse pallet capacities are 3,800 L HEMP, 7,500 L HEMP_FLOWER, and 5,700 L biomass. Partial stored amounts do not spawn pallets until a full pallet is available.
- Greenhouse status-screen emissives are restored and confirmed working in game.
- CBD factory pallet output/drop is repaired and confirmed working in game.
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
- [ ] Reconfirm corrected door animation and collision after the latest Blender export
- [x] Both recipes consume inputs and produce outputs
- [x] No unsupported `HEMP_FLOWER` output warning
- [x] Standardize greenhouse pallet contract as `palletSpawner -> palletAreaStart -> palletAreaEnd`, separate from unload triggers
- [x] Confirm the greenhouse can instantiate a physical pallet (lettuce placeholder)
- [x] Confirm Industrial Hemp and Flower pallet colors, movement, and collisions in game
- [x] Configure the active Biomass pallet capacity at 5,700 L
- [ ] Visually identify Biomass pallets in game and confirm label/color/tension belts
- [x] Confirm rear warning-stripe placement and greenhouse door/collisions in game
- [x] Replace the temporary lettuce greenhouse visual with a dedicated custom hemp plant asset
- [x] Confirm custom hemp greenhouse foliage in game
- [x] Restore and confirm restrained greenhouse status-screen emissives

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
- [x] Set CBD pallet capacity to 1,000 L
- [x] Rebalance CBD oil to `$4.80/L`
- [x] Register `cbdOilPallet.xml` as a hidden vehicle store item
- [x] Nest CBD pallet nodes as `palletSpawner -> palletAreaStart -> palletAreaEnd`
- [x] Align visible pallet safety stripes with the real spawn footprint
- [x] Add clear, level, paint, indoor, and AI-update placement areas
- [x] Remove the invalid optional test area rather than retain a direct-child warning
- [x] Put `HEMP_FLOWER` first in the seeded greenhouse outputs for independent distribution control
- [x] Add a dedicated CBD pallet intake shape with the official pallet collision group/mask

### CBD factory test next

- [x] Confirm factory colors render normal
- [x] Confirm large door slides left and clears the opening
- [x] Confirm personnel door opens and closes cleanly
- [x] Confirm industrial hemp distributes from greenhouse to CBD factory
- [x] Confirm `HEMP_FLOWER` distributes from the seeded greenhouse recipe to the CBD factory
- [x] Confirm both recipes activate from the internal wrench
- [x] Set CBD output mode to `Storing`
- [x] Confirm 1,000 L CBD-oil pallets instantiate and spawn
- [x] Confirm pallet spawn footprint/location is acceptable
- [x] Confirm repaired CBD pallet output/drop behavior in game
- [x] Confirm the 1,000 L capacity prevents the former 250 L pallet flood
- [ ] Review `log.txt` after exiting
- [x] Confirm the registered 1,000 L pallet loads and spawns without a log error
- [ ] Confirm physical HEMP and HEMP_FLOWER pallets auto-unload at the CBD marker

### Remaining Phase 2 polish

- [ ] Fresh-save regression test for placement, access, and collisions
- [ ] Final greenhouse and CBD economy pass after measured gameplay
- [ ] Final store and production icons
- [x] Replace greenhouse badge-style store image with a greenhouse building thumbnail
- [ ] Convert logo and final textures to power-of-two mipmapped DDS
- [ ] Remove obsolete savegame references only if they still appear

---

## Phase 3 / Alpha 0.3 - Outdoor Hemp Crop

- [x] Generate initial crop texture atlas, crop icons, and cutter-effect sources
- [x] Export the nine-state outdoor hemp foliage I3D and align every XML blockShape path to its exported hierarchy
- [x] Create a schema-valid FS25 foliageType definition for outdoor HEMP
- [x] Select the stock Great Plains seeder and MF 8570/header as the first compatibility targets
- [ ] Approve and integrate the realistic AI-assisted crop atlas as the final texture set
- [ ] Validate all nine visible foliage/growth states in a controlled field test
- [ ] Activate HEMP fruit-type registration on a controlled test map
- [ ] Validate seasonal growth, density channels, destruction, and save/reload
- [ ] Configure yield, mature-to-cut transition, windrow, and cutter effects
- [ ] Adapt one base-game planter and harvester for the first field test
- [ ] Run the first plant-to-harvest-to-delivery test
- [ ] Precision Farming and multiplayer experiments

### Pallet handling polish

- [x] Model stock-style low fork rails and add stock-equivalent tension-belt configuration in source
- [x] Rebuild each active product pallet from the complete combined hierarchy and restore visuals, mount trigger, collision rails, and helper nodes
- [ ] Confirm forklift entry, stacking, trailer loading, and tension belts in game

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
