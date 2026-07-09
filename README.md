# FS25 Hemp Industries

🚧 Alpha Development  
🖥️ PC Compatible  
🎮 Console Goal  
🌱 Industrial Hemp Expansion  
🚜 Green Horizon Industries

## Current Build

**Phase 2.3 / Alpha 0.2 greenhouse store visibility test is active.**

The active mod folder is:

```text
FS25_GreenHorizonIndustries/
```

This folder is intended to become the final FS25 mod folder/zip root for in-game testing.

## Phase 1 Result

Phase 1 fill type loading has been confirmed by FS25 log output:

```text
Info: Loaded 3 fill types from mod
```

## Phase 2.3 Scope

Phase 2.3 focuses on getting the Hemp Greenhouse visible in the FS25 construction menu after FS25 rejected the test category `greenhouses`.

Included now:

- `modDesc.xml` updated to mod version `0.2.3.0`
- `modDesc.xml` descriptor version kept at `109` for FS25 1.19
- Store item wiring for a Hemp Greenhouse
- Hemp Greenhouse category changed back to the valid `productionPoints` category
- Greenhouse production placeable XML
- Recipe balance notes XML
- Blender greenhouse generator output-path fix
- Blender pallet generator output-path fix
- Early top/front greenhouse signs removed from the Blender model
- Top pallet signs removed; pallets keep front labels only
- Production input/output loop:
  - Inputs: `WATER`, `GHI_HEMP_SEED`
  - Outputs: `HEMP`, `GHI_HEMP_BIOMASS`

## Where To Look In Game

Check the construction menu, not the normal vehicle/equipment store:

```text
Construction > Production > Factories / Production Points
```

If FS25 still shows the mod as version `0.2.2.0` or older, the old zip/folder is still installed.

Still pending:

- Verify the greenhouse appears in the FS25 construction menu under Production Points
- Confirm the temporary base-game greenhouse visual path loads
- Add original Green Horizon greenhouse model/assets to the placeable XML after i3d export
- Add real DDS store image and icon files
- Add pallets/storage triggers after first placeable test
- Add sell points and economy balancing
- Add fruit/crop registration after FS25 map file references are verified

## Development Rule

Do not upload GIANTS base-game files or extracted game assets to this repository. Use them locally as references only.
