@echo off
setlocal

cd /d "%~dp0"

echo Green Horizon Industries - FS25 Log Checker
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0check_fs25_log.ps1"

if errorlevel 1 (
    echo.
    echo Log checker failed or could not find the FS25 log.
    echo Copy the error above and send it for debugging.
    pause
    exit /b 1
)

echo.
pause
