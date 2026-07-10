@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0validate_greenhouse_export.ps1"
set "exitCode=%ERRORLEVEL%"

echo.
if not "%exitCode%"=="0" (
    echo Greenhouse export validation failed.
) else (
    echo Greenhouse export validation passed.
)

pause
exit /b %exitCode%
