function Start-WinKit {
    $global:WK_ROOT = Split-Path $MyInvocation.MyCommand.Path
    $global:WK_FEATURES = Join-Path $WK_ROOT "features"
    
    try {
        # Load core
        . "$WK_ROOT\core\Security.ps1"
        . "$WK_ROOT\core\Utils.ps1"
        . "$WK_ROOT\core\Logger.ps1"
        . "$WK_ROOT\core\Interface.ps1"  # NEW
        
        # Load UI
        . "$WK_ROOT\ui\Theme.ps1"
        . "$WK_ROOT\ui\UI.ps1"
        
        # Load Menu
        . "$WK_ROOT\Menu.ps1"
        
        # Validate
        Test-WKAdmin
        
        # Start
        Initialize-UI
        Show-MainMenu
        
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        Pause
        exit 1
    }
}
