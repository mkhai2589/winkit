function Start-WinKit {
    try {
        # Set global paths
        $global:WK_ROOT = $PSScriptRoot
        $global:WK_FEATURES = Join-Path $WK_ROOT "features"
        
        # Load core modules in correct order
        . "$WK_ROOT\core\Logger.ps1"
        Write-Log -Message "WinKit starting from: $WK_ROOT" -Level "INFO"
        
        . "$WK_ROOT\core\Security.ps1"
        . "$WK_ROOT\core\Utils.ps1"
        . "$WK_ROOT\core\Interface.ps1"
        
        # Load UI modules
        . "$WK_ROOT\ui\Theme.ps1"
        . "$WK_ROOT\ui\UI.ps1"
        
        # Verify admin privileges
        Test-WKAdmin
        
        # Load menu and start
        . "$WK_ROOT\Menu.ps1"
        
        Write-Log -Message "All modules loaded successfully" -Level "INFO"
        Write-Log -Message "System initialized, starting UI" -Level "INFO"
        
        Initialize-UI
        Show-MainMenu
    }
    catch {
        # Try to log error if logger is available
        try { Write-Log -Message "Startup failed: $_" -Level "ERROR" } catch {}
        
        Write-Host "`nFatal Error: $_" -ForegroundColor Red
        Write-Host "`nPress Enter to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}
