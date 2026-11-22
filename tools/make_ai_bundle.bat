@echo off
chcp 65001 >nul
cd /d "%~dp0.."
where py >nul 2>nul
if %errorlevel%==0 (
  py -3 "tools\make_ai_bundle.py" %*
) else (
  where python >nul 2>nul
  if errorlevel 1 (
    echo [ERROR] ไม่พบ Python
    pause
    exit /b 2
  )
  python "tools\make_ai_bundle.py" %*
)
echo.
pause