@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0verify_installed_mod.ps1"
set "exitCode=%ERRORLEVEL%"

echo.
if not "%exitCode%"=="0" (
    echo Installed mod check failed.
) else (
    echo Installed mod check passed.
)

pause
exit /b %exitCode%
