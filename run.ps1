# =========================================================
# run.ps1 - WinKit Bootstrap & Entry Point (FINAL)
# Single entry:
# irm https://raw.githubusercontent.com/mkhai2589/winkit/main/run.ps1 | iex
# =========================================================

# =========================================================
# BASIC ENV CHECK
# =========================================================
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "PowerShell 5.1+ required" -ForegroundColor Red
    return
}

# =========================================================
# BOOTSTRAP CONFIG
# =========================================================
$GitHubBase = "https://raw.githubusercontent.com/mkhai2589/winkit/main"
$TempRoot   = Join-Path $env:TEMP "WinKit"

# =========================================================
# DOWNLOAD HELPER (SIMPLE, SAFE)
# =========================================================
function Get-RemoteFile {
    param(
        [string]$Url,
        [string]$Destination
    )

    try {
        $dir = Split-Path $Destination -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# =========================================================
# PREPARE WORK DIR
# =========================================================
$RunId   = Get-Date -Format "yyyyMMdd_HHmmss"
$WorkDir = Join-Path $TempRoot $RunId

New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
Set-Location $WorkDir

# =========================================================
# DOWNLOAD MANIFEST
# =========================================================
$manifestPath = Join-Path $WorkDir "manifest.json"

if (-not (Get-RemoteFile "$GitHubBase/manifest.json" $manifestPath)) {
    Write-Host "Failed to download manifest.json" -ForegroundColor Red
    return
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
if (-not $manifest.files) {
    Write-Host "Invalid manifest.json" -ForegroundColor Red
    return
}

# =========================================================
# DOWNLOAD FILES
# =========================================================
foreach ($file in $manifest.files) {
    $url  = "$GitHubBase/$file"
    $dest = Join-Path $WorkDir $file.Replace('/', '\')

    if (-not (Get-RemoteFile $url $dest)) {
        Write-Host "Failed to download $file" -ForegroundColor Red
        return
    }
}

# =========================================================
# DOT-SOURCE LOADER
# =========================================================
. "$WorkDir\Loader.ps1"

# =========================================================
# LOAD CORE MODULES (ORDER IS LAW)
# =========================================================
Load-Modules -Layer core -Modules @(
    'Logger',
    'Utils',
    'Context',
    'Security',
    'FeatureRegistry',
    'Interface'
)

# =========================================================
# LOAD UI MODULES
# =========================================================
Load-Modules -Layer ui -Modules @(
    'Theme',
    'Logo',
    'UI'
)

# =========================================================
# LOAD MENU
# =========================================================
. "$WorkDir\Menu.ps1"

# =========================================================
# LOAD CONFIG
# =========================================================
$Global:WinKitConfig = Get-Content "$WorkDir\config.json" -Raw | ConvertFrom-Json

# =========================================================
# INIT THEME
# =========================================================
Initialize-Theme -ColorScheme ($Global:WinKitConfig.UI.Theme ?? 'default') | Out-Null

# =========================================================
# START APPLICATION
# =========================================================
Start-Menu
