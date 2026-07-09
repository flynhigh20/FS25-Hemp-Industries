# Blender Tool Notes

## Current Scripts

### Greenhouse

Run the greenhouse generator when you want the main Green Horizon greenhouse model:

```text
create_green_horizon_greenhouse.py
```

It creates the greenhouse model scene from scratch, assigns procedural Blender materials, removes the early top/front branding signs, and saves:

```text
assets/blender/green_horizon_hemp_greenhouse.blend
```

### Product Pallets

Run the pallet generator when you want the product pallet concept models:

```text
create_green_horizon_pallets.py
```

It creates Industrial Hemp, Hemp Biomass, and Hemp Seed Input pallets with front labels only, procedural materials, and no top pallet signs. It saves:

```text
assets/blender/green_horizon_product_pallets.blend
```

## Important Texture Note

The current scripts use Blender procedural materials, not external image texture files. In Blender, use Material Preview or Rendered view to see them. Final game-ready DDS textures still need a later pass before the assets are exported for FS25.

## Windows Path / Permission Fix

The scripts now find the repository folder from their own file path and save into `assets/blender/` from there. This avoids the previous Windows error where Blender tried to create `assets` inside a protected launch folder such as Program Files.

## Script Order

The greenhouse script and pallet script are separate generators. They do not need to be run in a specific order unless you intentionally want to combine scenes later.

For greenhouse animation/detail scripts, run the greenhouse generator first. Most animation/detail scripts expect the greenhouse objects to already exist, so running them first can fail or create empty animation tracks.

## Safe Greenhouse Workflow

1. Open Blender.
2. Run `create_green_horizon_greenhouse.py` from the `tools/blender/` folder.
3. Confirm the greenhouse slab is flat on the Blender grid.
4. Use Material Preview or Rendered view to check the procedural materials.
5. Save the `.blend` if you make manual edits.
6. Run any future animation/detail script.
7. Save another copy.
8. Export to `.i3d` only after the model looks right in Blender.

## Safe Pallet Workflow

1. Open Blender.
2. Run `create_green_horizon_pallets.py` from the `tools/blender/` folder.
3. Confirm the front pallet labels are readable.
4. Use Material Preview or Rendered view to check the procedural materials.
5. Save the `.blend` if you make manual edits.
6. Export to `.i3d` only after the pallets look right in Blender.

## Economy / Crop Reminder

- Fill types can show in the economy/price window when they are configured with price/economy data.
- A crop calendar/crop window entry needs a real fruit/crop registration, growth setup, and foliage data.
- Hemp biomass should stay a product/by-product, not a crop.
- Hemp seed should stay an input unless the project later adds strain-specific seed types.
