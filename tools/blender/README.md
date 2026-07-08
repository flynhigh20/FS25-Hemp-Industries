# Blender Tool Notes

## Current Script Order

Run the greenhouse generator first:

```text
create_green_horizon_greenhouse.py
```

That script creates the greenhouse model scene from scratch and saves a `.blend` file.

If an animation or detail script is added later, run it second unless its header says otherwise. Most animation/detail scripts will expect the greenhouse objects to already exist, so running them first can fail or create empty animation tracks.

## Safe Workflow

1. Open Blender.
2. Run `create_green_horizon_greenhouse.py`.
3. Confirm the greenhouse slab is flat on the Blender grid.
4. Save the `.blend`.
5. Run any future animation/detail script.
6. Save another copy.
7. Export to `.i3d` only after the model looks right in Blender.

## Economy / Crop Reminder

- Fill types can show in the economy/price window when they are configured with price/economy data.
- A crop calendar/crop window entry needs a real fruit/crop registration, growth setup, and foliage data.
- Hemp biomass should stay a product/by-product, not a crop.
- Hemp seed should stay an input unless the project later adds strain-specific seed types.
