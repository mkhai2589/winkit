# =========================================================
# WinKit - run.ps1 (IRM SAFE FINAL)
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoOwner = "mkhai2589"
$RepoName  = "winkit"
$Branch    = "main"

# ---------------------------------------------------------
# DETECT EXECUTION MODE
# ---------------------------------------------------------
$HasPhysicalFile = $false
try {
    if ($PSScriptRoot -and (Test-Path $PSScriptRoot)) {
        $HasPhysicalFile = $true
    }
} catch {}

# ---------------------------------------------------------
# RESOLVE ROOT PATH
# ---------------------------------------------------------
if ($HasPhysicalFile) {
    $Global:WinKitRoot = $PSScriptRoot
}
else {
    Write-Host "[*] Running via irm | iex — bootstrapping WinKit..." -ForegroundColor Cyan

    $Global:WinKitRoot = Join-Path $env:TEMP "WinKit"
    $zipUrl  = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$Branch.zip"
    $zipFile = "$Global:WinKitRoot.zip"

    if (Test-Path $Global:WinKitRoot) {
        Remove-Item $Global:WinKitRoot -Recurse -Force
    }

    Invoke-WebRequest $zipUrl -OutFile $zipFile -UseBasicParsing
    Expand-Archive $zipFile -DestinationPath $env:TEMP -Force
    Remove-Item $zipFile -Force

    $Global:WinKitRoot = Join-Path $env:TEMP "$RepoName-$Branch"
}

# ---------------------------------------------------------
# SAFE IMPORT FUNCTION
# ---------------------------------------------------------
function Import-WinKitFile {
    param (
        [Parameter(Mandatory)]
        [string]$RelativePath
    )

    $fullPath = Join-Path $Global:WinKitRoot $RelativePath

    if (-not (Test-Path $fullPath)) {
        Write-Host "[x] Missing file: $RelativePath" -ForegroundColor Red
        exit 1
    }

    . $fullPath
}

# ---------------------------------------------------------
# LOAD UI
# ---------------------------------------------------------
Import-WinKitFile "ui\Theme.ps1"
Import-WinKitFile "ui\Header.ps1"
Import-WinKitFile "ui\Footer.ps1"

# ---------------------------------------------------------
# LOAD CORE
# ---------------------------------------------------------
Import-WinKitFile "core\Utils.ps1"
Import-WinKitFile "core\Security.ps1"
Import-WinKitFile "core\Environment.ps1"
Import-WinKitFile "core\Loader.ps1"
Import-WinKitFile "core\Menu.ps1"

# ---------------------------------------------------------
# INIT PIPELINE
# ---------------------------------------------------------
Initialize-Security
Initialize-Environment
Initialize-Loader

# ---------------------------------------------------------
# START UI
# ---------------------------------------------------------
Start-Menu
Show-Footer
