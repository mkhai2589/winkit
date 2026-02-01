function Start-WinKit {
    try {
        # Set global variables - FIXED: Use correct path
        $global:WK_ROOT = $PSScriptRoot
        $global:WK_FEATURES = Join-Path $WK_ROOT "features"
        $global:WK_LOG = Join-Path $env:TEMP "winkit.log"

        # Debug info
        Write-Host "`n[DEBUG] WK_ROOT: $WK_ROOT" -ForegroundColor DarkGray
        Write-Host "[DEBUG] Loading modules..." -ForegroundColor DarkGray

        # Load core modules
        . "$WK_ROOT\core\Security.ps1"
        . "$WK_ROOT\core\Utils.ps1"
        . "$WK_ROOT\core\Logger.ps1"
        . "$WK_ROOT\core\Interface.ps1"

        # Load UI modules
        . "$WK_ROOT\ui\Theme.ps1"
        . "$WK_ROOT\ui\UI.ps1"

        # Load Menu
        . "$WK_ROOT\Menu.ps1"

        # Validate admin
        Test-WKAdmin
        
        # Initialize UI and show menu
        Initialize-UI
        Show-MainMenu
    }
    catch {
        Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nWinKit has encountered an error. Press Enter to exit..."
        [Console]::ReadKey($true)
        exit 1
    }
}
