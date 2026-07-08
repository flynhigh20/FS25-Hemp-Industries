# Green Horizon Industries Architecture

## Project Goal

Create an industrial-hemp expansion for Farming Simulator 25 focused on
agriculture, sustainable materials, production chains, and original equipment.

## Active Mod Folder

```text
FS25_GreenHorizonIndustries/
```

This is the active mod folder and future zip root for FS25 testing.

## Release Structure

### Green Horizon Core Pack
Console-friendly content pack.

Includes:
- Hemp greenhouse production
- Hemp pallets and fill types
- Fiber, seed, oil, hurds, rope, fabric, biomass, and hempcrete
- Factories, sell points, and placeables
- Future equipment and branding assets

### Hemp Field Crop Extension
PC-first extension.

Includes:
- Plantable industrial hemp crop
- Custom foliage and growth stages
- Harvest setup
- Map-specific fruit registration or Lua-based integration
- Precision Farming experiments

## Active Phase 2 Test Loop

The first greenhouse production test uses this loop:

```text
WATER + GHI_HEMP_SEED -> HEMP + GHI_HEMP_BIOMASS
```

The active placeable XML is:

```text
FS25_GreenHorizonIndustries/placeables/greenhouses/hempGreenhouse.xml
```

Recipe balancing notes are kept in:

```text
FS25_GreenHorizonIndustries/xml/productions/hempGreenhouseRecipes.xml
```

## Development Rule

Do not modify Farming Simulator 25 base-game files.

Use base-game files as local references only.
Do not upload GIANTS game files or extracted assets to this public repository.

## Current Status

- Repository initialized
- Branding direction selected
- Research library started
- FS25 test environment being installed
- Core Pack architecture selected
- Phase 1 fill type load confirmed in FS25 log
- Active mod folder renamed to `FS25_GreenHorizonIndustries/`
- Initial fill types added
- Phase 2 hemp greenhouse test XML added
- Field Crop Extension deferred until verified against FS25 map files
