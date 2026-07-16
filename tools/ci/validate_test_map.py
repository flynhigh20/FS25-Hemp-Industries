#!/usr/bin/env python3
"""Validate the standalone Green Horizon crop test-map package source."""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MAP_ROOT = REPO_ROOT / "FS25_GreenHorizonTestMap"
FAILURES: list[str] = []


def passed(message: str) -> None:
    print(f"PASS: {message}")


def fail(message: str) -> None:
    FAILURES.append(message)
    print(f"FAIL: {message}")


def require(relative: str) -> Path:
    path = MAP_ROOT / relative
    if path.is_file() and path.stat().st_size > 0:
        passed(f"Found {relative}")
    else:
        fail(f"Missing or empty {relative}")
    return path


def parse(path: Path) -> ET.ElementTree | None:
    try:
        tree = ET.parse(path)
    except (OSError, ET.ParseError) as exc:
        fail(f"XML parse failed for {path.name}: {exc}")
        return None
    passed(f"XML parses: {path.relative_to(MAP_ROOT)}")
    return tree


def main() -> int:
    print("Green Horizon Test Map - Static Validation")

    mod_desc = require("modDesc.xml")
    map_xml = require("maps/greenHorizonTestMap/greenHorizonTestMap.xml")
    map_fill_types = require("maps/greenHorizonTestMap/fillTypes.xml")
    hemp_xml = require("maps/greenHorizonTestMap/foliage/hemp/hemp.xml")
    require("maps/greenHorizonTestMap/foliage/hemp/hemp.i3d")
    require("maps/greenHorizonTestMap/foliage/hemp/hemp.i3d.shapes")
    require("maps/greenHorizonTestMap/foliage/hemp/textures/hempFoliage_diffuse.png")
    require("maps/greenHorizonTestMap/foliage/hemp/textures/hempFoliage_normal.png")
    require("icon.dds")
    require("preview.dds")

    mod_tree = parse(mod_desc)
    map_tree = parse(map_xml)
    map_fill_types_tree = parse(map_fill_types)
    hemp_tree = parse(hemp_xml)

    if mod_tree is not None:
        root = mod_tree.getroot()
        dependency = root.findtext("./dependencies/dependency")
        if dependency == "FS25_GreenHorizonIndustries":
            passed("Map depends on FS25_GreenHorizonIndustries")
        else:
            fail("Map dependency must be FS25_GreenHorizonIndustries")
        map_node = root.find("./maps/map")
        if map_node is not None and map_node.get("id") == "GreenHorizonTestMap":
            passed("Unique test-map id is configured")
        else:
            fail("Expected map id GreenHorizonTestMap")
        if root.find("fillTypes") is None:
            passed("modDesc leaves canonical fill-type ownership with Industries")
        else:
            fail("Test-map modDesc must not register duplicate fill types")

    if map_tree is not None:
        root = map_tree.getroot()
        filename = root.findtext("filename")
        if filename == "$data/maps/mapUS/mapUS.i3d":
            passed("Map reuses the official Riverbend Springs terrain")
        else:
            fail("Test map must reference the official mapUS terrain")
        fruits = [node.get("filename") for node in root.findall("./fruitTypes/fruitType")]
        expected = "maps/greenHorizonTestMap/foliage/hemp/hemp.xml"
        if expected in fruits:
            passed("Map loads its local HEMP foliage type")
        else:
            fail("Map does not load its local HEMP foliage type")
        fill_types_node = root.find("fillTypes")
        if (
            fill_types_node is not None
            and fill_types_node.get("filename")
            == "maps/greenHorizonTestMap/fillTypes.xml"
        ):
            passed("Map pre-registers HEMP during map loading")
        else:
            fail("Map must load its compatibility fillTypes.xml")
        children = list(root)
        fruit_types_node = root.find("fruitTypes")
        fill_pos = children.index(fill_types_node) if fill_types_node in children else -1
        fruit_pos = children.index(fruit_types_node) if fruit_types_node in children else -1
        if 0 <= fill_pos < fruit_pos:
            passed("HEMP fill-type registration precedes fruit-type loading")
        else:
            fail("Map fillTypes must appear before fruitTypes")
        categories = {
            node.get("name"): (node.text or "").strip()
            for node in root.findall("./fruitTypeCategories/fruitTypeCategory")
        }
        for category in ("SOWINGMACHINE", "GRAINHEADER"):
            if categories.get(category) == "HEMP":
                passed(f"Map registers HEMP for {category}")
            else:
                fail(f"Map must register HEMP for {category}")

    if map_fill_types_tree is not None:
        root = map_fill_types_tree.getroot()
        names = {
            (node.get("name") or "").upper()
            for node in root.findall("./fillTypes/fillType")
        }
        if names == {"HEMP"}:
            passed("Map compatibility file pre-registers only HEMP")
        else:
            fail(
                "Map compatibility fill types must be exactly HEMP, "
                f"found {sorted(names)}"
            )

    if hemp_tree is not None:
        root = hemp_tree.getroot()
        fruit = root.find("fruitType")
        layer = root.find("foliageLayer")
        if fruit is not None and fruit.get("name") == "HEMP":
            passed("Outdoor crop name is HEMP")
        else:
            fail("Foliage definition must register HEMP")
        if layer is not None and layer.get("numDensityMapChannels") == "4":
            passed("HEMP reserves four density-map state channels")
        else:
            fail("HEMP must reserve four density-map state channels")
        states = root.findall("./foliageLayer/foliageState")
        if len(states) == 10:
            passed("HEMP defines invisible plus nine visible/cut states")
        else:
            fail(f"Expected 10 total HEMP states, found {len(states)}")
        destructed_states = [
            state
            for state in states
            if state.get("isDestructedByWheel") == "true"
        ]
        if len(destructed_states) == 1 and destructed_states[0].get("name") == "harvested":
            passed("Harvested HEMP is the wheel-destruction target")
        else:
            fail("Exactly the harvested state must be isDestructedByWheel")
        periods = root.findall("./growth/seasonal/period")
        if len(periods) == 12:
            passed("HEMP growth calendar defines all 12 periods")
        else:
            fail(f"Expected 12 growth periods, found {len(periods)}")

    print()
    print(f"Failures: {len(FAILURES)}")
    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
