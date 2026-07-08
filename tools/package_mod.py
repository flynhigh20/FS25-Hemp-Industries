#!/usr/bin/env python3
"""Package the active FS25 mod folder into a drop-in zip.

This creates a zip where modDesc.xml is at the root of the archive, which is
what Farming Simulator expects. Do not use GitHub's full repository download zip
as the game mod zip because GitHub wraps the repo in an extra folder.
"""

from __future__ import annotations

import argparse
import sys
import zipfile
from pathlib import Path

DEFAULT_MOD_FOLDER = "FS25_GreenHorizonIndustries"
DEFAULT_OUTPUT = "dist/FS25_Hemp_Industries.zip"


def should_include(path: Path) -> bool:
    """Return True for files that should be packaged into the FS25 zip."""
    ignored_suffixes = {".blend", ".blend1", ".psd", ".kra"}
    ignored_parts = {"__pycache__", ".git", ".github", "tools", "docs", "research", "dist"}

    if any(part in ignored_parts for part in path.parts):
        return False
    if path.suffix.lower() in ignored_suffixes:
        return False
    return path.is_file()


def package_mod(mod_folder: Path, output_zip: Path) -> None:
    if not mod_folder.exists():
        raise FileNotFoundError(f"Mod folder not found: {mod_folder}")

    mod_desc = mod_folder / "modDesc.xml"
    if not mod_desc.exists():
        raise FileNotFoundError(f"modDesc.xml must be inside: {mod_folder}")

    output_zip.parent.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(output_zip, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for file_path in sorted(mod_folder.rglob("*")):
            if not should_include(file_path):
                continue
            archive.write(file_path, file_path.relative_to(mod_folder).as_posix())

    with zipfile.ZipFile(output_zip, "r") as archive:
        names = set(archive.namelist())
        if "modDesc.xml" not in names:
            raise RuntimeError("Packaged zip is invalid: modDesc.xml is not at the zip root")

    print(f"Packaged {output_zip}")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Package Green Horizon Industries for FS25.")
    parser.add_argument("--mod-folder", default=DEFAULT_MOD_FOLDER, help="Active mod folder to package")
    parser.add_argument("--output", default=DEFAULT_OUTPUT, help="Output zip path")
    args = parser.parse_args(argv)

    package_mod(Path(args.mod_folder), Path(args.output))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
