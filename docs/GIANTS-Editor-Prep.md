# GIANTS Editor Prep Notes

This is the next-stage plan after the Blender greenhouse model looks right.

## Current Status

The project currently has a Blender concept model and a temporary FS25 placeable XML.

The model is not connected to the in-game placeable yet. The current in-game greenhouse XML still uses a temporary base-game visual reference until the original Green Horizon `.i3d` is exported and tested.

## Blender 4.2 LTS Workflow

Use Blender 4.2 LTS for the current export prep unless a newer working GIANTS exporter setup is confirmed.

Recommended script order:

```text
1. tools/blender/create_green_horizon_greenhouse.py
2. Review the model shape/materials in Blender
3. tools/blender/add_giants_editor_helpers.py
4. Review helper positions
5. Export to .i3d later with the GIANTS Blender exporter
```

## Helper Marker Purpose

The helper script adds a collection named:

```text
GHI_GIANTS_EDITOR_HELPERS
```

These are not final visible game objects. They are named layout markers to make the GIANTS Editor hookup less confusing.

Current helper placeholders:

```text
GHI_ROOT_export_reference
GHI_placeable_collision_placeholder
GHI_player_interaction_trigger_placeholder
GHI_unload_water_trigger_placeholder
GHI_unload_seed_trigger_placeholder
GHI_pallet_spawn_area_placeholder
GHI_buy_marker_placeholder
```

## Suggested Future i3d / XML Mapping

| Blender helper placeholder | Future GIANTS / XML purpose |
| --- | --- |
| `GHI_ROOT_export_reference` | Scene root / export orientation reference |
| `GHI_placeable_collision_placeholder` | Main placeable collision sizing reference |
| `GHI_player_interaction_trigger_placeholder` | Player interaction / production trigger area |
| `GHI_unload_water_trigger_placeholder` | Water unload trigger reference |
| `GHI_unload_seed_trigger_placeholder` | Hemp seed input unload trigger reference |
| `GHI_pallet_spawn_area_placeholder` | Output pallet spawn reference |
| `GHI_buy_marker_placeholder` | Store/buy/placement visual reference |

## Do Not Upload Base Game Assets

Do not upload GIANTS base-game files or extracted assets to this repository.

Allowed:

```text
Original scripts
Original Blender files
Original XML
Original DDS files we create
Documentation
```

Not allowed:

```text
Copied GIANTS base-game i3d files
Copied GIANTS base-game textures
Extracted base-game meshes
Extracted base-game XML used as a full replacement
```

Base-game files can be used locally as references only.

## Before Exporting

Confirm in Blender:

- Slab sits flat on the grid.
- Roof is curved and seated on the wall tops.
- No unwanted signs are present.
- Materials are visible in Material Preview or Rendered view.
- Scale feels close to an FS greenhouse footprint.
- Helper placeholders are not blocking the look of the model.

## After Exporting

Planned future file location:

```text
FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d
```

Planned future XML swap:

```xml
<filename>placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d</filename>
```

Only do this after the `.i3d` exists in the mod folder and loads cleanly in GIANTS Editor.

## First In-Game i3d Test Goal

The first goal is not full production function. The first goal is only:

```text
The original Green Horizon greenhouse visual loads in FS25 without missing-resource errors.
```

After that works, tune:

```text
collision
placement areas
clear areas
trigger nodes
pallet spawn nodes
production storage
store image/icon
```
