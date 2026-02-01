function Show-MainMenu {
    while ($true) {
        try {
            Clear-Host
            Show-Header
            Show-SystemInfoBar
            Show-MainMenuTitle
            
            $config = Read-Json -Path (Join-Path $global:WK_ROOT "config.json")
            $features = $config.features | Sort-Object order
            
            foreach ($feature in $features) {
                Write-Host "  [$($feature.order)]. " -NoNewline -ForegroundColor Green
                Write-Host $feature.title -ForegroundColor White
                
                if ($feature.description) {
                    Write-Host "      $($feature.description)" -ForegroundColor Gray
                }
                
                Write-Host ""
            }
            
            Write-Host "  [0]. " -NoNewline -ForegroundColor Red
            Write-Host "Exit" -ForegroundColor White
            Write-Host ""
            
            Show-Footer -Status "Ready"
            
            Write-Host "Select an option [0-$($features[-1].order)]: " -NoNewline -ForegroundColor Yellow
            $choice = Read-Host
            
            if ($choice -eq "0") {
                Write-Host "Exiting..." -ForegroundColor Cyan
                exit 0
            }
            
            if (-not ($choice -match '^\d+$')) {
                Write-Host "Invalid input! Please enter a number." -ForegroundColor Red
                Pause
                continue
            }
            
            $selected = $features | Where-Object { $_.order -eq [int]$choice }
            
            if (-not $selected) {
                Write-Host "Option $choice not available!" -ForegroundColor Red
                Pause
                continue
            }
            
            Execute-Feature -Feature $selected
        }
        catch {
            Write-Host "Menu Error: $_" -ForegroundColor Red
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
        
        . $featurePath
        
        $functionName = "Start-$($Feature.id)"
        
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            Show-Footer -Status "Running: $($Feature.title)"
            Write-Host ""
            & $functionName
            Write-Log -Message "Feature executed: $($Feature.id)" -Level "INFO"
        }
        else {
            throw "Function $functionName not found"
        }
    }
    catch {
        Write-Host "Feature Error: $_" -ForegroundColor Red
        Write-Log -Message "Feature failed: $($Feature.id) - $_" -Level "ERROR"
    }
    finally {
        Write-Host ""
        Pause -Message "Press any key to return to menu..."
    }
}
