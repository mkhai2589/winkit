function Read-Json {
    param($Path)
    Get-Content $Path -Raw | ConvertFrom-Json
}

function Pause {
    Write-Host ""
    Read-Host "Press Enter to continue"
}
