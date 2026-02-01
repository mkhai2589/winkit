function Initialize-UI {
    Clear-Host
    
    # Try to load ASCII art
    $asciiPath = Join-Path $WK_ROOT "assets\ascii.txt"
    if (Test-Path $asciiPath) {
        try {
            Get-Content $asciiPath | Write-Host -ForegroundColor Cyan
        }
        catch {
            # If ASCII fails, just show title
        }
    }
    
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "        WinKit - Windows Toolkit" -ForegroundColor White
    Write-Host "=========================================" -ForegroundColor Cyan
}

function Show-Footer {
    try {
        $versionPath = Join-Path $WK_ROOT "version.json"
        if (Test-Path $versionPath) {
            $version = Get-Content $versionPath -Raw | ConvertFrom-Json
            Write-Host "`nVersion: $($version.version) | $($version.channel)" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host "`nVersion: 1.0.0 | stable" -ForegroundColor DarkGray
    }
}
