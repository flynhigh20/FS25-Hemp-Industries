# Procedural Greenhouse Texture Notes

## What Was Added

The greenhouse generator now creates procedural Blender materials through Python. These are not final FS25 DDS texture files yet, but they make the model look much closer to the intended Green Horizon style while we build and test.

Current procedural materials include:

- smoky green polycarbonate greenhouse panels
- satin black powder-coated metal frame
- mottled poured concrete foundation
- chunky dark grow-bed soil
- industrial hemp leaf color variation
- fiber-like hemp stems
- scuffed blue water tank
- painted Green Horizon sign panel
- warm raised sign lettering
- amber emissive grow light strips
- black rubber door/panel gasket seams

## Why Procedural First

Procedural materials are fast for concept work because they are created directly in Blender by the script. This lets us keep improving the model without needing finished DDS files yet.

## Later FS25 Asset Pass

Before the model is final in-game, these procedural materials should be converted or replaced with proper game-ready assets:

- diffuse/albedo DDS
- normal DDS
- specular/roughness DDS if needed
- collision mesh
- i3d material paths
- store image DDS
- icon DDS

## Script To Run

Run this first:

```text
create_green_horizon_greenhouse.py
```

It builds the greenhouse, assigns materials, adds panel seams, and saves:

```text
assets/blender/green_horizon_hemp_greenhouse.blend
```
