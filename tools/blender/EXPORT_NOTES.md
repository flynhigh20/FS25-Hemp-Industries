# Greenhouse Blender Export Notes

## Orientation

The greenhouse generator script builds the model upright in Blender with:

```text
X = width / left-right
Y = depth / front-back
Z = height / up-down
```

That means the greenhouse should sit flat on the floor inside Blender.

If the model stands up sideways after export/import into GIANTS Editor or FS25, do not redesign the model. That means the export axis conversion needs correction.

## Axis Fix To Try

For a Blender Z-up model going into a GIANTS/FS-style Y-up scene, try rotating the exported root object:

```text
X rotation: 90 degrees
Y rotation: 0 degrees
Z rotation: 0 degrees
```

If it flips the wrong way, use:

```text
X rotation: -90 degrees
Y rotation: 0 degrees
Z rotation: 0 degrees
```

Then apply transforms before the final i3d export if the exporter requires applied transforms.

## Practical Workflow

1. Run `tools/blender/create_green_horizon_greenhouse.py` in Blender.
2. Confirm the concrete slab is flat on the Blender grid.
3. Export using the GIANTS Blender Exporter.
4. Open the i3d in GIANTS Editor.
5. If it is standing upright/sideways, rotate the root object 90 degrees on X.
6. Re-export once the orientation is correct.

## Important

The in-game Phase 2 XML currently uses a temporary base-game greenhouse visual path. The Blender greenhouse script is the real original model direction, but it still needs:

- i3d export
- collision setup
- placement/terrain decal setup
- trigger nodes
- production/storage nodes
- final scale check
