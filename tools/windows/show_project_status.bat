@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0show_project_status.ps1"
set "exitCode=%ERRORLEVEL%"

echo.
pause
exit /b %exitCode%
