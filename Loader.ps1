function Start-WinKit {

    $global:WK_ROOT = $PSScriptRoot
    $global:WK_LOG  = Join-Path $env:TEMP "winkit.log"

    . "$WK_ROOT\core\Utils.ps1"
    . "$WK_ROOT\core\Logger.ps1"
    . "$WK_ROOT\core\Security.ps1"
    . "$WK_ROOT\core\Interface.ps1"
    . "$WK_ROOT\core\FeatureRegistry.ps1"

    . "$WK_ROOT\ui\Theme.ps1"
    . "$WK_ROOT\ui\UI.ps1"
    . "$WK_ROOT\ui\Logo.ps1"

    $global:WK_CONFIG = Read-Json "$WK_ROOT\config.json"

    Get-ChildItem "$WK_ROOT\features" -Filter "*.ps1" | ForEach-Object {
        . $_.FullName
    }

    Initialize-UI
    Show-MainMenu
}
