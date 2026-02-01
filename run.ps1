# ==========================================
# WinKit Online Bootstrap
# Single-line installer: irm URL | iex
# ==========================================

try {
    # Bypass execution policy for this session only
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
}
catch {
    # Continue execution even if policy can't be changed
}

# Configuration
$WK_ROOT = Join-Path $env:TEMP "winkit"
$REPO = "https://raw.githubusercontent.com/mkhai2589/winkit/main"

# Clear screen and show logo
Clear-Host
Write-Host "------------------------------------------" -ForegroundColor Cyan
Write-Host "              W I N K I T                 " -ForegroundColor White
Write-Host "    Windows Optimization Toolkit          " -ForegroundColor Gray
Write-Host "------------------------------------------" -ForegroundColor Cyan
Write-Host ""

Write-Host "Downloading..." -ForegroundColor Yellow

# Create working directory
if (-not (Test-Path $WK_ROOT)) {
    New-Item -ItemType Directory -Path $WK_ROOT -Force | Out-Null
}

# List of required files
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
    "features/02_ActivationTool.ps1",
    "features/03_Debloat.ps1",
    "features/05_Network.ps1",
    "features/06_InstallApps.ps1",
    "features/07_RemoveWindowsAI.ps1"
)

# Download each file with progress
$success = $true
$totalFiles = $FILES.Count
$currentFile = 0

foreach ($relativePath in $FILES) {
    $currentFile++
    try {
        $remoteUrl = "$REPO/$relativePath"
        $localPath = Join-Path $WK_ROOT $relativePath
        $directory = Split-Path $localPath -Parent
        
        # Create directory if it doesn't exist
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        # Show progress
        $percent = [math]::Round(($currentFile / $totalFiles) * 100)
        Write-Progress -Activity "Downloading WinKit" -Status "$percent% Complete" -PercentComplete $percent
        
        # Download file
        Invoke-WebRequest -Uri $remoteUrl -UseBasicParsing -OutFile $localPath -ErrorAction Stop
        
    }
    catch {
        Write-Progress -Activity "Downloading WinKit" -Completed
        Write-Host "  [ERROR] Failed to download: $relativePath" -ForegroundColor Red
        $success = $false
        break
    }
}

Write-Progress -Activity "Downloading WinKit" -Completed

# Check if download was successful
if (-not $success) {
    Write-Host "`nSome files failed to download." -ForegroundColor Red
    Write-Host "Check your internet connection and try again." -ForegroundColor Yellow
    Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
    $null = Read-Host
    exit 1
}

Write-Host "`nDownload complete!" -ForegroundColor Green
Write-Host "Starting WinKit..." -ForegroundColor Cyan
Start-Sleep -Seconds 1

# Load and execute WinKit
try {
    # Load Loader first, then start
    . "$WK_ROOT\Loader.ps1"
    Start-WinKit
}
catch {
    Write-Host "`nFailed to start WinKit: $_" -ForegroundColor Red
    Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
    $null = Read-Host
    exit 1
}
