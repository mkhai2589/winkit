# =========================================================
# Loader.ps1 - WinKit Module Loader (FINAL)
# =========================================================

# Global load state
if (-not $Global:WinKitLoadState) {
    $Global:WinKitLoadState = @{
        Loaded = @()
        Failed = @()
        Start = Get-Date
    }
}

function Load-Module {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        $Global:WinKitLoadState.Failed += $Path
        throw "Loader: Missing $Path"
    }

    . $Path
    $Global:WinKitLoadState.Loaded += $Path
}

function Initialize-Modules {
    # CRITICAL LOAD ORDER
    $order = @(
        "core\Logger.ps1",
        "core\Context.ps1", 
        "core\Utils.ps1",
        "core\Security.ps1",
        "core\FeatureRegistry.ps1",
        "core\Interface.ps1",
        "ui\Theme.ps1",
        "ui\Logo.ps1",
        "ui\UI.ps1",
        "Menu.ps1"
    )

    foreach ($module in $order) {
        try {
            Load-Module $module
        }
        catch {
            throw "Failed to load $module : $_"
        }
    }

    # Load all features
    $featureFiles = Get-ChildItem "features\*.ps1" -ErrorAction SilentlyContinue
    foreach ($file in $featureFiles) {
        try {
            Load-Module $file.FullName
        }
        catch {
            # Non-fatal: continue loading other features
        }
    }
}
