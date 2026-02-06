# =========================================================
# run.ps1 - WinKit Bootstrap (FINAL)
# =========================================================
$ErrorActionPreference = "Stop"

# ---------- Detect PowerShell ----------
$IsPS7 = $PSVersionTable.PSEdition -eq 'Core'

# ---------- Temp ----------
$BaseUrl = "https://raw.githubusercontent.com/mkhai2589/winkit/main"
$TempDir = Join-Path $env:TEMP ("WinKit_" + (Get-Date -Format "yyyyMMdd_HHmmss"))

New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Set-Location $TempDir

# ---------- Files ----------
$files = @(
    "Loader.ps1",
    "App.ps1",
    "Menu.ps1",
    "config.json",
    "version.json",
    "core/Logger.ps1",
    "core/Utils.ps1",
    "core/Security.ps1",
    "core/FeatureRegistry.ps1",
    "core/Interface.ps1",
    "ui/Theme.ps1",
    "ui/Logo.ps1",
    "ui/UI.ps1"
)

# ---------- Download ----------
foreach ($f in $files) {
    $dest = Join-Path $TempDir $f.Replace('/', '\')
    $dir = Split-Path $dest -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Invoke-RestMethod "$BaseUrl/$f" -OutFile $dest
}

# ---------- Load Config ----------
$Global:WinKitConfig = Get-Content "$TempDir\config.json" -Raw | ConvertFrom-Json

# ---------- Load Core ----------
. "$TempDir\Loader.ps1"
Load-Modules -Modules @("Logger","Utils","Security","FeatureRegistry","Interface") -Layer core
Load-Modules -Modules @("Theme","Logo","UI") -Layer ui

# ---------- START APP ----------
. "$TempDir\App.ps1"
Start-WinKit
