# Phase 2 / Alpha 0.2 — Hemp Greenhouse Test Build

## Goal

Add the first greenhouse production test shell now that Phase 1 fill types are confirmed loading in FS25.

## Active Files

```text
FS25_GreenHorizonIndustries/modDesc.xml
FS25_GreenHorizonIndustries/placeables/greenhouses/hempGreenhouse.xml
FS25_GreenHorizonIndustries/xml/productions/hempGreenhouseRecipes.xml
```

## Production Loop

```text
WATER + GHI_HEMP_SEED -> HEMP + GHI_HEMP_BIOMASS
```

## Current Balance Draft

```text
cyclesPerHour: 24
costsPerActiveHour: 18
WATER input: 20
GHI_HEMP_SEED input: 4
HEMP output: 18
GHI_HEMP_BIOMASS output: 6
```

## Test Steps

1. Rename the zip/folder for this next test if desired.
2. Make sure only the active mod folder/zip is in the FS25 mods folder.
3. Start FS25.
4. Confirm the mod still loads the 3 fill types.
5. Check whether Hemp Greenhouse appears in the construction/store menu.
6. If the game reports an error, grab the log lines around:

```text
placeables/greenhouses/hempGreenhouse.xml
storeItem_ghi_hempGreenhouse
production_ghi_hempGreenhouseBasic
```

## Expected Risk Areas

- Temporary base-game greenhouse visual path may need adjustment.
- Production-point XML may need extra trigger/storage sections once the game parses the placeable.
- Store image path may need replacement with an original DDS asset.

## Not Yet Included

- Original Green Horizon greenhouse model
- Store image DDS
- In-game icon DDS
- Pallet definitions
- Storage/loading/unloading trigger tuning
- Sell point XML
- Final production economy balancing
