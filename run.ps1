$ErrorActionPreference = "Stop"

$WK_ROOT = Join-Path $env:TEMP "winkit"
$REPO = "https://raw.githubusercontent.com/mkhai2589/winkit/main"

$FILES = @(
    "Loader.ps1",
    "Menu.ps1",
    "config.json",
    "version.json",
    "core/Logger.ps1",
    "core/Security.ps1",
    "core/Utils.ps1",
    "ui/Theme.ps1",
    "ui/UI.ps1"
)

if (-not (Test-Path $WK_ROOT)) {
    New-Item -ItemType Directory -Path $WK_ROOT -Force | Out-Null
}

foreach ($f in $FILES) {
    $dest = Join-Path $WK_ROOT $f
    $dir = Split-Path $dest
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    Invoke-WebRequest "$REPO/$f" -UseBasicParsing -OutFile $dest
}

. "$WK_ROOT\Loader.ps1"
Start-WinKit
