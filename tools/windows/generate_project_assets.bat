@echo off
setlocal

set "target=%~1"
if "%target%"=="" set "target=all"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0generate_project_assets.ps1" -Target "%target%"
set "exitCode=%ERRORLEVEL%"

echo.
if not "%exitCode%"=="0" (
    echo Asset generation failed. Check build\logs\blender in the repo.
) else (
    echo Asset generation completed for target: %target%
)

pause
exit /b %exitCode%
