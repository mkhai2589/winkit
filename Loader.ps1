function Start-WinKit {

    $global:WK_ROOT = Split-Path $MyInvocation.MyCommand.Path
    $global:WK_FEATURES = Join-Path $WK_ROOT "features"

    # Core
    . "$WK_ROOT\core\Security.ps1"
    . "$WK_ROOT\core\Utils.ps1"
    . "$WK_ROOT\core\Logger.ps1"

    # UI
    . "$WK_ROOT\ui\Theme.ps1"
    . "$WK_ROOT\ui\UI.ps1"

    # Menu
    . "$WK_ROOT\Menu.ps1"

    Test-WKAdmin
    Initialize-UI
    Show-MainMenu
}
