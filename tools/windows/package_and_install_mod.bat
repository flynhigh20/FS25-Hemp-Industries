@echo off
setlocal

cd /d "%~dp0"

echo Green Horizon Industries - Package and Install
echo.
echo This will:
echo   1. Build FS25_GreenHorizonIndustries.zip
echo   2. Remove old Green Horizon / Hemp Industries zips and loose folders from your FS25 mods folder
echo   3. Copy the new zip into your FS25 mods folder
echo.
pause

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0package_mod.ps1" -Install -CleanOldZips

if errorlevel 1 (
    echo.
    echo Packaging/install failed. Copy the error above and send it for debugging.
    pause
    exit /b 1
)

echo.
echo Installed. Start FS25 and confirm the mod list shows the current version.
echo.
pause
