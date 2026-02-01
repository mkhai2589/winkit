function Show-MainMenu {
    Clear-Host
    Initialize-UI

    $config = Read-Json "$WK_ROOT\config.json"
    $features = $config.features | Sort-Object order

    Write-Host "MAIN MENU" -ForegroundColor Cyan
    Write-Host "-------------------------------------"
    
    foreach ($f in $features) {
        Write-Host "[$($f.order)] $($f.title)" -ForegroundColor Green
    }

    Write-Host "[0] Exit" -ForegroundColor Yellow
    Show-Footer

    Write-Host ""
    $choice = Read-Host "Select option"

    if ($choice -eq "0") { exit }

    $selected = $features | Where-Object { $_.order -eq [int]$choice }

    if (-not $selected) {
        Write-Host "Invalid selection." -ForegroundColor Red
        Write-Host "Press Enter to continue..."
        [Console]::ReadKey($true)
        return Show-MainMenu
    }

    $featurePath = Join-Path $WK_FEATURES $selected.file

    if (-not (Test-Path $featurePath)) {
        Write-Host "Feature file not found." -ForegroundColor Red
        Write-Host "Press Enter to continue..."
        [Console]::ReadKey($true)
        return Show-MainMenu
    }

    try {
        . $featurePath
        & "Start-$($selected.id)"
    }
    catch {
        Write-Host "Error executing feature: $_" -ForegroundColor Red
        Write-Host "Press Enter to continue..."
        [Console]::ReadKey($true)
    }
    
    Show-MainMenu
}
