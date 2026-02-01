# ==========================================
# WinKit Loader
# Minimal initialization
# ==========================================

function Start-WinKit {
    try {
        # Set global paths
        $global:WK_ROOT = $PSScriptRoot
        $global:WK_FEATURES = Join-Path $WK_ROOT "features"
        $global:WK_LOG = Join-Path $env:TEMP "winkit.log"
        
        # Load core modules
        . "$WK_ROOT\core\Security.ps1"
        . "$WK_ROOT\core\Utils.ps1"
        . "$WK_ROOT\core\Logger.ps1"
        . "$WK_ROOT\core\Interface.ps1"
        
        # Load UI modules
        . "$WK_ROOT\ui\Theme.ps1"
        . "$WK_ROOT\ui\UI.ps1"
        
        # Load Dashboard (replaces Menu)
        . "$WK_ROOT\Dashboard.ps1"
        
        # Validate and start
        Test-WKAdmin
        Initialize-UI
        Show-Dashboard
    }
    catch {
        Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPress Enter to exit..."
        [Console]::ReadKey($true)
        exit 1
    }
}
