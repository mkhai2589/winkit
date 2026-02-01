# ===============================
# WinKit Entry Point
# ===============================

Set-ExecutionPolicy Bypass -Scope Process -Force

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load core
. "$Root\core\Utils.ps1"
. "$Root\core\Security.ps1"
. "$Root\core\Environment.ps1"
. "$Root\core\Loader.ps1"
. "$Root\core\Menu.ps1"

# Load UI
. "$Root\ui\Theme.ps1"
. "$Root\ui\Header.ps1"
. "$Root\ui\Footer.ps1"
. "$Root\ui\Dashboard.ps1"

Initialize-Security
Initialize-Environment
Load-WinKitModules

Start-WinKit
