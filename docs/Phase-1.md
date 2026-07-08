# Phase 1 / Alpha 0.1 — Foundation

## Goal

Get Green Horizon Industries into a clean FS25 mod-folder structure that can be copied, zipped, and tested without dragging extra project files into the game mod folder.

## Active Folder

```text
FS25_GreenHorizonIndustries/
```

This folder is the active mod root.

## Current Contents

```text
FS25_GreenHorizonIndustries/
├── modDesc.xml
└── xml/
    └── fillTypes.xml
```

## Completed

- Renamed the working mod folder from `mod/` to `FS25_GreenHorizonIndustries/`.
- Added Phase 1 `modDesc.xml` foundation.
- Added initial fill types:
  - `HEMP` — Industrial Hemp
  - `GHI_HEMP_SEED` — Hemp Seed
  - `GHI_HEMP_BIOMASS` — Hemp Biomass
- Updated README, roadmap, changelog, and architecture docs.

## Next Test Steps

1. Download or clone the repository.
2. Copy only `FS25_GreenHorizonIndustries/` into the FS25 mods folder, or zip that folder as `FS25_GreenHorizonIndustries.zip`.
3. Start FS25 and check whether the mod appears in the mod list.
4. If it fails, check the game log for XML errors.
5. Confirm whether `descVersion="91"` is correct for the installed FS25 build.

## Not Yet Included

- `icon_mod.dds`
- Greenhouse production XML
- Placeable greenhouse building
- Fruit/crop registration
- Crop textures and growth stages
- Custom harvester or equipment
- Console packaging checks
