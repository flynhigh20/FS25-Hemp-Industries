#!/usr/bin/env python3
"""Static repository checks that do not require Blender, GIANTS Editor, or FS25."""

from __future__ import annotations

import ast
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MOD_ROOT = REPO_ROOT / "FS25_GreenHorizonIndustries"

FAILURES: list[str] = []
WARNINGS: list[str] = []


def passed(message: str) -> None:
    print(f"PASS: {message}")


def fail(message: str) -> None:
    FAILURES.append(message)
    print(f"FAIL: {message}")


def warn(message: str) -> None:
    WARNINGS.append(message)
    print(f"WARN: {message}")


def parse_xml(path: Path) -> ET.ElementTree | None:
    try:
        tree = ET.parse(path)
    except (ET.ParseError, OSError) as exc:
        fail(f"XML parse failed: {path.relative_to(REPO_ROOT)} -- {exc}")
        return None
    passed(f"XML parses: {path.relative_to(REPO_ROOT)}")
    return tree


def check_python_sources() -> None:
    candidates = sorted((REPO_ROOT / "tools").rglob("*.py"))
    if not candidates:
        fail("No Python source files were found under tools/")
        return

    for path in candidates:
        try:
            ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        except (SyntaxError, UnicodeError, OSError) as exc:
            fail(f"Python syntax failed: {path.relative_to(REPO_ROOT)} -- {exc}")
        else:
            passed(f"Python syntax: {path.relative_to(REPO_ROOT)}")


def check_xml_sources() -> dict[Path, ET.ElementTree]:
    parsed: dict[Path, ET.ElementTree] = {}
    for path in sorted(MOD_ROOT.rglob("*.xml")):
        tree = parse_xml(path)
        if tree is not None:
            parsed[path] = tree
    return parsed


def check_powershell_obvious_errors() -> None:
    for path in sorted((REPO_ROOT / "tools" / "windows").glob("*.ps1")):
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as exc:
            fail(f"Could not read PowerShell source: {path.relative_to(REPO_ROOT)} -- {exc}")
            continue

        relative = path.relative_to(REPO_ROOT)
        if re.search(r"(?m)^\s*elif\s*\(", text):
            fail(f"PowerShell uses 'elseif', not 'elif': {relative}")
        if re.search(r"(?m)^\s*Invoke-[A-Za-z0-9_-]+\s*\\\s*$", text):
            fail(f"Possible Unix-style line continuation in PowerShell: {relative}")
        if "param(" not in text:
            warn(f"PowerShell script has no parameter block: {relative}")
        else:
            passed(f"PowerShell basic scan: {relative}")


def require_file(relative_path: str) -> Path:
    path = REPO_ROOT / relative_path
    if path.exists():
        passed(f"Required file exists: {relative_path}")
    else:
        fail(f"Missing required file: {relative_path}")
    return path


def check_mod_descriptor(parsed: dict[Path, ET.ElementTree]) -> str:
    path = MOD_ROOT / "modDesc.xml"
    tree = parsed.get(path)
    if tree is None:
        return ""

    root = tree.getroot()
    version = (root.findtext("version") or "").strip()
    if version:
        passed(f"modDesc version: {version}")
    else:
        fail("modDesc has no version")

    if root.find("fruitTypes") is None:
        passed("Field fruit registration remains inactive")
    else:
        fail("fruitTypes is active in modDesc before map integration is ready")

    fill_types = root.find("fillTypes")
    if fill_types is None or fill_types.get("filename") != "xml/fillTypes.xml":
        fail("modDesc fillTypes path is incorrect")
    else:
        passed("modDesc fillTypes path is correct")

    store_items = root.find("storeItems")
    active_items = [] if store_items is None else list(store_items.findall("storeItem"))
    if len(active_items) != 1:
        fail(f"Expected one active store item, found {len(active_items)}")
    elif active_items[0].get("xmlFilename") != "placeables/greenhouses/hempGreenhouse.xml":
        fail("Active store item is not the Hemp Greenhouse")
    else:
        passed("Hemp Greenhouse is the sole active store item")

    return version


