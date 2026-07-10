# Green Horizon Industries - Patch exported greenhouse i3d helper nodes for FS25
#
# Use after saving/exporting the greenhouse from GIANTS Editor as:
#   FS25_GreenHorizonIndustries/placeables/greenhouses/i3d/greenHorizonHempGreenhouse.i3d
#
# What it does:
# - renames our GHI_* helper placeholders to FS-style helper names
# - hides/non-renders helper boxes so they do not show as orange clunker blocks
# - applies base-game-style trigger/collision attributes
# - adds missing placement/area helper transform nodes when needed
# - rewrites hempGreenhouse.xml i3dMappings to point at the actual node paths

from __future__ import annotations

from pathlib import Path
import shutil
import xml.etree.ElementTree as ET


REQUIRED_MAPPING_IDS = [
    "clearAreaStart01",
    "clearAreaHeight01",
    "clearAreaWidth01",
    "levelAreaStart01",
    "levelAreaWidth01",
    "levelAreaHeight01",
    "indoorArea01Start",
    "indoorAreaWidth01",
    "indoorArea1Height",
    "testAreaStart01",
    "testAreaEnd01",
    "tipOcclusionUpdateAreaStart01",
    "tipOcclusionUpdateAreaEnd01",
    "plantNodes",
    "palletSpawner",
    "spawnPlaceStart01",
    "spawnPlaceEnd01",
    "sellingStation",
    "exactFillRootNode",
    "unloadTriggerMarker",
    "unloadTriggerAINode",
    "storage",
    "playerTrigger",
    "playerTriggerMarker",
    "teleportNode",
    "infoTrigger",
    "warningStripes",
]

RENAME_HELPERS = {
    "GHI_pallet_spawn_area_placeholder": "palletSpawner",
    "GHI_placeable_collision_placeholder": "placeableCollision",
    "GHI_player_interaction_trigger_placeholder": "playerTrigger",
    "GHI_unload_water_trigger_placeholder": "unloadTriggerMarker",
    "GHI_unload_seed_trigger_placeholder": "seedUnloadTrigger",
    "GHI_buy_marker": "warningStripes",
    "GHI_label_pallet_spawn": "label_pallet_spawn",
    "GHI_label_player_trigger": "label_player_trigger",
    "GHI_label_seed": "label_seed",
    "GHI_label_water": "label_water",
}

# Simple dimensions based on our current greenhouse footprint.
AREA_NODES = {
    "testAreaStart01": (-4.7, -3.1, 0.0),
    "testAreaEnd01": (4.7, 3.1, 4.2),
    "clearAreaStart01": (-4.7, -3.1, 0.0),
    "clearAreaWidth01": (4.7, -3.1, 0.0),
    "clearAreaHeight01": (-4.7, 3.1, 0.0),
    "levelAreaStart01": (-4.7, -3.1, 0.0),
    "levelAreaWidth01": (4.7, -3.1, 0.0),
    "levelAreaHeight01": (-4.7, 3.1, 0.0),
    "indoorArea01Start": (-4.1, -2.4, 0.0),
    "indoorAreaWidth01": (4.1, -2.4, 0.0),
    "indoorArea1Height": (-4.1, 2.4, 0.0),
    "tipOcclusionUpdateAreaStart01": (-4.7, -3.1, 0.0),
    "tipOcclusionUpdateAreaEnd01": (4.7, 3.1, 0.0),
    "plantNodes": (0.0, 0.0, 0.75),
    "sellingStation": (-3.9, 2.65, 0.8),
    "unloadTriggerAINode": (-3.9, 2.65, 0.8),
    "storage": (0.0, 0.0, 0.0),
    "teleportNode": (4.9, 0.0, 0.0),
    "spawnPlaceStart01": (2.05, 1.65, 0.05),
    "spawnPlaceEnd01": (3.05, 2.65, 0.05),
}


def find_repo_root() -> Path:
    script = Path(__file__).resolve()
    for candidate in [script.parent, *script.parents]:
        if (candidate / "FS25_GreenHorizonIndustries" / "modDesc.xml").exists():
            return candidate
    return Path.home() / "Documents" / "GreenHorizonIndustries"


def fmt_vec(values) -> str:
    return " ".join(f"{v:g}" for v in values)


def all_scene_nodes(scene):
    for elem in scene.iter():
        if elem.tag in {"TransformGroup", "Shape"}:
            yield elem


def get_name_map(scene):
    return {elem.attrib.get("name"): elem for elem in all_scene_nodes(scene) if elem.attrib.get("name")}


def next_node_id(root) -> int:
    max_id = 0
    for elem in root.iter():
        raw = elem.attrib.get("nodeId")
        if raw and raw.isdigit():
            max_id = max(max_id, int(raw))
    return max_id + 1


def add_transform(scene, root, name: str, translation=(0.0, 0.0, 0.0)):
    elem = ET.Element("TransformGroup", {
        "name": name,
        "translation": fmt_vec(translation),
        "visibility": "false",
        "nodeId": str(next_node_id(root)),
    })
    scene.append(elem)
    return elem


