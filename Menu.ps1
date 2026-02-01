function Show-MainMenu {
    while ($true) {
        try {
            Clear-Host
            Show-Header
            Show-SystemInfoBar
            Show-MainMenuTitle
            
            # Load menu from config.json (data-driven)
            $configPath = Join-Path $global:WK_ROOT "config.json"
            if (-not (Test-Path $configPath)) {
                throw "Configuration file not found at: $configPath"
            }
            
            $config = Read-Json -Path $configPath
            $features = $config.features | Sort-Object order
            
            # Filter only features that have corresponding files
            $availableFeatures = @()
            foreach ($feature in $features) {
                $featurePath = Join-Path $global:WK_FEATURES $feature.file
                if (Test-Path $featurePath) {
                    $availableFeatures += $feature
                }
            }
            
            # Display menu - only number and title (no description)
            foreach ($feature in $availableFeatures) {
                Write-Host "  [$($feature.order)]. " -NoNewline -ForegroundColor Green
                Write-Host $feature.title -ForegroundColor White
                Write-Host ""
            }
            
            Write-Host "  [0]. " -NoNewline -ForegroundColor Red
            Write-Host "Exit" -ForegroundColor White
            Write-Host ""
            
            Show-Footer -Status "Ready"
            
            # Get user input
            Write-Host "Select an option [0-$($availableFeatures[-1].order)]: " -NoNewline -ForegroundColor Yellow
            $choice = Read-Host
            
            if ($choice -eq "0") {
                Write-Host "`nExiting WinKit. Goodbye!" -ForegroundColor Cyan
                exit 0
            }
            
            # Validate input
            if (-not ($choice -match '^\d+$')) {
                Write-Host "`nInvalid input! Please enter a number." -ForegroundColor Red
                Pause
                continue
            }
            
            $selectedFeature = $availableFeatures | Where-Object { $_.order -eq [int]$choice }
            
            if (-not $selectedFeature) {
                Write-Host "`nOption $choice not available!" -ForegroundColor Red
                Pause
                continue
            }
            
            Execute-Feature -Feature $selectedFeature
        }
        catch {
            Write-Host "`nMenu Error: $_" -ForegroundColor Red
            Pause
        }
    }
}

function Execute-Feature {
    param([PSCustomObject]$Feature)
    
    try {
        Clear-Host
        Write-Host "=== $($Feature.title) ===" -ForegroundColor Cyan
        Write-Host ""
        
        $featurePath = Join-Path $global:WK_FEATURES $Feature.file
        
        if (-not (Test-Path $featurePath)) {
            throw "Feature file not found: $featurePath"
        }
        
        # Dynamically load feature
        . $featurePath
        
        $functionName = "Start-$($Feature.id)"
        
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            # Update footer to show running status
            Show-Footer -Status "Running: $($Feature.title)"
            Write-Host ""
            
            # Execute feature
            & $functionName
            
            # Log execution
            Write-Log -Message "Feature executed: $($Feature.id)" -Level "INFO"
        }
        else {
            throw "Feature function '$functionName' not found in $($Feature.file)"
        }
    }
    catch {
        Write-Host "`nFeature Error: $_" -ForegroundColor Red
        Write-Log -Message "Feature failed: $($Feature.id) - $_" -Level "ERROR"
    }
    finally {
        Write-Host ""
        Pause -Message "Press any key to return to menu..."
    }
}
