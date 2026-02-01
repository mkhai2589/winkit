# ==========================================
# WinKit - Single Line Installer & Launcher
# ==========================================

# Exit on any error
$ErrorActionPreference = "Stop"

# Set Execution Policy for this session only
try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
}
catch {
    # Continue if we can't change policy
}

# Configuration
$WK_ROOT = Join-Path $env:TEMP "winkit"
$REPO = "https://raw.githubusercontent.com/mkhai2589/winkit/main"

# All required files
$FILES = @(
    "Loader.ps1",
    "Dashboard.ps1",  # Renamed from Menu.ps1
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

# Clear console and show header
Clear-Host
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "    WinKit - Windows Optimization Toolkit" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Downloading latest version..." -ForegroundColor Yellow

# Create directory if needed
if (-not (Test-Path $WK_ROOT)) {
    New-Item -ItemType Directory -Path $WK_ROOT -Force | Out-Null
}

# Download all files
$success = $true
foreach ($f in $FILES) {
    try {
        $dest = Join-Path $WK_ROOT $f
        $dir = Split-Path $dest -Parent
        
        # Create directory structure
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        # Download file
        Write-Host "  [✓] $f" -ForegroundColor Gray
        Invoke-WebRequest "$REPO/$f" -UseBasicParsing -OutFile $dest -ErrorAction Stop
    }
    catch {
        Write-Host "  [✗] $f" -ForegroundColor Red
        Write-Host "      Error: $_" -ForegroundColor DarkRed
        $success = $false
    }
}

# Check if download was successful
if (-not $success) {
    Write-Host "`nSome files failed to download." -ForegroundColor Red
    Write-Host "Please check your internet connection and try again." -ForegroundColor Yellow
    Read-Host "`nPress Enter to exit"
    exit 1
}

Write-Host "`nDownload complete! Starting WinKit..." -ForegroundColor Green
Start-Sleep -Seconds 1

# Load and execute
try {
    . "$WK_ROOT\Loader.ps1"
    Start-WinKit
}
catch {
    Write-Host "`nERROR: Failed to start WinKit" -ForegroundColor Red
    Write-Host "Details: $_" -ForegroundColor DarkRed
    Read-Host "`nPress Enter to exit"
    exit 1
}
