@echo off
chcp 65001 >nul
set PYTHONUTF8=1
cd /d "%~dp0"
set "PY="
where py >nul 2>nul && set "PY=py"
if not defined PY (where python >nul 2>nul && set "PY=python")
if not defined PY (
  echo [ERROR] ไม่พบ Python - ติดตั้ง Python 3 แล้วลองใหม่
  pause
  exit /b 2
)

%PY% verify_core.py %*
echo.
pause