function Initialize-UI {
    Clear-Host

    $ascii = Join-Path $WK_ROOT "assets\ascii.txt"
    if (Test-Path $ascii) {
        Get-Content $ascii | Write-Host -ForegroundColor $WK_THEME.Title
    }

    Write-Host "WinKit - Windows Optimization Toolkit" -ForegroundColor $WK_THEME.Title
    Write-Host "-------------------------------------"
}

function Show-Footer {
    $version = Read-Json "$WK_ROOT\version.json"
    Write-Host ""
    Write-Host "Version $($version.version) - $($version.channel)" -ForegroundColor $WK_THEME.Info
}
