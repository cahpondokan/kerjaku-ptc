@echo off
setlocal EnableExtensions
set "SOURCE=%~dp0"
set "TARGET=%~1"
if "%TARGET%"=="" set "TARGET=D:\Flutter\Project\lembur"
if not exist "%TARGET%\pubspec.yaml" (
  set /p TARGET=Masukkan path project Lembur: 
)
if not exist "%TARGET%\pubspec.yaml" (
  echo ERROR: Project Flutter tidak ditemukan.
  pause
  exit /b 1
)
copy /Y "%SOURCE%pubspec.yaml" "%TARGET%\pubspec.yaml" >nul
copy /Y "%SOURCE%FIX_DART_3_7.bat" "%TARGET%\FIX_DART_3_7.bat" >nul
cd /d "%TARGET%"
call FIX_DART_3_7.bat
