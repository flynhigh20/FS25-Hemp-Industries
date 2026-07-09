# Phase 3 Upgradeable CBD Plant / Selling Point Plan

This is a planning document for the phase after the current greenhouse visibility and Blender model tests.

## Short Answer

Yes, the project can include an upgradeable-style CBD plant or selling point.

For a console-friendly ModHub target, the safest design is not a custom scripted upgrade button. The safer design is a tiered XML/placeable system that feels upgradeable to the player while staying script-light and asset-light.

## Why Tiered Placeables Are Safer

A true in-place upgrade system may require custom scripts, custom specializations, or complex configuration logic. That increases risk for console approval.

A tiered placeable system can be built with normal XML patterns and shared assets:

```text
Tier 1: Hemp Drop-Off / Local Buyer
Tier 2: CBD Processing Plant
Tier 3: CBD Distribution Center
```

The player experience still feels like upgrading:

```text
start small -> earn money -> sell/replace or place the next tier -> process more products
```

But the technical implementation stays simpler.

## Recommended Direction

Build the **CBD Plant** as the main upgrade path, not the basic selling point.

Reason:

- A selling point is mostly an endpoint.
- A CBD plant creates gameplay progression.
- A CBD plant can accept hemp/biomass and produce higher-value goods.
- A CBD plant can share model parts, textures, and XML structure across tiers.

The selling point can still exist, but it should stay lightweight.

## Proposed Upgrade Ladder

### Tier 1: Hemp Buyer / Drop-Off

Purpose:

```text
Early-game selling point for raw hemp and hemp biomass.
```

Inputs accepted:

```text
HEMP
GHI_HEMP_BIOMASS
```

Outputs:

```text
Money only
```

Asset plan:

```text
small booth / scale / sign / unload pad
very low geometry
shared texture atlas
```

### Tier 2: CBD Processing Plant

Purpose:

```text
Turns raw hemp into CBD product.
```

Inputs:

```text
HEMP
WATER
possibly GHI_HEMP_BIOMASS
```

Outputs:

```text
GHI_CBD_EXTRACT or GHI_CBD_OIL
```

Asset plan:

```text
small industrial shed
one or two tanks
pallet output area
same material set as greenhouse family
```

### Tier 3: CBD Distribution Center

Purpose:

```text
Higher-capacity processing and/or premium sale route.
```

Inputs:

```text
HEMP
GHI_HEMP_BIOMASS
GHI_CBD_EXTRACT or GHI_CBD_OIL
possibly packaging material later
```

Outputs:

```text
GHI_CBD_PRODUCTS
higher-value sale product
```

Asset plan:

```text
same base plant model with extra tanks/loading dock details
reuse textures from Tier 2
minimal added geometry
```

## Fill/Product Naming Ideas

Keep names plain and certification-safe:

```text
GHI_CBD_EXTRACT
GHI_CBD_OIL
GHI_CBD_PRODUCTS
```

Avoid overcomplicating the product list too early.

Suggested first new product:

```text
GHI_CBD_OIL
```

Suggested later product:

```text
GHI_CBD_PRODUCTS
```

## Console-Friendly Implementation Rules

Use XML and shared assets wherever possible.

Avoid:

```text
custom Lua scripts
scripted upgrade UI
many unique textures
high-poly decorative objects
separate texture sets for every tier
large 4K textures
unnecessary animation
lots of separate small mesh nodes
```

Prefer:

```text
separate tiered placeables
shared i3d model family
shared material names
shared texture atlas
low-poly geometry
small DDS textures
simple production recipes
simple store items
clear fill type names
```

## Suggested XML Structure Later

Potential folders:

```text
FS25_GreenHorizonIndustries/placeables/sellPoints/hempBuyer.xml
FS25_GreenHorizonIndustries/placeables/productions/cbdPlantSmall.xml
FS25_GreenHorizonIndustries/placeables/productions/cbdPlantLarge.xml
FS25_GreenHorizonIndustries/xml/productions/cbdPlantRecipes.xml
```

Potential future store items:

```xml
<storeItem xmlFilename="placeables/sellPoints/hempBuyer.xml"/>
<storeItem xmlFilename="placeables/productions/cbdPlantSmall.xml"/>
<storeItem xmlFilename="placeables/productions/cbdPlantLarge.xml"/>
```

Do not add these to the live mod until the current greenhouse placeable test passes.

## First Implementation Goal

After the greenhouse passes testing, the next implementation should be:

```text
Add GHI_CBD_OIL as a fill/product type.
Add a small CBD Plant production XML.
Use placeholder/simple visual first.
Confirm it appears in Construction > Production.
Confirm recipe loads without log errors.
```

Only after that should we add the larger tier or upgrade-style progression.

## Upgrade Feel Without Custom Scripts

Use these design tricks to make tiered placeables feel like upgrades:

```text
Tier 1 has low capacity and slow throughput.
Tier 2 has better capacity and adds CBD oil production.
Tier 3 has higher throughput and may produce packaged CBD products.
All tiers use similar branding/model style.
Store descriptions call them Small, Standard, and Expanded.
Pricing makes the player progress naturally.
```

## Current Recommendation

Make the **CBD Plant upgradeable-style** first.

Keep the selling point simple:

```text
Hemp Buyer / Hemp Market
```

Then let the CBD Plant become the real progression system.
