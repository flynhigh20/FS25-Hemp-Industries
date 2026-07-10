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

:END
exit /b 0
