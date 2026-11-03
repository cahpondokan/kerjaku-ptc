@echo off
setlocal
cd /d "%~dp0"
if "%~1"=="" (
  set "TARGET=D:\Flutter\Project\lembur"
) else (
  set "TARGET=%~1"
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_to_project.ps1" -TargetPath "%TARGET%"
if errorlevel 1 (
  echo.
  echo Instalasi gagal. Baca pesan error di atas.
  pause
  exit /b 1
)
echo.
pause