def check_fill_types(parsed: dict[Path, ET.ElementTree]) -> None:
    path = MOD_ROOT / "xml" / "fillTypes.xml"
    tree = parsed.get(path)
    if tree is None:
        return

    names = {
        node.get("name")
        for node in tree.getroot().findall("./fillTypes/fillType")
        if node.get("name")
    }
    required = {
        "HEMP",
        "GHI_HEMP_SEED",
        "GHI_HEMP_BIOMASS",
        "GHI_HEMP_FIBER",
        "HEMP_FLOWER",
        "GHI_HEMP_OIL",
    }
    missing = sorted(required - names)
    if missing:
        fail(f"Missing fill types: {', '.join(missing)}")
    else:
        passed("All six Green Horizon fill types are present")


def int_attr(node: ET.Element | None, attribute: str, source: str) -> int | None:
    if node is None:
        fail(f"Missing node while reading {source}.{attribute}")
        return None
    try:
        return int(node.get(attribute, ""))
    except ValueError:
        fail(f"Invalid integer for {source}.{attribute}: {node.get(attribute)!r}")
        return None


def check_field_contract(parsed: dict[Path, ET.ElementTree]) -> None:
    fruit_tree = parsed.get(MOD_ROOT / "xml" / "fruitTypes.xml")
    foliage_tree = parsed.get(MOD_ROOT / "foliage" / "hemp" / "hempFoliagePlan.xml")
    map_tree = parsed.get(MOD_ROOT / "foliage" / "hemp" / "hempMapRegistrationDraft.xml")
    cutter_tree = parsed.get(MOD_ROOT / "foliage" / "hemp" / "hempCutterEffectsPlan.xml")

    contracts: dict[str, tuple[int | None, int | None, int | None, int | None, int | None]] = {}

    if fruit_tree is not None:
        fruit = fruit_tree.getroot().find("./fruitTypes/fruitType[@name='HEMP']")
        if fruit is None:
            fail("fruitTypes.xml has no HEMP fruitType")
        else:
            contracts["fruitTypes.xml"] = (
                int_attr(fruit.find("general"), "numStateChannels", "fruit.general"),
                int_attr(fruit.find("growth"), "numGrowthStates", "fruit.growth"),
                int_attr(fruit.find("harvest"), "minHarvestingGrowthState", "fruit.harvest"),
                int_attr(fruit.find("growth"), "witheredState", "fruit.growth"),
                int_attr(fruit.find("harvest"), "cutState", "fruit.harvest"),
            )

    if foliage_tree is not None:
        density = foliage_tree.getroot().find("densityMap")
        contracts["hempFoliagePlan.xml"] = (
            int_attr(density, "numStateChannels", "foliage.densityMap"),
            int_attr(density, "numGrowthStates", "foliage.densityMap"),
            int_attr(density, "harvestReadyState", "foliage.densityMap"),
            int_attr(density, "witheredState", "foliage.densityMap"),
            int_attr(density, "cutState", "foliage.densityMap"),
        )
        states = foliage_tree.getroot().findall("./growthStates/state")
        if len(states) == 9:
            passed("Foliage plan contains nine states")
        else:
            fail(f"Foliage plan contains {len(states)} states instead of nine")

    if map_tree is not None:
        contract = map_tree.getroot().find("stateContract")
        contracts["hempMapRegistrationDraft.xml"] = (
            int_attr(contract, "numStateChannels", "map.stateContract"),
            int_attr(contract, "numGrowthStates", "map.stateContract"),
            int_attr(contract, "harvestReadyState", "map.stateContract"),
            int_attr(contract, "witheredState", "map.stateContract"),
            int_attr(contract, "cutState", "map.stateContract"),
        )

    expected = (4, 7, 7, 8, 9)
    for source, contract in contracts.items():
        if contract == expected:
            passed(f"Field state contract matches 4/7/7/8/9: {source}")
        else:
            fail(f"Field state contract mismatch in {source}: {contract}")

    if cutter_tree is not None:
        route = cutter_tree.getroot().find("./cropStateRouting/route[@growthState='7']")
        if (
            route is not None
            and route.get("cutterAllowed") == "true"
            and route.get("outputFillType") == "HEMP"
            and route.get("resultingState") == "9"
        ):
            passed("Cutter route is mature HEMP -> state 9")
        else:
            fail("Cutter mature-state route is inconsistent")


