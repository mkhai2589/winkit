try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
}
catch {}

$WK_ROOT = Join-Path $env:TEMP "winkit"
$REPO = "https://raw.githubusercontent.com/mkhai2589/winkit/main"

Clear-Host

Write-Host "------------------------------------------" -ForegroundColor Cyan
Write-Host "              W I N K I T                 " -ForegroundColor White
Write-Host "    Windows Optimization Toolkit          " -ForegroundColor Gray
Write-Host "------------------------------------------" -ForegroundColor Cyan
Write-Host ""
Write-Host "Downloading..." -ForegroundColor Yellow
Write-Host ""

if (Test-Path $WK_ROOT) {
    Remove-Item -Path $WK_ROOT -Recurse -Force -ErrorAction SilentlyContinue
}

New-Item -ItemType Directory -Path $WK_ROOT -Force | Out-Null

$FILES = @(
    "Loader.ps1",
    "Menu.ps1",
    "config.json",
    "version.json",
    "core/Logger.ps1",
    "core/Security.ps1",
    "core/Utils.ps1",
    "core/Interface.ps1",
    "ui/logo.ps1",
    "ui/Theme.ps1",
    "ui/UI.ps1",
    "features/01_CleanSystem.ps1",
    "features/02_ActivationTool.ps1",
    "features/03_Debloat.ps1",
    "features/04_Tweaks.ps1",
    "features/05_Network.ps1",
    "features/06_InstallApps.ps1",
    "features/07_RemoveWindowsAI.ps1"
)

$success = $true
$totalFiles = $FILES.Count
$currentFile = 0

foreach ($relativePath in $FILES) {
    $currentFile++
    $percentComplete = [math]::Round(($currentFile / $totalFiles) * 100)
    
    Write-Progress -Activity "Downloading WinKit" -Status "Preparing..." -PercentComplete $percentComplete
    
    try {
        $remoteUrl = "$REPO/$relativePath"
        $localPath = Join-Path $WK_ROOT $relativePath
        $directory = Split-Path $localPath -Parent
        
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
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

if (-not $success) {
    Write-Host ""
    Write-Host "Download failed. Check internet connection." -ForegroundColor Red
    Write-Host "Press Enter to exit..." -ForegroundColor Gray
    $null = Read-Host
    exit 1
}

Write-Host ""
Write-Host "Download complete!" -ForegroundColor Green
Write-Host "Starting WinKit..." -ForegroundColor Cyan
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
