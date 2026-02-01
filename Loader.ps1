# Loader.ps1 - Thêm Interface.ps1
function Start-WinKit {

    $global:WK_ROOT = Split-Path $MyInvocation.MyCommand.Path
    $global:WK_FEATURES = Join-Path $WK_ROOT "features"
    $global:WK_LOG = Join-Path $env:TEMP "winkit.log"

    # Core modules
    . "$WK_ROOT\core\Security.ps1"
    . "$WK_ROOT\core\Utils.ps1"
    . "$WK_ROOT\core\Logger.ps1"
    . "$WK_ROOT\core\Interface.ps1"    # <--- THÊM DÒNG NÀY

    # UI modules
    . "$WK_ROOT\ui\Theme.ps1"
    . "$WK_ROOT\ui\UI.ps1"

    # Menu
    . "$WK_ROOT\Menu.ps1"

    try {
        Test-WKAdmin
        Initialize-UI
        Show-MainMenu
    }
    catch {
        Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPress Enter to exit..."
        [Console]::ReadKey($true)
        exit 1
    }
}
