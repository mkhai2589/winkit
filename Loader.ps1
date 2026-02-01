function Start-WinKit {
    try {
        $global:WK_ROOT = $PSScriptRoot
        $global:WK_FEATURES = Join-Path $WK_ROOT "features"
        $global:WK_LOG = Join-Path $env:TEMP "winkit.log"
        
        Write-Log -Message "WinKit starting from: $WK_ROOT" -Level "INFO"
        
        . "$WK_ROOT\core\Security.ps1"
        . "$WK_ROOT\core\Utils.ps1"
        . "$WK_ROOT\core\Interface.ps1"
        
        . "$WK_ROOT\ui\Theme.ps1"
        . "$WK_ROOT\ui\UI.ps1"
        
        Test-WKAdmin
        
        . "$WK_ROOT\Menu.ps1"
        
        Initialize-UI
        Show-MainMenu
    }
    catch {
        Write-Host "FATAL ERROR: $_" -ForegroundColor Red
        Write-Host "`nPress Enter to exit..." -ForegroundColor Yellow
        $null = Read-Host
        exit 1
    }
}

# Import Logger first
. "$PSScriptRoot\core\Logger.ps1"
