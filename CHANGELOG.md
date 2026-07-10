# FS25 Hemp Industries

All notable changes to this project will be documented here.

---

## Version 0.2.16 - Hemp Foliage Source Generator

### Added
- Blender source generator for the inactive Industrial Hemp field crop.
- Procedural diffuse-alpha and normal foliage atlases.
- Near and distance card meshes for states 1 through 9.
- Field integration plan covering map layers, vehicle categories, cutter effects, and first-release outputs.

### Changed
- Updated mod version to `0.2.16.0`.
- Linked the foliage plan to the new generator and atlas tiles.
- Updated preflight checks to validate the generator and integration plan while warning, rather than failing, before the foliage textures are generated.
- Corrected Blender documentation to describe the new peaked glass greenhouse roof.

### Safety
- Field hemp remains inactive.
- Running the foliage generator creates source assets only; it does not edit `modDesc.xml` or register a map foliage layer.

---

## Version 0.2.15 - Field Hemp Crop Foundation

### Added
- Expanded inactive Industrial Hemp fruit type with cultivation, harvest, growth, crop-care, destruction, and map-color targets.
- Added a 12-period seasonal hemp growth calendar draft.
- Added a nine-state foliage asset plan covering emerged through cut states.
- Added field-crop activation documentation and safety gates.

### Changed
- Updated mod version to `0.2.15.0`.
- Updated preflight checks to validate the fruit type, growth calendar, and foliage-state plan.
- Updated packaging checks so the crop draft files are included in every test zip.

### Safety
- Field hemp remains inactive in `modDesc.xml` until foliage textures, map density channels, cutter effects, destruction masks, and vehicle categories are ready.
- The greenhouse remains the active test feature.

---

## Version 0.2.4 - Phase 2 Blender Roof / Local Descriptor Test

### Changed
- Updated mod version to `0.2.4.0`.
- Returned `modDesc.xml` descriptor version to `91` for the current local FS25 test setup.
- Kept Hemp Greenhouse store category as valid `productionPoints`.
- Updated Blender greenhouse generator for Blender 4.2 LTS workflow.
- Removed the floating flat roof panel from the greenhouse concept.
- Added a real curved polycarbonate roof mesh.
- Moved roof ribs up so they sit on the wall tops instead of reading as flipped into the body.
- Kept early top/front greenhouse signs removed.

### Test Focus
- Delete the old zip/folder before testing.
- Confirm the mod list shows version `0.2.4.0`.
- Check Construction > Production > Factories / Production Points.
- Run the greenhouse generator in Blender 4.2 LTS.
- Confirm the generated roof is curved and seated on the wall tops.

---

## Version 0.2.3 - Phase 2 Category Rejection Fix

### Changed
- Updated mod version to `0.2.3.0`.
- Kept `modDesc.xml` descriptor version at `109` for FS25 1.19.
- Changed Hemp Greenhouse store category from rejected `greenhouses` back to valid `productionPoints`.
- Updated Blender greenhouse generator to save relative to the repository instead of Blender's launch folder.
- Updated Blender pallet generator to save relative to the repository instead of Blender's launch folder.
- Removed the early top/front greenhouse signs from the Blender greenhouse concept.
- Removed top signs from the pallet concept models while keeping front labels.

### Test Focus
- Delete the old zip/folder before testing.
- Confirm the mod list shows version `0.2.3.0`.
- Check Construction > Production > Factories / Production Points.
- Confirm no `Invalid category 'greenhouses'` warning appears.
- Confirm Blender scripts save into `assets/blender/` without the Windows `PermissionError`.

---

## Version 0.2.2 - Phase 2 Store Visibility Test

### Changed
- Updated `modDesc.xml` descriptor version from `91` to `109` for FS25 1.19.
- Updated mod version to `0.2.2.0`.
- Changed Hemp Greenhouse store category from `productionPoints` to `greenhouses` for the next construction-menu test.

### Test Result
- FS25 rejected `greenhouses` as an invalid store category and fell back to `misc`.

### Test Focus
- Delete the old zip before testing.
- Confirm the mod list shows version `0.2.2.0`.
- Check Construction > Production > Greenhouses.
- If not visible, also check Construction > Production > Factories / Production Points.
- Search the log for `Unknown category`, `Invalid store item`, or `hempGreenhouse.xml`.

---

## Version 0.2.1 - Phase 2 Icon Log Fix

### Changed
- Updated `modDesc.xml` version to `0.2.1.0`.
- Removed the `iconFilename` reference until `icon_mod.dds` is actually packaged.

### Test Focus
- Confirm the missing `icon_mod.dds` error is gone.
- Confirm the mod still loads the 3 fill types.
- Check whether the Hemp Greenhouse appears in the FS25 construction/store menu.
- If it does not appear, search the log for `hempGreenhouse.xml`, `storeItem_ghi_hempGreenhouse`, or `production_ghi_hempGreenhouseBasic`.

---

## Version 0.2.0 - Phase 2 Greenhouse Test Build

### Added
- Hemp Greenhouse production placeable XML.
- Store item wiring in `modDesc.xml`.
- Localized text entries for the greenhouse store item, function text, and production name.
- Greenhouse recipe balance notes XML.

### Changed
- Updated `modDesc.xml` version to `0.2.0.0`.
- README now tracks the successful Phase 1 fill type load and Phase 2 greenhouse test scope.
- Roadmap now marks the first successful fill type load.

### Test Focus
- Confirm the Hemp Greenhouse appears in the FS25 construction/store menu.
- Watch the FS25 log for errors around `placeables/greenhouses/hempGreenhouse.xml`.
- Confirm whether the temporary base-game greenhouse visual path resolves.

---

## Version 0.1.0 - Phase 1 Foundation

### Added
- Phase 1 foundation status.
- Active FS25 mod folder: `FS25_GreenHorizonIndustries/`.
- Updated `modDesc.xml` version to `0.1.0.0`.
- Initial fill type registration for Industrial Hemp, Hemp Seed, and Hemp Biomass.
- Phase 1 documentation.

### Changed
- Renamed the working mod folder from `mod/` to `FS25_GreenHorizonIndustries/`.
- Updated README and roadmap to match the new folder structure.

### Pending Verification
- Confirm `modDesc.xml` loads in FS25.
- Confirm `descVersion` against the installed FS25 build.
- Add `icon_mod.dds` before final packaging.

---

## Version 0.0.1 - Project Initialization

### Added
- GitHub repository created.
- Initial folder structure.
- Development roadmap established.
- Green Horizon Industries branding selected.
- Project architecture planned.
- Initial modDesc.xml created.

### Planned
- Verify modDesc.xml against current FS25 format.
- Add fillTypes.xml.
- Add fruitTypes.xml.
- Register Industrial Hemp crop.
- Implement greenhouse support.
