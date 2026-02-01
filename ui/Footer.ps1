# =========================================================
# WinKit - Footer.ps1
# Footer info & UX helper
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -------------------------
# SHOW FOOTER
# -------------------------
function Show-Footer {

    Write-Host ""
    Write-Colored ("-" * 60) $Global:WinKitTheme.Accent

    # Version info
    $versionText = "Version: Unknown"
    $versionPath = Join-Path $PSScriptRoot "..\version.json"

    if (Test-Path $versionPath) {
        try {
            $ver = Get-Content $versionPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($ver.version) {
                $versionText = "Version: $($ver.version)"
            }
        }
        catch {
            # ignore version read errors
        }
    }

    Write-Info $versionText

    # Project info
    Write-Info "WinKit – Windows Toolkit for Power Users"
    Write-Info "GitHub: https://github.com/mkhai2589/winkit"

    Write-Host ""
}
