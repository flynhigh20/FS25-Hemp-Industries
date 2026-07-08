# Greenhouse Blender Export Notes

## Orientation

The current repo generator script is intended to build the greenhouse flat in Blender with:

```text
X = width / left-right
Y = depth / front-back
Z = height / up-down
```

The concrete slab should sit flat on the Blender grid. If the model is standing up before export, that is a Blender model-orientation issue, not a GIANTS export issue.

## If The Greenhouse Is Standing Up In Blender

Try this first:

1. Press `A` to select all greenhouse objects.
2. Press `R`.
3. Press `X`.
4. Type `90`.
5. Press `Enter`.
6. If it flips the wrong way, undo and use `-90` instead.
7. Once the slab is flat on the grid, press `Ctrl + A` and choose `Rotation` to apply the rotation.
8. Save a fixed copy of the blend file.

The most likely fixes are:

```text
Rotate X 90 degrees
or
Rotate X -90 degrees
```

If X does not fix it, try the same idea on Y:

```text
Rotate Y 90 degrees
or
Rotate Y -90 degrees
```

## After Blender Looks Correct

Only export after the model sits correctly in Blender.

Then:

1. Export using the GIANTS Blender Exporter.
2. Open the i3d in GIANTS Editor.
3. If it stands up only after export, fix the exporter axis/root object.
4. Re-export once the orientation is correct.

## Current Repo Status

The in-game Phase 2 XML currently uses a temporary base-game greenhouse visual path. The Blender greenhouse script is the real original model direction, but it still needs:

- i3d export
- collision setup
- placement/terrain decal setup
- trigger nodes
- production/storage nodes
- final scale check
