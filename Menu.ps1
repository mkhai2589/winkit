function Show-MainMenu {
    Clear-Host
    Initialize-UI

    try {
        # Build config path and check
        $configPath = Join-Path $WK_ROOT "config.json"
        
        if (-not (Test-Path $configPath)) {
            Write-Host "ERROR: Config file not found at:`n$configPath" -ForegroundColor Red
            Pause
            exit 1
        }

        # Read config
        $config = Read-Json -Path $configPath
        $features = $config.features | Sort-Object order

        # Display menu
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
            Pause
            return Show-MainMenu
        }

        $featurePath = Join-Path $WK_FEATURES $selected.file

        if (-not (Test-Path $featurePath)) {
            Write-Host "Feature file not found: $featurePath" -ForegroundColor Red
            Pause
            return Show-MainMenu
        }

        # Load and execute feature
        . $featurePath
        $functionName = "Start-$($selected.id)"
        
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            & $functionName
        }
        else {
            Write-Host "Feature function not found: $functionName" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error in main menu: $_" -ForegroundColor Red
        Pause
    }
    
    # Return to menu
    Show-MainMenu
}
