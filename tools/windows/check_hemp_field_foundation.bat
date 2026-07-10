@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check_hemp_field_foundation.ps1"
set "exitCode=%ERRORLEVEL%"

echo.
if not "%exitCode%"=="0" (
    echo Field hemp foundation check failed.
) else (
    echo Field hemp foundation check passed.
)

pause
exit /b %exitCode%
