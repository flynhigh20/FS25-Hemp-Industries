# Phase 2 / Alpha 0.2 — Hemp Greenhouse Test Build

## Goal

Add the first greenhouse production test shell now that Phase 1 fill types are confirmed loading in FS25.

## Phase 2.1 Log Fix

The first Phase 2 test reported:

```text
Error: Can't load resource '.../FS25_Hemp_Industries/icon_mod.dds'.
```

Fix applied:

```text
Removed iconFilename from modDesc.xml until icon_mod.dds is actually packaged.
```

## Phase 2.2 Store Visibility Test

The latest log showed FS25 1.19 uses:

```text
ModDesc Version: 109
```

Fix applied:

```text
modDesc descVersion updated from 91 to 109
mod version updated to 0.2.2.0
greenhouse store category changed from productionPoints to greenhouses
```

## Active Files

```text
FS25_GreenHorizonIndustries/modDesc.xml
FS25_GreenHorizonIndustries/placeables/greenhouses/hempGreenhouse.xml
FS25_GreenHorizonIndustries/xml/productions/hempGreenhouseRecipes.xml
```

## Where To Look In Game

Use the construction menu, not the vehicle/equipment store.

Check:

```text
Construction > Production > Greenhouses
Construction > Production > Factories / Production Points
Construction > Buildings / Sheds, only if FS25 falls back from the greenhouse category
```

If the mod list still shows version `0.2.0.0`, the old zip is still installed and the new test is not active.

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

1. Delete the old `FS25_Hemp_Industries.zip` from the FS25 mods folder.
2. Re-zip the current active folder as `FS25_Hemp_Industries.zip` or `FS25_GreenHorizonIndustries.zip`.
3. Start FS25.
4. Confirm the mod list shows version `0.2.2.0`.
5. Confirm the missing `icon_mod.dds` error is gone.
6. Confirm the mod still loads the 3 fill types.
7. Check Construction > Production > Greenhouses.
8. If the greenhouse still does not show, search the log for:

```text
placeables/greenhouses/hempGreenhouse.xml
storeItem_ghi_hempGreenhouse
production_ghi_hempGreenhouseBasic
Invalid store item
Invalid placeable
Unknown category
```

## Expected Risk Areas

- Greenhouse category name may differ internally.
- Store item XML may be registered but hidden by category/menu rules.
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
