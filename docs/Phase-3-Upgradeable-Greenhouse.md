# Phase 3 Upgradeable Greenhouse Plan

This is a future design plan for making the Hemp Greenhouse feel upgradeable without forcing the player to buy a completely bigger building.

## Short Answer

Yes, an upgradeable-style greenhouse is a strong idea.

For a console-friendly target, the safest approach is not a heavy custom scripted upgrade UI. The safer approach is to make upgrades with XML-friendly placeables, recipes, and shared lightweight assets.

## Design Goal

The player should feel like they are improving the same greenhouse over time:

```text
Basic greenhouse -> irrigation -> grow lights -> climate control -> advanced racks
```

But the technical setup should stay simple enough for console goals:

```text
simple XML
few placeables
shared textures
low-poly model pieces
minimal custom scripting
```

## Final Direction: Option B + Option C Combo

Use a combo of:

```text
Option B: small add-on upgrade modules
Option C: higher-tier greenhouse recipes
```

The modules give the player a visual reason to believe the greenhouse has been upgraded.

The recipes give the upgrade real gameplay value.

In plain English:

```text
The upgrade module shows what changed.
The upgraded recipe is what makes the greenhouse perform better.
```

This is the best balance for the project because it feels like a real upgrade system while staying safer for console optimization than a custom scripted upgrade menu.

## Best Console-Safe Options

### Option A: Same-Footprint Upgrade Tiers

This uses several greenhouse versions that are the same size/footprint, but each version looks more upgraded.

Example:

```text
Hemp Greenhouse - Basic
Hemp Greenhouse - Irrigated
Hemp Greenhouse - Climate Controlled
Hemp Greenhouse - Advanced
```

Player flow:

```text
sell old greenhouse -> place upgraded version in same spot
```

Pros:

```text
simple XML
safe for console
easy to test
easy to balance
no custom upgrade script needed
```

Cons:

```text
not a true in-place upgrade
player has to replace the building manually
```

### Option B: Add-On Upgrade Modules

This keeps one main greenhouse and adds small upgrade modules nearby.

Example modules:

```text
Irrigation Control Box
Grow Light Power Cabinet
Climate Control Unit
Nutrient Tank
Extra Rack Kit
```

Player flow:

```text
place greenhouse
place upgrade modules beside/behind it
activate better production recipes or use module buildings as small productions
```

Pros:

```text
feels like upgrading the same building
visual add-ons are small
can reuse textures
console-friendly if kept simple
```

Cons:

```text
true automatic interaction between main greenhouse and module may be limited without scripts
modules may need to work as visual placeables or as small supporting production points
```

### Option C: Recipe-Based Upgrades

This keeps one greenhouse model, but adds higher-tier recipes that require extra inputs.

Example recipes:

```text
Basic Hemp Growth
Irrigated Hemp Growth
LED Hemp Growth
Climate-Controlled Hemp Growth
```

Example inputs:

```text
WATER
GHI_HEMP_SEED
LIQUIDFERTILIZER
ELECTRICCHARGE or a future safe input if supported
```

Pros:

```text
very XML-friendly
no extra building models required
low slot impact
simple console path
```

Cons:

```text
less visual upgrade feeling unless combined with small add-on props
```

## How The B + C Combo Works

The main greenhouse stays as the primary production point.

Upgrade modules are small placeables that sit near the greenhouse and visually represent improvements.

The greenhouse gets multiple production recipes. The player chooses the recipe that matches the upgrade level they have built.

Example flow:

```text
Build Hemp Greenhouse.
Run Basic Hemp Growth recipe.
Buy/place Irrigation Upgrade Module.
Switch greenhouse to Irrigated Hemp Growth recipe.
Buy/place Grow Light Upgrade Module.
Switch greenhouse to LED Hemp Growth recipe.
Buy/place Climate Control Upgrade Module.
Switch greenhouse to Climate-Controlled Hemp Growth recipe.
```

This does not require the module to automatically unlock the recipe at first. The store description and recipe names can guide the player until we know what FS25 allows cleanly without scripts.

