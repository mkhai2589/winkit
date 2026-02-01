$ErrorActionPreference = "Stop"

# Fix Execution Policy - Bypass for current process only
try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
}
catch {
    # Ignore if we can't change policy
}

$WK_ROOT = Join-Path $env:TEMP "winkit"
$REPO = "https://raw.githubusercontent.com/mkhai2589/winkit/main"

# DANH SÁCH FILE ĐẦY ĐỦ
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
    "features/01_CleanSystem.ps1"
)

Write-Host "WinKit - Windows Optimization Toolkit" -ForegroundColor Cyan
Write-Host "Downloading latest version..." -ForegroundColor Yellow

if (-not (Test-Path $WK_ROOT)) {
    New-Item -ItemType Directory -Path $WK_ROOT -Force | Out-Null
}

foreach ($f in $FILES) {
    try {
        $dest = Join-Path $WK_ROOT $f
        $dir = Split-Path $dest -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        Write-Host "  Downloading: $f" -ForegroundColor Gray
        Invoke-RestMethod "$REPO/$f" -UseBasicParsing -OutFile $dest -ErrorAction Stop
    }
    catch {
        Write-Host "  ERROR: Failed to download $f" -ForegroundColor Red
        Write-Host "  Details: $_" -ForegroundColor DarkRed
        exit 1
    }
}

Write-Host "`nDownload complete!" -ForegroundColor Green
Write-Host "Starting WinKit..." -ForegroundColor Cyan
Start-Sleep -Seconds 1

# Load and execute
try {
    . "$WK_ROOT\Loader.ps1"
    Start-WinKit
}
catch {
    Write-Host "`nFailed to start WinKit: $_" -ForegroundColor Red
    Write-Host "`nPress Enter to exit..."
    [Console]::ReadKey($true)
    exit 1
}
