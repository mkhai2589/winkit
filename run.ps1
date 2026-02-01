Set-ExecutionPolicy Bypass -Scope Process -Force

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$root\core\Loader.ps1"
. "$root\core\Menu.ps1"

Load-WinKitModules

while ($true) {
    Clear-Host
    Write-Host "===== WinKit Toolbox =====" -ForegroundColor Cyan
    Show-WinKitMenu
    Invoke-WinKitSelection
}
