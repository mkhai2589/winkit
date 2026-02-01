# =========================================================
# WinKit - Header.ps1
# ASCII banner & branding header
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -------------------------
# SHOW HEADER
# -------------------------
function Show-Header {

    Clear-Host

    # Load ASCII if exists
    $asciiPath = Join-Path $PSScriptRoot "..\assets\ascii.txt"
    if (Test-Path $asciiPath) {
        $ascii = Get-Content $asciiPath -Encoding UTF8
        foreach ($line in $ascii) {
            Write-Title $line
        }
    }
    else {
        Write-Title "WinKit"
    }

    Write-Host ""
    Write-Accent "Windows Toolkit for Power Users"
    Write-Host ""

    # Environment info (safe, read-only)
    if ($Global:WinKitEnv) {
        Write-Info ("OS: {0} | Build: {1} | Arch: {2}" -f `
            $Global:WinKitEnv.Generation,
            $Global:WinKitEnv.Build,
            $Global:WinKitEnv.Architecture
        )
    }

    Write-Colored ("-" * 60) $Global:WinKitTheme.Accent
}
