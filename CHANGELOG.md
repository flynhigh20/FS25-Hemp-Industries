# FS25 Hemp Industries

All notable changes to this project will be documented here.

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
