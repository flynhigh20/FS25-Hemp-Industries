#!/usr/bin/env python3
"""Create the standalone Green Horizon test-map ZIP."""

from __future__ import annotations

import sys
import zipfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
MAP_ROOT = REPO_ROOT / "FS25_GreenHorizonTestMap"
OUTPUT = REPO_ROOT / "dist" / "FS25_GreenHorizonTestMap.zip"


def main() -> int:
    if not (MAP_ROOT / "modDesc.xml").is_file():
        raise FileNotFoundError(f"Missing map mod source: {MAP_ROOT}")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(OUTPUT, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(MAP_ROOT.rglob("*")):
            if path.is_file():
                archive.write(path, path.relative_to(MAP_ROOT).as_posix())

    with zipfile.ZipFile(OUTPUT) as archive:
        names = set(archive.namelist())
        required = {
            "modDesc.xml",
            "maps/greenHorizonTestMap/greenHorizonTestMap.xml",
            "maps/greenHorizonTestMap/foliage/hemp/hemp.xml",
            "maps/greenHorizonTestMap/foliage/hemp/hemp.i3d",
            "maps/greenHorizonTestMap/foliage/hemp/hemp.i3d.shapes",
        }
        missing = sorted(required - names)
        if missing:
            raise RuntimeError(f"Test-map ZIP is missing: {', '.join(missing)}")

    print(f"Created {OUTPUT}")
    print("ZIP root check: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
