# Green Horizon Product Pallet Notes

## Script

Run this in Blender:

```text
tools/blender/create_green_horizon_pallets.py
```

It generates:

```text
assets/blender/green_horizon_product_pallets.blend
```

## Pallet Variants

The script currently creates three concept pallets:

- `INDUSTRIAL HEMP`
- `HEMP BIOMASS`
- `HEMP SEED INPUT`

The seed pallet is treated as an input-material concept, not as a sellable money product. It is included for greenhouse/production gameplay testing and can later become strain-specific if the mod adds different hemp seed types.

## Text Fixes

The pallet labels are intentionally simple and readable:

- `GREEN HORIZON`
- product title
- lot/code line such as `LOT GH-HEMP | FS25`

Front labels are placed on the negative-Y face of the pallet. Top labels are placed flat on top so the pallet can be recognized from above in Blender/GIANTS Editor.

## Procedural Materials

The pallet generator uses procedural Blender materials for:

- rough reused pallet wood
- dark end-grain/scuffed pallet blocks
- cloudy clear pallet wrap
- cream shipping label stock
- dark green printed label text
- compressed industrial hemp product
- tan-green hemp biomass bales
- natural canvas seed bags
- black plastic pallet straps
- Green Horizon brand panels

## Later FS25 Asset Pass

Before final in-game release, convert or replace these procedural materials with game-ready assets:

- diffuse/albedo DDS
- normal DDS
- specular/roughness DDS if needed
- i3d material paths
- pallet collision mesh
- store/shop icons if pallets become store-visible
