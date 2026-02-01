function Pause {
    Write-Host ""
    Write-Host "Press ENTER to continue..." -ForegroundColor DarkGray
    [void][System.Console]::ReadLine()
}

function Confirm-Action($Message) {
    Write-Host "$Message (Y/N): " -NoNewline -ForegroundColor Yellow
    return ((Read-Host).ToUpper() -eq "Y")
}

function Write-Info($msg) {
    Write-Host "[*] $msg" -ForegroundColor Cyan
}

function Write-Warn($msg) {
    Write-Host "[!] $msg" -ForegroundColor Yellow
}

function Write-ErrorMsg($msg) {
    Write-Host "[X] $msg" -ForegroundColor Red
}
