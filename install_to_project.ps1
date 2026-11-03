param(
    [Parameter(Mandatory = $false)]
    [string]$TargetPath = "D:\Flutter\Project\lembur"
)

$ErrorActionPreference = "Stop"
$SourcePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetPath = [System.IO.Path]::GetFullPath($TargetPath)

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  INSTALLER LEMBUR PTC V9 - OUTPUT & OVERFLOW FIX" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Sumber : $SourcePath"
Write-Host "Target : $TargetPath"
Write-Host ""

if (-not (Test-Path $TargetPath)) {
    throw "Folder target tidak ditemukan: $TargetPath"
}

$TargetPubspec = Join-Path $TargetPath "pubspec.yaml"
if (-not (Test-Path $TargetPubspec)) {
    throw "Target bukan root project Flutter karena pubspec.yaml tidak ditemukan."
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ProjectParent = Split-Path -Parent $TargetPath
$BackupRoot = Join-Path $ProjectParent "_lembur_backups"
$BackupPath = Join-Path $BackupRoot "before_v9_$Timestamp"
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

# Pindahkan folder backup lama dari dalam project. Flutter analyze ikut membaca
# semua file Dart yang berada di bawah root project, termasuk backup installer lama.
$LegacyBackupPath = Join-Path $BackupRoot "legacy_from_project_$Timestamp"
$LegacyDirectories = @(Get-ChildItem -Path $TargetPath -Directory -Force |
    Where-Object {
        $_.Name -like "_backup_before_*" -or
        $_.Name -like "backup_fix_*" -or
        $_.Name -like "_backup_fix_*"
    })

if ($LegacyDirectories.Count -gt 0) {
    New-Item -ItemType Directory -Path $LegacyBackupPath -Force | Out-Null
    foreach ($LegacyDirectory in $LegacyDirectories) {
        $Destination = Join-Path $LegacyBackupPath $LegacyDirectory.Name
        Write-Host "Memindahkan backup lama keluar project: $($LegacyDirectory.Name)" -ForegroundColor DarkYellow
        Move-Item -Path $LegacyDirectory.FullName -Destination $Destination -Force
    }
    Write-Host "Backup lama dipindahkan ke: $LegacyBackupPath" -ForegroundColor Green
}

$BackupItems = @(
    "lib",
    "assets",
    "test",
    "docs",
    "android\app",
    "pubspec.yaml",
    "analysis_options.yaml",
    "README.md",
    "CHANGELOG.md"
)

foreach ($Item in $BackupItems) {
    $Existing = Join-Path $TargetPath $Item
    if (Test-Path $Existing) {
        $Destination = Join-Path $BackupPath $Item
        $DestinationParent = Split-Path -Parent $Destination
        if ($DestinationParent) {
            New-Item -ItemType Directory -Path $DestinationParent -Force | Out-Null
        }
        Copy-Item $Existing $Destination -Recurse -Force
    }
}

Write-Host "Backup project dibuat di luar root project:" -ForegroundColor Green
Write-Host "$BackupPath" -ForegroundColor Green

# Hapus source-code lama agar file usang versi sebelumnya tidak tertinggal.
$ReplaceDirectories = @("lib", "assets", "test", "docs")
foreach ($Directory in $ReplaceDirectories) {
    $ExistingDirectory = Join-Path $TargetPath $Directory
    if (Test-Path $ExistingDirectory) {
        Remove-Item $ExistingDirectory -Recurse -Force
    }
}

$Directories = @("lib", "assets", "test", "docs", "android\app")
foreach ($Directory in $Directories) {
    $SourceDirectory = Join-Path $SourcePath $Directory
    $TargetDirectory = Join-Path $TargetPath $Directory
    if (Test-Path $SourceDirectory) {
        New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null
        Copy-Item (Join-Path $SourceDirectory "*") $TargetDirectory -Recurse -Force
    }
}

$Files = @(
    "pubspec.yaml",
    "analysis_options.yaml",
    "README.md",
    "CHANGELOG.md"
)
foreach ($File in $Files) {
    Copy-Item (Join-Path $SourcePath $File) (Join-Path $TargetPath $File) -Force
}

$LockFile = Join-Path $TargetPath "pubspec.lock"
$DartTool = Join-Path $TargetPath ".dart_tool"
if (Test-Path $LockFile) {
    Remove-Item $LockFile -Force
}
if (Test-Path $DartTool) {
    Remove-Item $DartTool -Recurse -Force
}

Push-Location $TargetPath
try {
    Write-Host ""
    Write-Host "Menjalankan flutter clean..." -ForegroundColor Yellow
    flutter clean
    if ($LASTEXITCODE -ne 0) { throw "flutter clean gagal." }

    Write-Host "Menjalankan flutter pub get..." -ForegroundColor Yellow
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get gagal." }

    Write-Host "Membuat ikon launcher..." -ForegroundColor Yellow
    dart run flutter_launcher_icons
    if ($LASTEXITCODE -ne 0) { throw "Pembuatan ikon gagal." }

    # Format hanya source dan test, bukan folder backup atau hasil build.
    Write-Host "Menjalankan dart format pada lib dan test..." -ForegroundColor Yellow
    dart format lib test
    if ($LASTEXITCODE -ne 0) { throw "dart format gagal." }

    Write-Host "Menjalankan flutter analyze..." -ForegroundColor Yellow
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw "flutter analyze masih menemukan masalah." }

    Write-Host "Menjalankan flutter test..." -ForegroundColor Yellow
    flutter test
    if ($LASTEXITCODE -ne 0) { throw "flutter test gagal." }

    Write-Host "Membangun APK debug..." -ForegroundColor Yellow
    flutter build apk --debug
    if ($LASTEXITCODE -ne 0) { throw "Build APK debug gagal." }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " INSTALASI LEMBUR V9 SELESAI" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "Backup tersimpan di:"
Write-Host "$BackupPath"
Write-Host ""
Write-Host "Jalankan aplikasi dengan:"
Write-Host "cd `"$TargetPath`""
Write-Host "flutter run"
