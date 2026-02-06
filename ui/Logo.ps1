# =========================================================
# ui/Logo.ps1
# WinKit ASCII Logo Renderer
#
# PURPOSE:
# - Render static ASCII logo
# - Optional centered output
#
# ❌ No business logic
# ❌ No system state
# ❌ No dependency on Feature / Context
# =========================================================

# =========================================================
# STATIC LOGO CONTENT (IMMUTABLE)
# =========================================================
$script:WinKitLogo = @"
              W I N K I T
      __        ___      _  ___ _ _
      \ \      / (_)_ __| |/ (_) | |
       \ \ /\ / /| | '__| ' /| | | |
        \ V  V / | | |  | . \| | | |
         \_/\_/  |_|_|  |_|\_\_|_|_|

        Windows Optimization Toolkit
        Author: Minh Khai  |  Contact: 0333090930
"@

# =========================================================
# GET LOGO (PURE)
# =========================================================
function Get-Logo {
    [CmdletBinding()]
    param()

    return $script:WinKitLogo
}

# =========================================================
# RENDER LOGO
# =========================================================
function Show-Logo {
    [CmdletBinding()]
    param(
        [switch]$Centered
    )

    $lines = (Get-Logo) -split "`n"

    $width = 0
    if ($Centered -and $Host.UI -and $Host.UI.RawUI) {
        $width = $Host.UI.RawUI.WindowSize.Width
    }

    foreach ($line in $lines) {
        $output = $line

        if ($Centered -and $width -gt 0) {
            $pad = [math]::Max(0, [math]::Floor(($width - $line.Length) / 2))
            $output = (' ' * $pad) + $line
        }

        Write-Host $output -ForegroundColor Cyan
    }
}

# =========================================================
# MODULE EXPORT
# =========================================================
if ($MyInvocation.InvocationName -ne '.') {
    Export-ModuleMember -Function `
        Get-Logo, `
        Show-Logo
}