def check_icon_manifest(parsed: dict[Path, ET.ElementTree]) -> None:
    path = MOD_ROOT / "ui" / "hempIconManifest.xml"
    tree = parsed.get(path)
    if tree is None:
        return

    icons = tree.getroot().findall("./icons/icon")
    ids = {icon.get("id") for icon in icons}
    required = {
        "HEMP",
        "GHI_HEMP_SEED",
        "GHI_HEMP_BIOMASS",
        "GHI_HEMP_FIBER",
        "HEMP_FLOWER",
        "GHI_HEMP_OIL",
        "HEMP_CROP",
        "HEMP_CALENDAR",
    }
    missing = sorted(required - ids)
    if missing:
        fail(f"Icon manifest is missing: {', '.join(missing)}")
    else:
        passed("Icon manifest contains all eight planned icons")

    linked = [icon.get("id") for icon in icons if icon.get("linked") == "true"]
    if linked:
        fail(f"Icons were linked before verification: {', '.join(linked)}")
    else:
        passed("All crop and product icons remain unlinked")


def check_version_docs(version: str) -> None:
    if not version:
        return
    readme = REPO_ROOT / "README.md"
    if readme.exists() and version in readme.read_text(encoding="utf-8"):
        passed("README contains the current mod version")
    else:
        fail("README does not contain the current mod version")


def check_export_state() -> None:
    i3d = MOD_ROOT / "placeables" / "greenhouses" / "i3d" / "greenHorizonHempGreenhouse.i3d"
    shapes = Path(f"{i3d}.shapes")

    if not i3d.exists():
        warn("Greenhouse i3d is absent; local manual export is still required")
        return

    text = i3d.read_text(encoding="utf-8", errors="replace")
    if "placeholder" in text:
        warn("Repository still contains the Phase 2.6 placeholder i3d")
    else:
        passed("Repository i3d is not marked as the placeholder")

    if shapes.exists():
        passed("Greenhouse shapes file exists in the repository")
    else:
        warn("Greenhouse shapes file is absent; local manual export is still required")


def main() -> int:
    print("Green Horizon Industries - Static Repository Validation")
    print(f"Repository: {REPO_ROOT}")
    print()

    for relative in (
        "FS25_GreenHorizonIndustries/modDesc.xml",
        "FS25_GreenHorizonIndustries/xml/fillTypes.xml",
        "FS25_GreenHorizonIndustries/xml/fruitTypes.xml",
        "FS25_GreenHorizonIndustries/xml/growth/hempGrowth.xml",
        "FS25_GreenHorizonIndustries/foliage/hemp/hempFoliagePlan.xml",
        "FS25_GreenHorizonIndustries/foliage/hemp/hempMapRegistrationDraft.xml",
        "FS25_GreenHorizonIndustries/foliage/hemp/hempCutterEffectsPlan.xml",
        "FS25_GreenHorizonIndustries/ui/hempIconManifest.xml",
        "tools/blender/create_green_horizon_greenhouse.py",
        "tools/blender/create_hemp_foliage.py",
        "tools/blender/create_hemp_crop_icons.py",
        "tools/blender/create_hemp_cutter_effects.py",
        "tools/windows/generate_project_assets.ps1",
        "tools/windows/validate_greenhouse_export.ps1",
    ):
        require_file(relative)

    check_python_sources()
    check_powershell_obvious_errors()
    parsed = check_xml_sources()
    version = check_mod_descriptor(parsed)
    check_fill_types(parsed)
    check_field_contract(parsed)
    check_icon_manifest(parsed)
    check_version_docs(version)
    check_export_state()

    print()
    print("Validation summary")
    print(f"Failures: {len(FAILURES)}")
    print(f"Warnings: {len(WARNINGS)}")

    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
