# ==========================================
# WinKit Loader Module
# Bootstraps and loads all system components
# ==========================================

function Start-WinKit {
    try {
        # Set global paths
        $global:WK_ROOT = Split-Path $MyInvocation.MyCommand.Path
        $global:WK_FEATURES = Join-Path $WK_ROOT "features"
        $global:WK_LOG = Join-Path $env:TEMP "winkit.log"
        
        # **LOAD LOGGER FIRST**
        . "$WK_ROOT\core\Logger.ps1"
        # Now Write-Log is available
        Write-Log -Message "WinKit started" -Level "INFO"
        Write-Log -Message "Loading core modules" -Level "DEBUG"
        
        # Load remaining core modules
        . "$WK_ROOT\core\Security.ps1"
        . "$WK_ROOT\core\Utils.ps1"
        . "$WK_ROOT\core\Interface.ps1"
        
        # Load UI modules
        Write-Log -Message "Loading UI modules" -Level "DEBUG"
        . "$WK_ROOT\ui\Theme.ps1"
        . "$WK_ROOT\ui\UI.ps1"
        
        # Load Menu
        Write-Log -Message "Loading menu module" -Level "DEBUG"
        . "$WK_ROOT\Menu.ps1"
        
        # Validate administrative privileges
        Write-Log -Message "Checking admin privileges" -Level "DEBUG"
        Test-WKAdmin
        
        # Initialize UI and show main menu
        Write-Log -Message "Starting UI" -Level "INFO"
        Initialize-UI
        Show-MainMenu
    }
    catch {
        Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nWinKit cannot start. Press Enter to exit..." -ForegroundColor Yellow
        [Console]::ReadKey($true) | Out-Null
        exit 1
    }
}
