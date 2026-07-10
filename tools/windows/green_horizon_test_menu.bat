@echo off
setlocal

:MENU
cls
echo ==============================================
echo   Green Horizon Industries - Test Menu
echo ==============================================
echo.
echo  1. Preflight check repo files
echo  2. Package only
echo  3. Package and install ZIP to FS25 mods folder
echo  4. Check FS25 log after running game
echo  5. Open Windows packaging guide
echo  6. Open test checklist
echo  7. Install LOOSE folder for GIANTS Icon Generator
echo  8. Check field hemp foundation drafts
echo  9. Generate greenhouse model and materials
echo 10. Generate field foliage, icons, and cutter assets
echo 11. Generate product pallet source assets
echo 12. Generate ALL Blender source assets
echo 13. Repair texture paths and validate greenhouse i3d
echo 14. Open asset generation workflow
echo 15. Show project status and next action
echo  0. Exit
echo.
set /p choice=Pick an option: 

if "%choice%"=="1" goto PREFLIGHT
if "%choice%"=="2" goto PACKAGE_ONLY
if "%choice%"=="3" goto PACKAGE_INSTALL
if "%choice%"=="4" goto LOG_CHECK
if "%choice%"=="5" goto OPEN_PACKAGING_DOC
if "%choice%"=="6" goto OPEN_CHECKLIST
if "%choice%"=="7" goto INSTALL_LOOSE
if "%choice%"=="8" goto FIELD_CHECK
if "%choice%"=="9" goto GENERATE_GREENHOUSE
if "%choice%"=="10" goto GENERATE_FIELD
if "%choice%"=="11" goto GENERATE_PALLETS
if "%choice%"=="12" goto GENERATE_ALL
if "%choice%"=="13" goto VALIDATE_EXPORT
if "%choice%"=="14" goto OPEN_ASSET_WORKFLOW
if "%choice%"=="15" goto PROJECT_STATUS
if "%choice%"=="0" goto END

echo.
echo Not a valid option.
pause
goto MENU

:PREFLIGHT
call "%~dp0preflight_check.bat"
goto MENU

:PACKAGE_ONLY
call "%~dp0package_mod.bat"
goto MENU

:PACKAGE_INSTALL
call "%~dp0package_and_install_mod.bat"
goto MENU

:LOG_CHECK
call "%~dp0check_fs25_log.bat"
goto MENU

:OPEN_PACKAGING_DOC
start "" "%~dp0..\..\docs\Windows-Packaging.md"
goto MENU

:OPEN_CHECKLIST
start "" "%~dp0..\..\docs\Test-Checklist.md"
goto MENU

:INSTALL_LOOSE
call "%~dp0install_loose_mod_for_icon_generator.bat"
goto MENU

:FIELD_CHECK
call "%~dp0check_hemp_field_foundation.bat"
goto MENU

:GENERATE_GREENHOUSE
call "%~dp0generate_project_assets.bat" greenhouse
goto MENU

:GENERATE_FIELD
call "%~dp0generate_project_assets.bat" field
goto MENU

:GENERATE_PALLETS
call "%~dp0generate_project_assets.bat" pallets
goto MENU

:GENERATE_ALL
call "%~dp0generate_project_assets.bat" all
goto MENU

:VALIDATE_EXPORT
call "%~dp0validate_greenhouse_export.bat"
goto MENU

:OPEN_ASSET_WORKFLOW
start "" "%~dp0..\..\docs\Asset-Generation-Workflow.md"
goto MENU

:PROJECT_STATUS
call "%~dp0show_project_status.bat"
goto MENU

:END
exit /b 0
