# Windows Packaging Guide

This project has two packaging options:

- Easy Windows launchers in `tools/windows/`
- Optional Python script in `tools/package_mod.py`

Use the Windows launchers if you are just testing the mod locally.

## Easiest Option: Package and Install

Double-click:

```text
tools/windows/package_and_install_mod.bat
```

This does three things:

1. Builds `FS25_GreenHorizonIndustries.zip`
2. Removes old confusing test zips from your FS25 mods folder:
   - `FS25_GreenHorizonIndustries.zip`
   - `FS25_Hemp_Industries.zip`
3. Copies the new zip into:

```text
Documents/My Games/FarmingSimulator2025/mods
```

After that, start FS25 and confirm the mod list shows the current version from `modDesc.xml`.

## Safer Option: Package Only

Double-click:

```text
tools/windows/package_mod.bat
```

This only creates:

```text
dist/FS25_GreenHorizonIndustries.zip
```

Then you can manually copy that zip into your FS25 mods folder.

## Log Checker

After you run FS25 once, double-click:

```text
tools/windows/check_fs25_log.bat
```

This scans the normal FS25 log location:

```text
Documents/My Games/FarmingSimulator2025/log.txt
```

It filters for Green Horizon lines, warnings, and errors, then saves a smaller report in:

```text
Documents/My Games/FarmingSimulator2025/GreenHorizonReports/
```

Send that report text if the greenhouse does not show or if FS25 throws warnings.

## Why This Exists

The most common packaging mistake is zipping the parent folder so the zip looks like this:

```text
FS25_GreenHorizonIndustries.zip
└── FS25_GreenHorizonIndustries/
    └── modDesc.xml
```

That is wrong for FS25 testing.

The correct zip root is:

```text
FS25_GreenHorizonIndustries.zip
├── modDesc.xml
├── placeables/
├── xml/
└── ...
```

The Windows packager checks that `modDesc.xml` is at the top of the zip before it says the package passed.

## If Windows Blocks the Script

The `.bat` launcher runs PowerShell with:

```text
-ExecutionPolicy Bypass
```

That should avoid the normal PowerShell script-blocking issue for this local test script.

If it still fails, copy the full error text and use the manual zip method below.

## Manual Zip Method

1. Open the repo folder.
2. Open `FS25_GreenHorizonIndustries/`.
3. Select everything inside that folder.
4. Right-click > Send to > Compressed zipped folder.
5. Name it:

```text
FS25_GreenHorizonIndustries.zip
```

6. Open the zip and confirm `modDesc.xml` is immediately visible at the top level.
7. Copy it to:

```text
Documents/My Games/FarmingSimulator2025/mods
```

## Optional Python Script

The Python packager is mainly for automation and GitHub Actions.

Use this only if you are comfortable running Python from a terminal:

```text
python tools/package_mod.py
```

For normal local testing, use the Windows `.bat` files instead.
