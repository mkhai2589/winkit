$ErrorActionPreference = "Stop"

try {
    Set-ExecutionPolicy Bypass -Scope Process -Force
}
catch {}

$WK_ROOT = Join-Path $env:TEMP "winkit"
$REPO = "https://raw.githubusercontent.com/mkhai2589/winkit/main"

Clear-Host
Write-Host "=== WinKit Setup ===" -ForegroundColor Cyan
Write-Host "Downloading..." -ForegroundColor Yellow

if (-not (Test-Path $WK_ROOT)) {
    New-Item -ItemType Directory -Path $WK_ROOT -Force | Out-Null
}

$FILES = @(
    "Loader.ps1",
    "Menu.ps1",
    "config.json",
    "version.json",
    "core/Logger.ps1",
    "core/Security.ps1",
    "core/Utils.ps1",
    "core/Interface.ps1",
    "ui/Theme.ps1",
    "ui/UI.ps1",
    "features/01_CleanSystem.ps1",
    "features/02_Activation.ps1",
    "features/03_Debloat.ps1",
    "features/04_Tweaks.ps1",
    "features/05_Network.ps1",
    "features/06_InstallApps.ps1",
    "features/07_RemoveWindowsAI.ps1"
)

foreach ($file in $FILES) {
    try {
        $remote = "$REPO/$file"
        $local = Join-Path $WK_ROOT $file
        $dir = Split-Path $local -Parent
        
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        Write-Host "  -> $file" -ForegroundColor Gray
        Invoke-WebRequest -Uri $remote -UseBasicParsing -OutFile $local -ErrorAction Stop
    }
    catch {
        Write-Host "  X Failed: $file" -ForegroundColor Red
        Write-Host "Press Enter to exit..." -ForegroundColor Gray
        $null = Read-Host
        exit 1
    }
}

Write-Host ""
Write-Host "Starting WinKit..." -ForegroundColor Green
Start-Sleep -Seconds 1

try {
    . "$WK_ROOT\Loader.ps1"
    Start-WinKit
}
catch {
    Write-Host "Failed to start: $_" -ForegroundColor Red
    Write-Host "Press Enter to exit..." -ForegroundColor Gray
    $null = Read-Host
    exit 1
}
