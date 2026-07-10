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
- generated image textures and assigned Blender materials

It saves:

```text
assets/blender/green_horizon_hemp_greenhouse.blend
```

It also creates test-ready PNG material textures here:

```text
FS25_GreenHorizonIndustries/placeables/greenhouses/textures/
```

Generated materials cover:

```text
polycarbonate glass
black powder-coated frame
concrete
soil
hemp leaves and stems
water tank
rubber seals
wiring
grow lights
```

No greenhouse panel, wiring, material, helper-marker, or post-export patch script is required.

## Export to GIANTS

1. Pull the latest repository files.
2. Run `create_green_horizon_greenhouse.py` again so the model and textures are regenerated together.
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

The texture files must remain under the mod's `placeables/greenhouses/textures/` folder. Option 3 now checks that the model, shapes file, and material textures are all present before packaging.

## Material Scope

The current scripted textures are the first functional material pass. They are image-based rather than Blender-only procedural colors, which gives the exporter real files to reference. Final release quality can later replace these PNG files with optimized DDS diffuse, normal, and specular maps without rebuilding the model hierarchy.

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

## Fruit-Type Reminder

`FS25_GreenHorizonIndustries/xml/fruitTypes.xml` is a prepared draft only. A real field crop also needs foliage textures, growth states, density-map channels, destruction settings, cutter effects, and vehicle compatibility. The greenhouse can be tested before that field-crop stack is activated.
