# ==========================================
# WinKit Online Bootstrap
# Single-line installer: irm URL | iex
# ==========================================

# Set strict error handling
$ErrorActionPreference = "Stop"

# Bypass execution policy for this session only
try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
}
catch {
    # Continue execution even if policy can't be changed
}

# Configuration
$WK_ROOT = Join-Path $env:TEMP "winkit"
$REPO = "https://raw.githubusercontent.com/mkhai2589/winkit/main"

# List of required files (maintains directory structure)
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
    "ui/UI.ps1"
)

# Clear screen and show welcome message
Clear-Host
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         WinKit - Setup                   ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "Downloading latest version..." -ForegroundColor Yellow

# Create working directory
if (-not (Test-Path $WK_ROOT)) {
    New-Item -ItemType Directory -Path $WK_ROOT -Force | Out-Null
}

# Download each file
$success = $true
foreach ($relativePath in $FILES) {
    try {
        $remoteUrl = "$REPO/$relativePath"
        $localPath = Join-Path $WK_ROOT $relativePath
        $directory = Split-Path $localPath -Parent
        
        # Create directory if it doesn't exist
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        # Download file
        Write-Host "  → $relativePath" -ForegroundColor Gray
        Invoke-WebRequest -Uri $remoteUrl -UseBasicParsing -OutFile $localPath -ErrorAction Stop
        
    }
    catch {
        Write-Host "  ✗ Failed: $relativePath" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor DarkRed
        $success = $false
    }
}

# Check if download was successful
if (-not $success) {
    Write-Host "`nSome files failed to download." -ForegroundColor Red
    Write-Host "Check your internet connection and try again." -ForegroundColor Yellow
    Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
    [Console]::ReadKey($true) | Out-Null
    exit 1
}

Write-Host "`n✓ Download complete!" -ForegroundColor Green
Write-Host "Starting WinKit..." -ForegroundColor Cyan
Start-Sleep -Seconds 1

# Load and execute WinKit
try {
    . "$WK_ROOT\Loader.ps1"
    Start-WinKit
}
catch {
    Write-Host "`nFailed to start WinKit: $_" -ForegroundColor Red
    Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
    [Console]::ReadKey($true) | Out-Null
    exit 1
}
