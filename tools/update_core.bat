@echo off
chcp 65001 >nul
cd /d "%~dp0.."
where python >nul 2>nul
if errorlevel 1 (
  echo [ERROR] ไม่พบ Python
  pause
  exit /b 2
)
echo ตัวอย่าง: tools\update_core.bat --platform W:\...\EA_Platform_Core --version v1.0.2
python tools\update_core.py %*
pause