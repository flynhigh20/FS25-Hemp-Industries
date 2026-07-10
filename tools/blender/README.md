# Blender Tool Notes

## Greenhouse — One Main Script

Use Blender `4.2 LTS` and run:

```text
create_green_horizon_greenhouse.py
```

The main script now creates the complete working model source in one pass:

- concrete slab and curbs
- greenhouse frame and curved roof hoops
- transparent roof and wall panels
- grow beds and hemp concept plants
- water tank and control box
- grow lights and wiring
- FS25-style placement, trigger, storage, spawn, plant, and collision nodes
- perimeter wall collision with an open doorway instead of one solid collision box

It saves:

```text
assets/blender/green_horizon_hemp_greenhouse.blend
```

No greenhouse panel, wiring, helper-marker, or post-export patch script is required.

## Export to GIANTS

1. Run `create_green_horizon_greenhouse.py`.
2. Open the generated `.blend` and inspect the model.
3. Export/select the root object named:

```text
greenHorizonHempGreenhouse
```

4. Save the exported game model directly into:

```text
FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d
```

5. When asked by GIANTS:

```text
Save relative paths: Yes
Save game paths: No
```

6. Keep the generated shapes file beside the i3d:

```text
greenHorizonHempGreenhouse.i3d.shapes
```

The active placeable XML already contains mappings for the deterministic helper hierarchy produced by the main script.

## Product Pallets

The separate pallet generator is still available:

```text
create_green_horizon_pallets.py
```

It saves:

```text
assets/blender/green_horizon_product_pallets.blend
```

The current greenhouse recipes sell outputs directly during early testing, so custom product pallets are not required for the first in-game model load.

## Materials and Textures

The generator currently uses Blender materials. Use Material Preview or Rendered view to inspect them. Final optimized FS25 DDS texture work remains a later art pass.

## Fruit-Type Reminder

`FS25_GreenHorizonIndustries/xml/fruitTypes.xml` is a prepared draft only. A real field crop also needs foliage textures, growth states, density-map channels, destruction settings, cutter effects, and vehicle compatibility. The greenhouse can be tested before that field-crop stack is activated.
