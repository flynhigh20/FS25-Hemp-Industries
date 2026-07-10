@echo off
setlocal

rem Blender can print a harmless oneTBB allocator replacement warning to stderr
rem on some Windows builds. PowerShell treats that stderr text as a terminating
rem NativeCommandError because the generator uses ErrorActionPreference=Stop.
rem Disable allocator replacement before Blender starts so the workflow can run.
set "TBB_MALLOC_DISABLE_REPLACEMENT=1"

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
