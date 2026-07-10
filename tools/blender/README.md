# Blender Tool Notes

## Greenhouse — Main Script

Use Blender `4.2 LTS` and run:

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

## Product Pallet Source Set

Run:

```text
create_green_horizon_pallets.py
```

The script now creates six product roots:

```text
pallet_hemp
pallet_seed
pallet_biomass
pallet_fiber
pallet_flower
pallet_oil
```

It includes export-oriented helper nodes for fill units, fill triggers, exact-fill roots, discharge nodes, dynamic mounting, collisions, tension belts, and raycasting. It also creates image-based materials for wood, clear wrap, labels, straps, products, and oil drums.

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

The matching inactive XML templates are under:

```text
FS25_GreenHorizonIndustries/pallets/xml/
```

After each export, the actual i3d node order must be checked before its pallet XML is activated or linked from `fillTypes.xml`.

## Inactive Expansion Files

These files are intentionally packaged but not loaded by `modDesc.xml`:

```text
FS25_GreenHorizonIndustries/xml/fruitTypes.xml
FS25_GreenHorizonIndustries/xml/growth/hempGrowth.xml
FS25_GreenHorizonIndustries/xml/productions/hempProcessingRecipes.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempFoliagePlan.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempFieldIntegrationPlan.xml
FS25_GreenHorizonIndustries/pallets/xml/*.xml
```

They remain inactive until the corresponding model, foliage, map, pallet, and gameplay requirements have been tested.
