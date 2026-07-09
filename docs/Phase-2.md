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

The FS25 1.19 log showed:

```text
ModDesc Version: 109
```

Fix applied:

```text
modDesc descVersion updated from 91 to 109
mod version updated to 0.2.2.0
greenhouse store category changed from productionPoints to greenhouses
```

## Phase 2.3 Category Rejection Fix

The Phase 2.2 test loaded the current mod version but FS25 rejected the greenhouse category:

```text
(Version: 0.2.2.0) FS25_GreenHorizonIndustries
Warning (.../hempGreenhouse.xml): Invalid category 'greenhouses' in store data!
Warning (.../hempGreenhouse.xml): No categories defined in store data! Using 'misc' instead!
```

Fix applied:

```text
mod version updated to 0.2.3.0
store category changed from greenhouses back to productionPoints
Blender greenhouse generator output path fixed
Blender pallet generator output path fixed
greenhouse top/front signs removed
pallet top signs removed; front labels kept
```

## Phase 2.4 Blender Roof / Local Descriptor Test

The Blender model generated successfully, but the material pass made the roof issue obvious: the roof read like a flipped/floating flat panel instead of the earlier greenhouse roof shape.

Fix applied:

```text
mod version updated to 0.2.4.0
modDesc descVersion returned to 91 for the current local FS25 test setup
Blender greenhouse script marked for Blender 4.2 LTS
flat floating roof panel removed
curved polycarbonate roof mesh added
roof ribs moved up to sit on the wall tops
no-sign greenhouse look kept
```

## Active Files

```text
FS25_GreenHorizonIndustries/modDesc.xml
FS25_GreenHorizonIndustries/placeables/greenhouses/hempGreenhouse.xml
FS25_GreenHorizonIndustries/xml/productions/hempGreenhouseRecipes.xml
tools/blender/create_green_horizon_greenhouse.py
tools/blender/create_green_horizon_pallets.py
```

## Where To Look In Game

Use the construction menu, not the vehicle/equipment store.

Check:

```text
Construction > Production > Factories / Production Points
```

If the mod list still shows version `0.2.3.0` or older, the old zip/folder is still installed and the new test is not active.

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

1. Delete the old `FS25_Hemp_Industries.zip` or `FS25_GreenHorizonIndustries.zip` from the FS25 mods folder.
2. Re-zip the current active folder as `FS25_GreenHorizonIndustries.zip`.
3. Start FS25.
4. Confirm the mod list shows version `0.2.4.0`.
5. Confirm the missing `icon_mod.dds` error is gone.
6. Confirm the mod still loads the 3 fill types.
7. Check Construction > Production > Factories / Production Points.
8. If the greenhouse still does not show, search the log for:

```text
placeables/greenhouses/hempGreenhouse.xml
storeItem_ghi_hempGreenhouse
production_ghi_hempGreenhouseBasic
Invalid store item
Invalid placeable
Unknown category
Can't load resource
```

## Blender Test Steps

1. Install/open Blender 4.2 LTS for the current FS25/GIANTS workflow.
2. Pull/download the current repo.
3. Run the script from the repo `tools/blender/` folder.
4. Confirm the script saves into:

```text
assets/blender/
```

5. Use Material Preview or Rendered view to see the procedural materials.
6. Confirm the roof is curved and sitting on the wall tops, not floating as a flat panel.

## Expected Risk Areas

- Store item XML may be registered but hidden by production/menu rules.
- Temporary base-game greenhouse visual path may need adjustment.
- Production-point XML may need extra trigger/storage sections once the game parses the placeable.
- Store image path may need replacement with an original DDS asset.
- Blender procedural materials are not final FS25 DDS textures yet.

## Not Yet Included

- Original Green Horizon greenhouse i3d connected to the placeable XML
- Store image DDS
- In-game icon DDS
- Pallet definitions connected to production/storage
- Storage/loading/unloading trigger tuning
- Sell point XML
- Final production economy balancing
