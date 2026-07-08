# FS25 Hemp Industries

🚧 Alpha Development  
🖥️ PC Compatible  
🎮 Console Goal  
🌱 Industrial Hemp Expansion  
🚜 Green Horizon Industries

## Current Build

**Phase 2 / Alpha 0.2 greenhouse test build is now started.**

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

## Phase 2 Scope

Phase 2 adds the first greenhouse production test shell.

Included now:

- `modDesc.xml` updated to version `0.2.0.0`
- Store item wiring for a Hemp Greenhouse
- Greenhouse production placeable XML
- Recipe balance notes XML
- Production input/output loop:
  - Inputs: `WATER`, `GHI_HEMP_SEED`
  - Outputs: `HEMP`, `GHI_HEMP_BIOMASS`

Still pending:

- Verify the greenhouse appears in the FS25 store
- Confirm the temporary base-game greenhouse visual path loads
- Add original Green Horizon greenhouse model/assets
- Add real DDS store image and icon files
- Add pallets/storage triggers after first placeable test
- Add sell points and economy balancing
- Add fruit/crop registration after FS25 map file references are verified

## Development Rule

Do not upload GIANTS base-game files or extracted game assets to this repository. Use them locally as references only.
