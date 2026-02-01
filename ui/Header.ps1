function Show-Header {
    Clear-Host
    Write-Host "========================================" -ForegroundColor DarkGray
    Write-Host " WinKit Toolbox" -ForegroundColor Cyan
    Write-Host " OS: $($Global:WinKitEnv.OSName) | Build: $($Global:WinKitEnv.Build)" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor DarkGray
}
