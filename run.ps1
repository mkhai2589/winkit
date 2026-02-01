# ===============================
# WinKit - Ghost Toolbox UI
# ===============================

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$Root\ui\Dashboard.ps1"

Show-Dashboard
