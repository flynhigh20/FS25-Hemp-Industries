@echo off
setlocal

cd /d "%~dp0"

echo Green Horizon Industries - Install Loose Folder For GIANTS Icon Generator
echo.
echo This will:
echo   1. Generate temporary alpha icon/store image files if missing
echo   2. Build the normal zip for backup/testing
echo   3. Remove old Green Horizon / Hemp Industries zips and loose folders from your FS25 mods folder
echo   4. Copy a complete unzipped FS25_GreenHorizonIndustries folder into your FS25 mods folder
echo.
echo Use this option when you want GIANTS Icon Generator to see the mod.
echo Use package_and_install_mod.bat when you only want normal zipped FS25 testing.
echo.
pause

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0package_mod.ps1" -InstallLoose -CleanOldZips

if errorlevel 1 (
    echo.
    echo Loose install failed. Copy the error above and send it for debugging.
    pause
    exit /b 1
)

echo.
echo Loose folder installed. Open GIANTS Icon Generator and select FS25_GreenHorizonIndustries.
echo.
pause
