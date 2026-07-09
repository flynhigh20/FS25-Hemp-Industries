# FS25 Hemp Industries

🚧 Alpha Development  
🖥️ PC Compatible  
🎮 Console Goal  
🌱 Industrial Hemp Expansion  
🚜 Green Horizon Industries

## Current Build

**Phase 2.4 / Alpha 0.2 greenhouse store visibility and Blender roof test is active.**

The active mod folder is:

```text
FS25_GreenHorizonIndustries/
```

This folder is intended to become the final FS25 mod folder/zip root for in-game testing.

## Quick Windows Testing

Package and install the mod with:

```text
tools/windows/package_and_install_mod.bat
```

After running FS25 once, check the filtered log report with:

```text
tools/windows/check_fs25_log.bat
```

Helpful docs:

```text
docs/Windows-Packaging.md
docs/Test-Checklist.md
docs/GIANTS-Editor-Prep.md
tools/blender/README.md
```

## Phase 1 Result

Phase 1 fill type loading has been confirmed by FS25 log output:

```text
Info: Loaded 3 fill types from mod
```

## Phase 2.4 Scope

Phase 2.4 focuses on keeping the Hemp Greenhouse visible in the FS25 construction menu while correcting the Blender greenhouse concept model.

Included now:

- `modDesc.xml` updated to mod version `0.2.4.0`
- `modDesc.xml` descriptor version returned to `91` for the current local FS25 test setup
- Store item wiring for a Hemp Greenhouse
- Hemp Greenhouse category kept as the valid `productionPoints` category
- Greenhouse production placeable XML
- Recipe balance notes XML
- Blender greenhouse generator output-path fix
- Blender pallet generator output-path fix
- Greenhouse Blender script marked for Blender 4.2 LTS workflow
- Curved greenhouse roof restored as a real mesh, with no floating flat roof panel
- Early top/front greenhouse signs removed from the Blender model
- Top pallet signs removed; pallets keep front labels only
- Windows package/install helper added
- Windows FS25 log checker added
- Optional Blender GIANTS Editor helper markers added
- Production input/output loop:
  - Inputs: `WATER`, `GHI_HEMP_SEED`
  - Outputs: `HEMP`, `GHI_HEMP_BIOMASS`

## Where To Look In Game

Check the construction menu, not the normal vehicle/equipment store:

```text
Construction > Production > Factories / Production Points
```

If FS25 still shows the mod as version `0.2.3.0` or older, the old zip/folder is still installed.

Still pending:

- Verify the greenhouse appears in the FS25 construction menu under Production Points
- Confirm the temporary base-game greenhouse visual path loads
- Add original Green Horizon greenhouse model/assets to the placeable XML after i3d export
- Add real DDS store image and icon files
- Add pallets/storage triggers after first placeable test
- Add sell points and economy balancing
- Add fruit/crop registration after FS25 map file references are verified

## Development Rule

Do not upload GIANTS base-game files or extracted game assets to this repository. Use them locally as references only.
