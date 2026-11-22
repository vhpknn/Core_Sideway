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

%PY% sync_core.py %*
set RC=%ERRORLEVEL%
if %RC%==2 goto done
if %RC%==1 (
  echo.
  choice /c YN /m "คัดลอก Core ต้นฉบับทับสำเนา - ไฟล์เดิมจะถูกสำรองไว้ ใช่หรือไม่"
  if errorlevel 2 goto done
  %PY% sync_core.py --apply --yes %*
)
:done
echo.
pause