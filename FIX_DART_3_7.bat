@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo ==============================================
echo   PERBAIKAN DEPENDENCY LEMBUR - DART 3.7.x
echo ==============================================
echo.

if not exist "pubspec.yaml" (
  echo ERROR: Jalankan file ini dari root project Lembur.
  pause
  exit /b 1
)

where flutter >nul 2>&1
if errorlevel 1 (
  echo ERROR: Flutter tidak ditemukan di PATH.
  pause
  exit /b 1
)

echo [1/6] Memeriksa versi Flutter dan Dart...
call flutter --version

echo.
echo [2/6] Menghapus hasil resolver lama...
if exist "pubspec.lock" del /F /Q "pubspec.lock"
if exist ".dart_tool" rmdir /S /Q ".dart_tool"

echo [3/6] Membersihkan project...
call flutter clean
if errorlevel 1 goto :failed

echo [4/6] Mengambil dependency kompatibel Dart 3.7...
call flutter pub get
if errorlevel 1 goto :failed

echo [5/6] Membuat ulang icon launcher...
call dart run flutter_launcher_icons
if errorlevel 1 goto :failed

echo [6/6] Memeriksa kode dan unit test...
call flutter analyze
if errorlevel 1 goto :failed
call flutter test
if errorlevel 1 goto :failed

echo.
echo ==============================================
echo BERHASIL. Jalankan aplikasi dengan: flutter run
echo ==============================================
pause
exit /b 0

:failed
echo.
echo PROSES BERHENTI karena masih ada error.
echo Salin seluruh pesan error terakhir ke ChatGPT.
pause
exit /b 1
