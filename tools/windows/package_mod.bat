@echo off
setlocal

cd /d "%~dp0"

echo Green Horizon Industries - Windows Packager
echo.
echo This will build FS25_GreenHorizonIndustries.zip with modDesc.xml at the top of the zip.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0package_mod.ps1"

if errorlevel 1 (
    echo.
    echo Packaging failed. Copy the error above and send it for debugging.
    pause
    exit /b 1
)

echo.
echo Zip created in the repo dist folder.
echo Copy dist\FS25_GreenHorizonIndustries.zip to your FS25 mods folder.
echo.
pause
