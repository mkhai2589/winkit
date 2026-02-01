function Start-WinKit {
    try {
        # SET GLOBAL PATHS FIRST
        $global:WK_ROOT = $PSScriptRoot
        $global:WK_FEATURES = Join-Path $WK_ROOT "features"
        $global:WK_LOG = Join-Path $env:TEMP "winkit.log"
        
        # CLEAR OLD LOG ON NEW START
        if (Test-Path $global:WK_LOG) {
            Remove-Item $global:WK_LOG -Force -ErrorAction SilentlyContinue
        }
        
        # LOAD CORE MODULES IN CORRECT ORDER
        . "$WK_ROOT\core\Logger.ps1"
        Write-Log -Message "WinKit starting from: $WK_ROOT" -Level "INFO"
        
        . "$WK_ROOT\core\Security.ps1"
        . "$WK_ROOT\core\Utils.ps1"
        . "$WK_ROOT\core\Interface.ps1"
        
        # LOAD UI MODULES
        . "$WK_ROOT\ui\Theme.ps1"
        . "$WK_ROOT\ui\UI.ps1"
        
        # LOAD MENU
        . "$WK_ROOT\Menu.ps1"
        
        # VALIDATE ADMINISTRATOR PRIVILEGES
        Test-WKAdmin
        
        Write-Log -Message "All modules loaded successfully" -Level "INFO"
        
        # START USER INTERFACE
        Initialize-UI
        Show-MainMenu
        
    }
    catch {
        Write-Host "`nFATAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPress Enter to exit..." -ForegroundColor Yellow
        $null = Read-Host
        exit 1
    }
}
