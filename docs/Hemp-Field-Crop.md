# Industrial Hemp Field Crop

## Current Status

The greenhouse uses the active `HEMP` fill type, but field hemp remains intentionally inactive. The project now has source generators and synchronized planning files for foliage, icons, cutter effects, growth, and map integration without linking them into gameplay XML early.

## Prepared Files

```text
FS25_GreenHorizonIndustries/xml/fruitTypes.xml
FS25_GreenHorizonIndustries/xml/growth/hempGrowth.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempFoliagePlan.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempFieldIntegrationPlan.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempMapRegistrationDraft.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempCutterEffectsPlan.xml
FS25_GreenHorizonIndustries/ui/hempIconManifest.xml
```

Source generators:

```text
tools/blender/create_hemp_foliage.py
tools/blender/create_hemp_crop_icons.py
tools/blender/create_hemp_cutter_effects.py
```

Cross-file validator:

```text
tools/windows/check_hemp_field_foundation.ps1
```

## Draft Crop Contract

```text
4 state channels
7 living growth states
State 7 = mature / harvest ready
State 8 = withered
State 9 = cut
First field output = HEMP
First harvest transition = state 7 to state 9
```

The first field version is planned as one straightforward seeding and grain-style harvesting workflow. Specialized biomass, flower, and fiber-windrow harvesting remain separate later workflows.

## Foliage Work

The foliage generator creates:

- Near-view crossed cards for all nine states.
- One distance card per state.
- Shared diffuse-alpha and normal atlases.
- Reduced-size distance diffuse and normal textures.
- A Blender source file for visual inspection.

The foliage XML plan keeps state numbers, card counts, heights, atlas tiles, and activation gates synchronized.

## Crop and Product Icons

The icon generator creates transparent source PNGs for:

- Industrial Hemp.
- Hemp Seed.
- Hemp Biomass.
- Hemp Fiber.
- Hemp Flower.
- Hemp Oil.
- The field-crop menu.
- The crop calendar.

These icons are not linked to `fillTypes.xml`, `fruitTypes.xml`, or `modDesc.xml` yet. Final FS25 image format and exact icon XML keys still need local verification.

## Cutter Effects

The cutter-effect generator creates source textures for:

- Chaff.
- Stem shards.
- Leaf fragments.
- Dust.

The effect plan defines an initial mature-crop route, two future equipment profiles, particle budgets, LOD distances, sound targets, and activation requirements. It is a project plan rather than active GIANTS effect XML.

## Required Before Activation

1. Run and visually inspect all three source generators.
2. Convert or optimize final textures into the verified FS25 formats.
3. Select a dedicated test map.
4. Add a hemp foliage layer and reserve four density-map state channels.
5. Verify the exact FS25 fruit, foliage, growth, icon, and cutter-effect XML schemas from locally installed game references.
6. Select and configure one seeder or planter workflow.
7. Select and configure one harvester and header workflow.
8. Add mature-state harvesting effects and state-9 cut behavior.
9. Configure crop destruction and trampling masks.
10. Test planting, growth, harvesting, withering, save/reload, multiplayer, and console performance.
11. Only then link the field crop through the appropriate map or crop-loading system.

## Safety Rule

Do not activate `xml/fruitTypes.xml` through `modDesc.xml` merely because the drafts parse. A true field fruit requires map-level foliage and density-map integration. Activating it early can prevent maps or savegames from loading.
