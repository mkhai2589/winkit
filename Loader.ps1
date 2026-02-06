# =========================================================
# Loader.ps1
# WinKit Core Loader
#
# RESPONSIBILITY:
# - Dot-source core / ui modules
# - Track load state
#
# HARD RULES:
# ❌ No UI output
# ❌ No color / Write-Host
# ❌ No dependency on Logger / UI
# =========================================================

# =========================================================
# GLOBAL LOAD STATE
# =========================================================
if (-not $Global:WinKitLoadState) {
    $Global:WinKitLoadState = @{
        Loaded  = @()
        Failed  = @()
        Started = Get-Date
    }
}

# =========================================================
# LOAD SINGLE MODULE (DOT-SOURCE)
# =========================================================
function Load-CoreModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter(Mandatory=$false)]
        [ValidateSet('core','ui')]
        [string]$Layer = 'core'
    )

    $path = Join-Path $Layer "$ModuleName.ps1"

    if (-not (Test-Path $path)) {
        $Global:WinKitLoadState.Failed += $ModuleName
        throw "Loader: File not found -> $path"
    }

    try {
        # Dot-source
        . $path

        # Basic validation (optional & safe)
        if ($ModuleName -eq 'Logger') {
            if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
                throw "Logger loaded but Write-Log not found"
            }
        }

        $Global:WinKitLoadState.Loaded += $ModuleName
        return $true
    }
    catch {
        $Global:WinKitLoadState.Failed += $ModuleName
        throw "Loader: Failed to load $ModuleName -> $($_.Exception.Message)"
    }
}

# =========================================================
# LOAD MULTIPLE MODULES (ORDERED)
# =========================================================
function Load-Modules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Modules,

        [Parameter(Mandatory=$false)]
        [ValidateSet('core','ui')]
        [string]$Layer = 'core'
    )

    foreach ($module in $Modules) {
        Load-CoreModule -ModuleName $module -Layer $Layer
    }

    return $true
}

# =========================================================
# QUERY LOAD STATE (READ ONLY)
# =========================================================
function Get-LoadState {
    [CmdletBinding()]
    param()

    return [PSCustomObject]@{
        Loaded   = $Global:WinKitLoadState.Loaded
        Failed   = $Global:WinKitLoadState.Failed
        Duration = (Get-Date) - $Global:WinKitLoadState.Started
    }
}
