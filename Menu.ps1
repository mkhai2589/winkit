# ==========================================
# WinKit Main Menu Module
# Data-driven menu system
# ==========================================

function Show-MainMenu {
    while ($true) {
        try {
            Clear-Host
            Initialize-UI
            Show-Header
            
            # Load menu configuration
            $configPath = Join-Path $WK_ROOT "config.json"
            if (-not (Test-Path $configPath)) {
                throw "Configuration file not found at: $configPath"
            }
            
            $config = Read-Json -Path $configPath
            $features = $config.features | Sort-Object order
            
            # Display menu items
            Write-Host "`nMAIN MENU" -ForegroundColor $WK_THEME.Accent
            Write-Host "══════════════════════════════════════════" -ForegroundColor $WK_THEME.Border
            
            foreach ($feature in $features) {
                Write-Host "[$($feature.order)]" -NoNewline -ForegroundColor $WK_THEME.MenuItem
                Write-Host " $($feature.title)" -ForegroundColor $WK_THEME.Primary
                
                if ($feature.description) {
                    Write-Host "    $($feature.description)" -ForegroundColor $WK_THEME.Description
                }
                
                Write-Host ""
            }
            
            Write-Host "[0]" -NoNewline -ForegroundColor $WK_THEME.Error
            Write-Host " Exit" -ForegroundColor $WK_THEME.Primary
            
            Show-Footer
            
            # Get user input
            Write-Host "`nSelect option: " -NoNewline -ForegroundColor $WK_THEME.Accent
            $choice = Read-Host
            
            if ($choice -eq "0") {
                Write-Log -Message "User exited application" -Level "INFO"
                exit 0
            }
            
            # Find selected feature
            $selected = $features | Where-Object { $_.order -eq [int]$choice }
            
            if (-not $selected) {
                Write-Host "`nInvalid selection!" -ForegroundColor $WK_THEME.Error
                Pause
                continue
            }
            
            # Execute selected feature
            Invoke-Feature -Feature $selected
            
        }
        catch {
            Write-Host "`nMenu Error: $_" -ForegroundColor $WK_THEME.Error
            Pause
        }
    }
}

function Invoke-Feature {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Feature
    )
    
    try {
        # Check if feature file exists
        $featurePath = Join-Path $WK_FEATURES $Feature.file
        if (-not (Test-Path $featurePath)) {
            throw "Feature file not found: $featurePath"
        }
        
        # Load feature module
        . $featurePath
        
        # Execute feature function
        $functionName = "Start-$($Feature.id)"
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            Write-Log -Message "Executing feature: $($Feature.id)" -Level "INFO"
            & $functionName
        }
        else {
            throw "Feature function '$functionName' not found"
        }
    }
    catch {
        Write-Host "`nFeature Error: $_" -ForegroundColor $WK_THEME.Error
        Write-Log -Message "Feature execution failed: $_" -Level "ERROR"
    }
    
    # Return to menu
    Write-Host "`n" -NoNewline
    Pause -Message "Return to main menu..."
}
