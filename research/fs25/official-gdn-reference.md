# Official GIANTS FS25 Reference Notes

This file records the official GIANTS sources used for Green Horizon Industries. Prefer these FS25 sources over older FS17/FS19 examples whenever their XML, shaders, or engine behavior differ.

## I3D scenegraph and functional nodes

- [I3D format documentation](https://gdn.giants-software.com/documentation_i3d.php)
- I3D is XML. Its scenegraph stores the transform hierarchy, shapes, materials, dynamics, animation, and user attributes.
- TransformGroup parent/child order is significant when XML mappings address nodes by index.
- Stable functional nodes should be named, grouped, and kept separate from decorative meshes.
- Trigger and collision behavior belongs on the intended transform or shape; non-renderable functional nodes should not be confused with visible geometry.
- File references must remain relative and valid inside the packaged ZIP.

Project rule: after every Blender or GIANTS Editor export, verify every `i3dMapping` against the newly exported scenegraph before packaging. Do not assume old child indexes survived an export.

## FS25 mapping tutorial: selling stations

- [Adding a selling station](https://gdn.giants-software.com/videoTutorials2.php?s=1&p=0&c=7&LANGUAGE=en)
- GIANTS recommends importing functional base-game models or using preconfigured placeables with built-in functionality.
- Selling, loading, and unloading functionality is connected through I3D mappings and XML.
- Structures and functional nodes should be organized under clearly named Transform Groups.

Project rule: compare greenhouse and factory production/pallet structures with a working FS25 base-game placeable before inventing a new hierarchy.

## FS25 modding toolchain

- [Familiarize with the Modding Tools](https://gdn.giants-software.com/videoTutorials2.php?s=2&p=0&c=1&LANGUAGE=en)
- Official workflow: Blender, GIANTS I3D Exporter, GIANTS Editor, and GIANTS Studio.
- Blender establishes geometry, pivots, and hierarchy; GIANTS Editor verifies the exported runtime scene; XML connects functionality.

Project rule: Blender is the source of truth for model structure, but the exported I3D and FS25 log are the source of truth for runtime mappings.

## Vehicle functions and fill systems

- [Implementing vehicle functions](https://gdn.giants-software.com/videoTutorials2.php?s=2&p=0&c=7&LANGUAGE=en)
- Relevant concepts include work areas, AI collision, visual effects, and fill volumes.
- Vehicle-specific XML should not be copied directly into placeables, but the node discipline and fill-volume workflow remain useful for future Phase 4 equipment.

Project rule: postpone tractor/harvester integration until the greenhouse/CBD loop is regression-tested. For future equipment, build functional nodes and XML together rather than adding them after the finished model.

## Animation

- [Animating your vehicle](https://gdn.giants-software.com/videoTutorials2.php?s=2&p=0&c=8&LANGUAGE=en)
- Animation setup covers stable pivots, moving parts, control of the motion process, and sounds.

Project rule: greenhouse and factory doors must animate dedicated door assemblies around correct pivots. Never use zero-based keyframes when the exported node has a non-zero closed translation unless the XML intentionally uses relative animation.

## Extra visual features

- [Adding extra vehicle features](https://gdn.giants-software.com/videoTutorials2.php?s=2&p=0&c=9&LANGUAGE=en)
- Covers visual lights, license plates, and dashboards.

Project rule: these features are optional polish. Do not add lights or dashboards until functional triggers, collisions, pallets, and production behavior are stable.

## Legacy Lua engine tutorial

- [Basic setup and loading I3D files](https://gdn.giants-software.com/tutorial01.php)
- Useful concepts: engine node IDs/handles, linking loaded I3D scenes to the world root, child indexing, frame updates, and input callbacks.
- This is a low-level standalone-engine tutorial, not an FS25 placeable specialization template.

Project rule: use it to understand scenegraph IDs and child order, but use FS25 LuaDoc and current base-game specializations before adding custom Lua to the mod.

## Current Green Horizon implications

1. Preserve the confirmed greenhouse water, seed, and wrench nodes.
2. Verify pallet spawn start/end nodes are direct nested children and that XML mappings point to the exported indexes.
3. Register every custom pallet XML as a hidden store item and link it from its fill type.
4. Use `Storing` for physical pallets and `Distributing` for production-chain transfer.
5. Existing savegames retain output-mode state; XML output-order changes may require toggling the recipe mode again.
6. Package and install the current ZIP before every test; never test an older ZIP by accident.
7. Review `log.txt` after each test and treat it as the runtime authority.
