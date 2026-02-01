function Start-WinKit {
    try {
        $global:WK_ROOT = $PSScriptRoot
        $global:WK_FEATURES = Join-Path $WK_ROOT "features"
        
        . "$WK_ROOT\core\Logger.ps1"
        . "$WK_ROOT\core\Security.ps1"
        . "$WK_ROOT\core\Utils.ps1"
        . "$WK_ROOT\core\Interface.ps1"
        
        . "$WK_ROOT\ui\Theme.ps1"
        . "$WK_ROOT\ui\UI.ps1"
        
        Test-WKAdmin
        Write-Log -Message "WinKit started" -Level "INFO"
        
        Initialize-UI
        . "$WK_ROOT\Menu.ps1"
        Show-MainMenu
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        Write-Host "Press Enter to exit..." -ForegroundColor Yellow
        $null = Read-Host
        exit 1
    }
}
