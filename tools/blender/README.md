# Blender Tool Notes

## Greenhouse — One Main Script

Use Blender `4.2 LTS` and run:

```text
create_green_horizon_greenhouse.py
```

The main script creates the greenhouse model source in one pass:

- concrete slab and curbs
- black greenhouse frame
- straight peaked glass gable roof with center ridge
- transparent roof, side, and gable panels
- grow beds and hemp concept plants
- water tank and control box
- grow lights and wiring
- FS25-style placement, trigger, storage, spawn, plant, and collision nodes
- perimeter wall collision with an open doorway instead of one solid collision box
- generated image textures and assigned Blender materials

It saves:

```text
assets/blender/green_horizon_hemp_greenhouse.blend
```

It also creates test-ready PNG material textures here:

```text
FS25_GreenHorizonIndustries/placeables/greenhouses/textures/
```

No greenhouse panel, wiring, material, helper-marker, or post-export patch script is required.

## Greenhouse Export to GIANTS

1. Pull the latest repository files.
2. Run `create_green_horizon_greenhouse.py` so the model and textures are regenerated together.
3. Open the generated `.blend` and use Material Preview to inspect it.
4. Export/select the root object named:

```text
greenHorizonHempGreenhouse
```

5. Save the game model directly into:

```text
FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d
```

6. When asked by GIANTS:

```text
Save relative paths: Yes
Save game paths: No
```

7. Keep the generated shapes file beside the i3d:

```text
greenHorizonHempGreenhouse.i3d.shapes
```

The texture files must remain under the mod's `placeables/greenhouses/textures/` folder. Option 3 checks that the model, shapes file, and material textures are present before packaging.

## Industrial Hemp Foliage Source

Run this separately when working on the future field crop:

```text
create_hemp_foliage.py
```

It creates a source scene containing all nine planned hemp states:

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

The generator builds crossed alpha-card meshes for near LODs, one distance card per state, and UV mapping into a shared foliage atlas. It saves:

```text
assets/blender/green_horizon_hemp_foliage.blend
```

It also writes:

```text
FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_diffuse.png
FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_normal.png
FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_distance_diffuse.png
FS25_GreenHorizonIndustries/foliage/hemp/textures/hempFoliage_distance_normal.png
```

These are source/test assets. Running the generator does not activate field hemp and does not modify `modDesc.xml`.

## Field-Crop Safety

The prepared crop files remain inactive:

```text
FS25_GreenHorizonIndustries/xml/fruitTypes.xml
FS25_GreenHorizonIndustries/xml/growth/hempGrowth.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempFoliagePlan.xml
FS25_GreenHorizonIndustries/foliage/hemp/hempFieldIntegrationPlan.xml
```

A true field crop still needs a test map foliage layer, density-map channels, cutter effects, destruction settings, and vehicle compatibility. Do not activate the fruit type simply because the XML and source assets exist.

## Material Scope

The current scripted textures are the first functional material pass. Final release quality can replace the PNG files with optimized DDS diffuse, normal, and specular maps without rebuilding the model hierarchy.

## Product Pallets

The separate pallet generator remains available:

```text
create_green_horizon_pallets.py
```

It saves:

```text
assets/blender/green_horizon_product_pallets.blend
```

The current greenhouse recipes sell outputs directly during early testing, so custom product pallets are not required for the first in-game model load.
