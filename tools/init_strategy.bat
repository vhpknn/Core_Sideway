@echo off
chcp 65001 >nul
cd /d "%~dp0.."
where python >nul 2>nul
if errorlevel 1 (
  echo [ERROR] ไม่พบ Python
  pause
  exit /b 2
)
python tools\init_strategy.py %*
pause