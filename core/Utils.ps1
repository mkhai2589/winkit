function Read-Json($Path) {
    Get-Content $Path -Raw | ConvertFrom-Json
}

function Pause-Return {
    Write-Host ""
    Read-Host "Press Enter to return"
}
