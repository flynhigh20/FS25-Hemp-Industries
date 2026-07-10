# Blender Tool Notes

Use Blender `4.2 LTS` for all scripts in this folder.

## Greenhouse — Main Script

Run:

```text
create_green_horizon_greenhouse.py
```

The script creates the peaked glass greenhouse, materials, grow beds, hemp concept plants, lighting, wiring, and FS25-style helper hierarchy. It saves:

```text
assets/blender/green_horizon_hemp_greenhouse.blend
```

Generated greenhouse textures are written to:

```text
FS25_GreenHorizonIndustries/placeables/greenhouses/textures/
```

### Greenhouse Export

1. Run the script.
2. Open the generated blend file in Material Preview.
3. Export the root `greenHorizonHempGreenhouse` directly to:

```text
FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d
```

4. Choose relative paths `Yes` and game paths `No`.
5. Open the i3d in GIANTS Editor, inspect it, and save over the same file.
6. Keep `greenHorizonHempGreenhouse.i3d.shapes` beside the i3d.

## Industrial Hemp Foliage Source

Run:

```text
create_hemp_foliage.py
```

It creates source cards and atlas textures for nine planned field-crop states:

```text
1 emerged
2 sprout
3 juvenile
4 vegetative
5 pre-flower
6 flowering
7 mature / harvest ready
8 withered
9 cut
```

It saves:

```text
assets/blender/green_horizon_hemp_foliage.blend
```

Generated foliage textures are written to:

```text
FS25_GreenHorizonIndustries/foliage/hemp/textures/
```

Running this script does not activate the field crop.

## Crop and Product Icons

Run:

```text
create_hemp_crop_icons.py
```

It creates transparent source PNG icons for:

```text
HEMP
GHI_HEMP_SEED
GHI_HEMP_BIOMASS
GHI_HEMP_FIBER
GHI_HEMP_FLOWER
GHI_HEMP_OIL
HEMP_CROP
HEMP_CALENDAR
```

Output folder:

```text
FS25_GreenHorizonIndustries/ui/icons/
```

The icon manifest is:

```text
FS25_GreenHorizonIndustries/ui/hempIconManifest.xml
```

The icons remain unlinked until the final image format and exact FS25 fill-type, crop-menu, and calendar XML keys are verified.

## Hemp Cutter-Effect Sources

Run:

```text
create_hemp_cutter_effects.py
```

It creates source textures for:

```text
hemp chaff
stem shards
leaf fragments
dust
```

The preview source file is:

```text
assets/blender/green_horizon_hemp_cutter_effects.blend
```

Generated textures are written to:

```text
FS25_GreenHorizonIndustries/foliage/hemp/effects/textures/
```

The effect plan is:

```text
FS25_GreenHorizonIndustries/foliage/hemp/hempCutterEffectsPlan.xml
```

These are source assets only. Do not copy the plan into active vehicle or fruit XML until the exact FS25 cutter-effect schema is verified from the locally installed game and a supported harvester/header workflow has been selected.

## Product Pallet Source Set

Run:

```text
create_green_horizon_pallets.py
```

The script creates six product roots:

```text
pallet_hemp
pallet_seed
pallet_biomass
pallet_fiber
pallet_flower
pallet_oil
```

It includes helper nodes for fill units, fill triggers, exact-fill roots, discharge nodes, dynamic mounting, collisions, tension belts, and raycasting. It also creates image-based materials for wood, clear wrap, labels, straps, products, and oil drums.

The combined source file is:

```text
assets/blender/green_horizon_product_pallets.blend
```

Generated pallet textures are written to:

```text
FS25_GreenHorizonIndustries/pallets/textures/
```

### Pallet Export

The six roots are spaced apart for preview. Before exporting one root:

1. Select the required root.
2. Press `Alt+G` so its location becomes `0, 0, 0`.
3. Export only that root and its children.
4. Save to the matching filename under:

```text
FS25_GreenHorizonIndustries/pallets/i3d/
```

Expected exports:

```text
pallet_hemp      -> hempPallet.i3d
pallet_seed      -> seedPallet.i3d
pallet_biomass   -> biomassPallet.i3d
pallet_fiber     -> fiberPallet.i3d
pallet_flower    -> flowerPallet.i3d
pallet_oil       -> oilPallet.i3d
```

After each export, check the actual i3d node order before activating its pallet XML or linking it from `fillTypes.xml`.

## Field Foundation Check

Run from PowerShell:

```text
tools/windows/check_hemp_field_foundation.ps1
```

It checks that fruit states, foliage states, map registration, icon entries, and cutter routing agree while confirming that the field crop remains inactive.

## Inactive Expansion Files

These files are intentionally packaged but not loaded by `modDesc.xml`:

```text
FS25_GreenHorizonIndustries/xml/fruitTypes.xml
FS25_GreenHorizonIndustries/xml/growth/hempGrowth.xml
FS25_GreenHorizonIndustries/xml/productions/hempProcessingRecipes.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempFoliagePlan.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempFieldIntegrationPlan.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempMapRegistrationDraft.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempCutterEffectsPlan.xml
FS25_GreenHorizonIndustries/ui/hempIconManifest.xml
FS25_GreenHorizonIndustries/pallets/xml/*.xml
```

They remain inactive until the corresponding model, foliage, map, UI, effect, pallet, and gameplay requirements have been tested.
