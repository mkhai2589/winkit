# =========================================================
# WinKit - run.ps1
# Entry point (irm | iex)
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -------------------------
# ROOT PATH RESOLUTION
# -------------------------
$Global:WinKitRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# In case of irm | iex (no physical file)
if (-not $WinKitRoot -or $WinKitRoot -eq "") {
    $WinKitRoot = Get-Location
}

# -------------------------
# CORE LOADER
# -------------------------
function Import-WinKitFile {
    param (
        [Parameter(Mandatory)]
        [string]$RelativePath
    )

    $fullPath = Join-Path $Global:WinKitRoot $RelativePath
    if (-not (Test-Path $fullPath)) {
        Write-Error "Required file not found: $RelativePath"
        exit
    }

    . $fullPath
}

# -------------------------
# LOAD CORE & UI
# -------------------------
try {
    Import-WinKitFile "ui\Theme.ps1"
    Import-WinKitFile "ui\Header.ps1"
    Import-WinKitFile "ui\Footer.ps1"

    Import-WinKitFile "core\Utils.ps1"
    Import-WinKitFile "core\Security.ps1"
    Import-WinKitFile "core\Environment.ps1"
    Import-WinKitFile "core\Loader.ps1"
    Import-WinKitFile "core\Menu.ps1"
}
catch {
    Write-Host "[x] Failed to load WinKit core files" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}

# -------------------------
# INITIALIZATION PIPELINE
# -------------------------
try {
    Initialize-Security
    Initialize-Environment
    Initialize-Loader
}
catch {
    Write-ErrorX "Initialization failed"
    Write-ErrorX $_.Exception.Message
    exit
}

# -------------------------
# START UI
# -------------------------
try {
    Start-Menu
}
catch {
    Write-ErrorX "Fatal error occurred"
    Write-ErrorX $_.Exception.Message
    Pause-Console
}
finally {
    Show-Footer
}
