# =========================================================
# Loader.ps1 - WinKit Core Loader (FINAL)
# =========================================================

if (-not $Global:WinKitLoadState) {
    $Global:WinKitLoadState = @{
        Loaded  = @()
        Failed  = @()
        Started = Get-Date
    }
}

function Load-CoreModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName,
        [ValidateSet('core','ui')][string]$Layer = 'core'
    )

    $path = Join-Path $Layer "$ModuleName.ps1"

    if (-not (Test-Path $path)) {
        $Global:WinKitLoadState.Failed += $ModuleName
        throw "Loader: File not found -> $path"
    }

    try {
        . $path

        if ($ModuleName -eq 'Logger') {
            if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
                throw "Logger loaded but Write-Log missing"
            }
        }

        $Global:WinKitLoadState.Loaded += $ModuleName
        return $true
    }
    catch {
        $Global:WinKitLoadState.Failed += $ModuleName
        throw "Loader: Failed $ModuleName -> $($_.Exception.Message)"
    }
}

function Load-Modules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Modules,
        [ValidateSet('core','ui')][string]$Layer = 'core'
    )

    foreach ($m in $Modules) {
        Load-CoreModule -ModuleName $m -Layer $Layer
    }
    return $true
}

function Get-LoadState {
    [CmdletBinding()]
    param()

    [PSCustomObject]@{
        Loaded   = $Global:WinKitLoadState.Loaded
        Failed   = $Global:WinKitLoadState.Failed
        Duration = (Get-Date) - $Global:WinKitLoadState.Started
    }
}
