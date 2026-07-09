# FS25 Hemp Industries

🚧 Alpha Development  
🖥️ PC Compatible  
🎮 Console Goal  
🌱 Industrial Hemp Expansion  
🚜 Green Horizon Industries

## Current Build

**Phase 2.6 / Alpha 0.2 safe Blender greenhouse rebuild and store visibility retest is active.**

The active mod folder is:

```text
FS25_GreenHorizonIndustries/
```

This folder is intended to become the final FS25 mod folder/zip root for in-game testing.

## Quick Windows Testing

Start with the helper menu:

```text
tools/windows/green_horizon_test_menu.bat
```

Recommended order:

```text
1. Preflight check repo files
3. Package and install to FS25 mods folder
4. Check FS25 log after running game
```

You can also package/install directly with:

```text
tools/windows/package_and_install_mod.bat
```

After running FS25 once, check the filtered log report with:

```text
tools/windows/check_fs25_log.bat
```

Helpful docs:

```text
docs/Next-Test-Plan.md
docs/Windows-Packaging.md
docs/Test-Checklist.md
docs/GIANTS-Editor-Prep.md
docs/Phase-3-Upgradeable-Greenhouse.md
docs/Phase-3-Upgradeable-CBD-Plant.md
docs/Console-Optimization.md
tools/blender/README.md
```

## Phase 1 Result

Phase 1 fill type loading has been confirmed by FS25 log output:

```text
Info: Loaded 3 fill types from mod
```

## Phase 2.6 Scope

Phase 2.6 starts the Blender greenhouse model over with a safe rebuild while keeping the current FS25 store visibility retest path.

Included now:

- `modDesc.xml` remains mod version `0.2.5.0` for the current FS25 package retest
- `modDesc.xml` descriptor version remains `91` for the current local FS25 test setup
- Windows package/install helper removes old loose mod folders as well as old zips
- Store item wiring for a Hemp Greenhouse
- Hemp Greenhouse category kept as `productionPoints` for the production-point shell
- Production brush metadata added: `production` / `factories`
- Greenhouse production placeable XML
- Recipe balance notes XML
- Blender greenhouse generator output-path fix
- Blender pallet generator output-path fix
- Greenhouse Blender script marked for Blender 4.2 LTS workflow
- Greenhouse Blender script rebuilt from scratch with segmented roof panels
- Single curved roof mesh and solidify/thickness modifier removed
- Adjustable arched ribs retained
- Early top/front greenhouse signs removed from the Blender model
- Top pallet signs removed; pallets keep front labels only
- Windows test menu added
- Windows preflight checker added
- Windows FS25 log checker added
- Optional Blender GIANTS Editor helper markers added
- Console optimization planning added
- Upgradeable-style greenhouse progression plan added
- Upgradeable-style CBD plant / selling point progression plan added
- Production input/output loop:
  - Inputs: `WATER`, `GHI_HEMP_SEED`
  - Outputs: `HEMP`, `GHI_HEMP_BIOMASS`

## Where To Look In Game

First confirm FS25 shows the mod version as:

```text
0.2.5.0
```

If FS25 still shows the mod as version `0.2.2.0`, `0.2.3.0`, or `0.2.4.0`, the old zip or loose folder is still installed.

Then check the construction menu:

```text
Construction > Production > Factories / Production Points
```

Still pending:

- Verify FS25 loads version `0.2.5.0`
- Verify the greenhouse appears in the FS25 construction menu under Production/Factories
- Decide whether the later true greenhouse system should use `PlaceableGreenhouse` / greenhouse plant schema instead of the current productionPoint shell
- Confirm the temporary base-game greenhouse visual path loads
- Approve the safe rebuilt Blender greenhouse shape
- Add original Green Horizon greenhouse model/assets to the placeable XML after i3d export
- Add real DDS store image and icon files
- Add pallets/storage triggers after first placeable test
- Add sell points and economy balancing
- Add upgradeable-style greenhouse modules after greenhouse test passes
- Add upgradeable-style CBD plant progression after greenhouse test passes
- Add fruit/crop registration after FS25 map file references are verified

## Development Rule

Do not upload GIANTS base-game files or extracted game assets to this repository. Use them locally as references only.
