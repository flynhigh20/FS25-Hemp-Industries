@echo off
setlocal

cd /d "%~dp0"

echo Green Horizon Industries - Preflight Check
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0preflight_check.ps1"

if errorlevel 1 (
    echo.
    echo Preflight found a problem. Copy the output above and send it for debugging.
    pause
    exit /b 1
)

echo.
echo Preflight passed.
echo.
pause
