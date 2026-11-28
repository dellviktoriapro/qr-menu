@echo off
cd /d "%~dp0"
where node >nul 2>nul
if errorlevel 1 (
  echo Install Node.js 22 or newer from https://nodejs.org/ and reopen this file.
  pause
  exit /b 1
)
call npm ci --omit=dev --ignore-scripts
if errorlevel 1 (
  pause
  exit /b 1
)
node bridge.cjs
pause
