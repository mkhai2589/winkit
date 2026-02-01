# ==========================================
# WinKit Loader Module
# Bootstraps and loads all system components
# ==========================================

function Start-WinKit {
    try {
        # SET GLOBAL PATHS FIRST
        $global:WK_ROOT = $PSScriptRoot
        $global:WK_FEATURES = Join-Path $WK_ROOT "features"
        $global:WK_LOG = Join-Path $env:TEMP "winkit.log"
        
        # DEBUG: Verify path is set
        Write-Host "[INIT] Root path: $WK_ROOT" -ForegroundColor DarkGray
        
        # LOAD CORE MODULES IN CORRECT ORDER
        # 1. Logger first (so Write-Log is available immediately)
        . "$WK_ROOT\core\Logger.ps1"
        Write-Log -Message "WinKit initialized at: $WK_ROOT" -Level "INFO"
        
        # 2. Load remaining core modules
        Write-Log -Message "Loading core modules..." -Level "DEBUG"
        . "$WK_ROOT\core\Security.ps1"
        . "$WK_ROOT\core\Utils.ps1"
        . "$WK_ROOT\core\Interface.ps1"
        
        # 3. Load UI modules
        Write-Log -Message "Loading UI modules..." -Level "DEBUG"
        . "$WK_ROOT\ui\Theme.ps1"
        . "$WK_ROOT\ui\UI.ps1"
        
        # 4. Load Menu module
        Write-Log -Message "Loading menu module..." -Level "DEBUG"
        . "$WK_ROOT\Menu.ps1"
        
        # VALIDATE AND START
        Write-Log -Message "Checking administrator privileges..." -Level "DEBUG"
        Test-WKAdmin
        
        Write-Log -Message "Starting user interface..." -Level "INFO"
        Initialize-UI
        Show-MainMenu
        
    }
    catch {
        # Try to log the error if logger is available
        try { Write-Log -Message "Fatal startup error: $_" -Level "ERROR" } catch {}
        
        # Show user-friendly error
        Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPress Enter to exit..." -ForegroundColor Yellow
        [Console]::ReadKey($true) | Out-Null
        exit 1
    }
}
