# Industrial Hemp Field Crop

## Current Status

The greenhouse uses the active `HEMP` fill type, but the field crop remains intentionally inactive.

Prepared files:

```text
FS25_GreenHorizonIndustries/xml/fruitTypes.xml
FS25_GreenHorizonIndustries/xml/growth/hempGrowth.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempFoliagePlan.xml
```

## Draft Crop Behavior

- Seeded with normal field equipment after vehicle-category integration.
- Rolling and lime are expected.
- Seven live growth states.
- State 7 is harvest ready.
- State 8 is withered.
- State 9 is the cut state.
- Main planting window targets spring.
- Main harvest window targets late summer and early fall.
- The first field version produces `HEMP` directly.
- A custom hemp-stalk/fiber windrow is deferred until its pickup and processing chain are complete.

## Required Before Activation

1. Create near and distance foliage textures with alpha.
2. Create growth-state foliage meshes/cards.
3. Add the hemp foliage layer and density-map channels to a test map.
4. Add hemp to the correct seeder, header, and harvester categories.
5. Add cutter effects for mature and cut states.
6. Configure destruction and trampling masks.
7. Test planting, growth, harvesting, withering, and savegame reload.
8. Only then wire the fruit type and growth files into the appropriate map or crop-loading system.

## Safety Rule

Do not activate `xml/fruitTypes.xml` through `modDesc.xml` merely because the XML parses. A standalone fill type can load without a map foliage layer, but a true field fruit requires map-level foliage and density-map integration. Activating early can prevent maps or savegames from loading.
