function Show-MainMenu {

    Clear-Host
    Initialize-UI

    $config = Read-Json "$WK_ROOT\config.json"
    $features = $config.features | Sort-Object order

    foreach ($f in $features) {
        Write-Host "[$($f.order)] $($f.title)" -ForegroundColor $WK_THEME.Menu
    }

    Write-Host "[0] Exit" -ForegroundColor $WK_THEME.Warn
    Show-Footer

    Write-Host ""
    $choice = Read-Host "Select option"

    if ($choice -eq "0") { exit }

    $selected = $features | Where-Object { $_.order -eq [int]$choice }

    if (-not $selected) {
        Write-Host "Invalid selection." -ForegroundColor $WK_THEME.Error
        Pause
        return Show-MainMenu
    }

    $featurePath = Join-Path $WK_FEATURES $selected.file

    if (-not (Test-Path $featurePath)) {
        Write-Host "Feature file not found." -ForegroundColor $WK_THEME.Error
        Pause
        return Show-MainMenu
    }

    . $featurePath
    & "Start-$($selected.id)"

    Pause
    Show-MainMenu
}