def apply_helper_settings(scene):
    name_map = get_name_map(scene)

    for old, new in RENAME_HELPERS.items():
        elem = name_map.get(old)
        if elem is not None:
            elem.set("name", new)

    name_map = get_name_map(scene)

    # Visual/helper boxes should not render in-game.
    for name in [
        "palletSpawner",
        "placeableCollision",
        "warningStripes",
        "label_pallet_spawn",
        "label_player_trigger",
        "label_seed",
        "label_water",
    ]:
        elem = name_map.get(name)
        if elem is not None:
            elem.set("visibility", "false")
            elem.set("nonRenderable", "true")
            elem.set("castsShadows", "false")
            elem.set("receiveShadows", "false")

    # Main physical collision: non-rendered but solid/static.
    col = name_map.get("placeableCollision")
    if col is not None:
        col.set("visibility", "false")
        col.set("nonRenderable", "true")
        col.set("static", "true")
        col.set("collisionFilterGroup", "0x1034")
        col.set("collisionFilterMask", "0xfffffbff")
        col.set("castsShadows", "false")
        col.set("receiveShadows", "false")

    # Player/water/seed trigger boxes: hidden trigger shapes.
    for name in ["playerTrigger", "unloadTriggerMarker", "seedUnloadTrigger"]:
        elem = name_map.get(name)
        if elem is not None:
            elem.set("visibility", "false")
            elem.set("nonRenderable", "true")
            elem.set("static", "true")
            elem.set("trigger", "true")
            elem.set("collisionFilterGroup", "0x20000000")
            elem.set("collisionFilterMask", "0x100000")
            elem.set("castsShadows", "false")
            elem.set("receiveShadows", "false")


def ensure_required_nodes(scene, root):
    name_map = get_name_map(scene)

    for name, translation in AREA_NODES.items():
        if name not in name_map:
            add_transform(scene, root, name, translation)

    name_map = get_name_map(scene)

    # Reuse good trigger/location nodes for IDs that can safely point at existing objects.
    aliases = {
        "exactFillRootNode": "unloadTriggerMarker",
        "playerTriggerMarker": "playerTrigger",
        "infoTrigger": "playerTrigger",
    }
    for alias, target in aliases.items():
        if alias not in name_map and target in name_map:
            # Do not duplicate shape geometry; i3dMappings can point this ID at the target path.
            continue
        if alias not in name_map:
            add_transform(scene, root, alias, (0.0, 0.0, 0.0))

    # Add some child plant spots so the greenhouse plantSpaces parent is not empty.
    name_map = get_name_map(scene)
    plant_parent = name_map.get("plantNodes")
    if plant_parent is not None:
        existing_children = [child for child in plant_parent if child.attrib.get("name", "").startswith("plantNode")]
        if not existing_children:
            x_values = [-2.8, -1.4, 0.0, 1.4, 2.8]
            y_values = [-1.45, 0.0, 1.45]
            idx = 1
            for y in y_values:
                for x in x_values:
                    child = ET.Element("TransformGroup", {
                        "name": f"plantNode{idx}",
                        "translation": fmt_vec((x, y, 0.0)),
                        "visibility": "false",
                        "nodeId": str(next_node_id(root)),
                    })
                    plant_parent.append(child)
                    idx += 1


def compute_node_paths(scene):
    paths = {}

    def walk(elem, path):
        name = elem.attrib.get("name")
        if name:
            paths[name] = path
        children = [child for child in list(elem) if child.tag in {"TransformGroup", "Shape"}]
        for idx, child in enumerate(children):
            walk(child, f"{path}|{idx}")

    children = [child for child in list(scene) if child.tag in {"TransformGroup", "Shape"}]
    for idx, child in enumerate(children):
        walk(child, f"0>{idx}")
    return paths


def mapping_target(mapping_id: str, paths: dict[str, str]) -> str | None:
    aliases = {
        "exactFillRootNode": "unloadTriggerMarker",
        "playerTriggerMarker": "playerTrigger",
        "infoTrigger": "playerTrigger",
    }
    name = aliases.get(mapping_id, mapping_id)
    return paths.get(name)


def patch_placeable_xml(xml_path: Path, i3d_paths: dict[str, str]) -> None:
    tree = ET.parse(xml_path)
    root = tree.getroot()

    existing = root.find("i3dMappings")
    if existing is not None:
        root.remove(existing)

    mappings = ET.Element("i3dMappings")
    for mapping_id in REQUIRED_MAPPING_IDS:
        node_path = mapping_target(mapping_id, i3d_paths)
        if node_path is None:
            print(f"WARN: no node path found for mapping id {mapping_id}")
            continue
        mappings.append(ET.Element("i3dMapping", {"id": mapping_id, "node": node_path}))

    root.append(mappings)
    tree.write(xml_path, encoding="utf-8", xml_declaration=True)


def main() -> None:
    repo_root = find_repo_root()
    i3d_path = repo_root / "FS25_GreenHorizonIndustries" / "placeables" / "greenhouses" / "i3d" / "greenHorizonHempGreenhouse.i3d"
    xml_path = repo_root / "FS25_GreenHorizonIndustries" / "placeables" / "greenhouses" / "hempGreenhouse.xml"

    if not i3d_path.exists():
        raise FileNotFoundError(f"Missing exported i3d: {i3d_path}")
    if not xml_path.exists():
        raise FileNotFoundError(f"Missing placeable XML: {xml_path}")

    backup = i3d_path.with_suffix(i3d_path.suffix + ".bak")
    shutil.copy2(i3d_path, backup)

    tree = ET.parse(i3d_path)
    root = tree.getroot()
    scene = root.find("Scene")
    if scene is None:
        raise RuntimeError("i3d has no <Scene> section")

    apply_helper_settings(scene)
    ensure_required_nodes(scene, root)
    tree.write(i3d_path, encoding="utf-8", xml_declaration=True)

    # Re-parse after writing so paths match final file.
    final_tree = ET.parse(i3d_path)
    final_scene = final_tree.getroot().find("Scene")
    paths = compute_node_paths(final_scene)
    patch_placeable_xml(xml_path, paths)

    print(f"Patched helper nodes: {i3d_path}")
    print(f"Backup saved: {backup}")
    print(f"Updated i3dMappings in: {xml_path}")


if __name__ == "__main__":
    main()
