@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_to_project.ps1" -TargetPath "D:\Flutter\Project\lembur"
if errorlevel 1 (
  echo.
  echo Instalasi gagal. Baca pesan error di atas.
  pause
  exit /b 1
)
echo.
pause