## Recommended Direction

Use the B + C hybrid:

```text
One main Hemp Greenhouse
Small visual upgrade modules
Higher-tier recipes that represent those upgrades
```

This gives the best feel without jumping straight into risky custom scripts.

## Suggested Upgrade Ladder

### Level 1: Basic Hemp Greenhouse

Visual:

```text
basic greenhouse
simple beds
water barrel or basic tank
```

Recipe:

```text
WATER + GHI_HEMP_SEED -> HEMP + GHI_HEMP_BIOMASS
```

Gameplay:

```text
slow output
small storage
low cost
```

### Level 2: Irrigation Upgrade

Visual module:

```text
small irrigation pump/control box
small side water tank
thin pipe detail
```

Recipe idea:

```text
WATER + GHI_HEMP_SEED -> more HEMP + GHI_HEMP_BIOMASS
```

Gameplay:

```text
better throughput
slightly higher water use
```

### Level 3: Grow Light Upgrade

Visual module:

```text
small power cabinet
subtle LED strips inside greenhouse
```

Recipe idea:

```text
WATER + GHI_HEMP_SEED + extra input -> higher HEMP output
```

Gameplay:

```text
faster cycle
higher upkeep or extra input
```

### Level 4: Climate Control Upgrade

Visual module:

```text
fan/HVAC box
small duct detail
control panel
```

Recipe idea:

```text
WATER + GHI_HEMP_SEED + fertilizer-like input -> premium output balance
```

Gameplay:

```text
best greenhouse throughput
higher cost
higher input demand
```

## Console Optimization Rules For This Idea

Keep upgrade modules tiny and reusable.

Prefer:

```text
same greenhouse base mesh
shared material set
small repeated props
simple box collision
few nodes
simple XML recipes
```

Avoid:

```text
custom upgrade scripts at first
large unique textures per upgrade
high-poly interior clutter
heavy animations
many separate visible objects
```

## Store / Player Guidance

Because the first version may not automatically lock recipes behind modules, store names and descriptions need to clearly explain the intended progression.

Example store names:

```text
Hemp Greenhouse
Irrigation Upgrade Module
Grow Light Upgrade Module
Climate Control Upgrade Module
```

Example greenhouse recipe names:

```text
Basic Hemp Growth
Irrigated Hemp Growth
LED Hemp Growth
Climate-Controlled Hemp Growth
```

Example store description idea:

```text
Place this module beside your Hemp Greenhouse, then use the matching greenhouse recipe for improved output.
```

## How To Make It Feel Like A Real Upgrade

Even without true scripted upgrades, the player can feel progression through:

```text
store descriptions
pricing
higher recipe throughput
small visual modules
consistent branding
same footprint
same greenhouse family
```

## First Implementation After Current Testing

Do not add this before the current greenhouse test passes.

After the greenhouse appears correctly in FS25, the first upgrade test should be:

```text
Add one small Irrigation Upgrade Module as a simple placeable.
Keep it visual-only first.
Add an Irrigated Hemp Growth recipe to the greenhouse.
Confirm the module appears in Construction.
Confirm the greenhouse recipe appears/loads.
Confirm no log errors.
Then decide whether the module should stay visual-only, work as a supporting mini-production, or later become a true scripted upgrade if needed.
```

## Preferred Long-Term Plan

1. Get main greenhouse working.
2. Add real greenhouse i3d.
3. Add one small visual Irrigation Upgrade Module.
4. Add Irrigated Hemp Growth recipe to the greenhouse.
5. Add grow light module and LED Hemp Growth recipe.
6. Add climate control module and Climate-Controlled Hemp Growth recipe.
7. Only consider custom scripted upgrades if XML-only progression feels too limited.

## Current Recommendation

Build the greenhouse upgrade system as:

```text
Main Greenhouse + Small Upgrade Modules + Higher-Tier Recipes
```

That should feel better than only buying bigger greenhouses, while staying cleaner for console optimization.
