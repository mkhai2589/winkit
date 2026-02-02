function Show-MainMenu {
    while ($true) {
        try {
            Clear-Host
            Show-Header
            Write-Host ""
            Show-SystemInfoBar
            
            # LOAD CONFIGURATION
            $configPath = Join-Path $global:WK_ROOT "config.json"
            if (-not (Test-Path $configPath)) {
                throw "Configuration file not found at: $configPath"
            }
            
            $config = Read-Json -Path $configPath
            
            # GET AVAILABLE FEATURES
            $availableFeatures = @()
            
            # Create a copy of features array to avoid modification during iteration
            $featuresCopy = @($config.features)
            
            foreach ($feature in $featuresCopy) {
                $featurePath = Join-Path $global:WK_FEATURES $feature.file
                if (Test-Path $featurePath) {
                    $availableFeatures += $feature
                }
            }
            
            # GROUP FEATURES BY CATEGORY
            $categories = @{}
            $availableFeaturesCopy = @($availableFeatures)
            
            foreach ($feature in $availableFeaturesCopy) {
                if (-not $categories.ContainsKey($feature.category)) {
                    $categories[$feature.category] = @()
                }
                $categories[$feature.category] += $feature
            }
            
            # SORT FEATURES IN EACH CATEGORY
            $categoryKeys = @($categories.Keys)
            foreach ($category in $categoryKeys) {
                $sortedFeatures = $categories[$category] | Sort-Object order
                $categories[$category] = @($sortedFeatures)
            }
            
            # DISPLAY CATEGORIES IN SPECIFIED ORDER
            if ($config.ui -and $config.ui.categoryOrder) {
                $categoryOrder = $config.ui.categoryOrder
            } else {
                # Default order if not specified
                $categoryOrder = @("Essential", "Advanced", "Tools")
            }
            
            $categoryKeys = @($categories.Keys)
            foreach ($category in $categoryOrder) {
                if ($categoryKeys -contains $category -and $categories[$category].Count -gt 0) {
                    $categoryColor = if ($config.ui -and $config.ui.categoryColors -and $config.ui.categoryColors.$category) { 
                        $config.ui.categoryColors.$category 
                    } else { 
                        if ($WK_THEME -and $WK_THEME[$category]) {
                            $WK_THEME[$category]
                        } else {
                            "White"
                        }
                    }
                    
                    Write-Host ""
                    Write-Host "[ $category ]" -ForegroundColor $categoryColor
                    Write-Host ""
                    
                    # Create copy of features in this category
                    $categoryFeatures = @($categories[$category])
                    foreach ($feature in $categoryFeatures) {
                        $dangerIcon = switch ($feature.dangerLevel) {
                            "High" { " (!)" }
                            "Medium" { " (?)" }
                            default { "" }
                        }
                        
                        Write-Host " [$($feature.order)]$dangerIcon $($feature.title)" -ForegroundColor White
                    }
                }
            }
            
            # EXIT OPTION
            Write-Host ""
            Write-Host "------------------------------------------" -ForegroundColor DarkGray
            Write-Host " [0] Exit" -ForegroundColor Gray
            Write-Host ""
            
            # FOOTER
            Show-Footer -Status "Ready"
            
            # USER INPUT
            if ($availableFeatures.Count -gt 0) {
                $maxOption = ($availableFeatures | Measure-Object -Property order -Maximum).Maximum
                Write-Host "Select an option [0-$maxOption]: " -NoNewline -ForegroundColor Yellow
            } else {
                Write-Host "No features available. Select [0] to exit: " -NoNewline -ForegroundColor Yellow
            }
            
            $choice = Read-Host
            
            if ($choice -eq "0") {
                Write-Host "`nExiting WinKit. Goodbye!" -ForegroundColor Cyan
                exit 0
            }
            
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
            Write-Host "Returning to menu in 3 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }
    }
}

function Execute-Feature([PSCustomObject]$Feature) {
    try {
        Clear-Host
        Write-Host "=== $($Feature.title) ===" -ForegroundColor Cyan
        
        if ($Feature.description) {
            Write-Host "$($Feature.description)" -ForegroundColor Gray
        }
        
        Write-Host ""
        
        # LOAD FEATURE FILE
        $featurePath = Join-Path $global:WK_FEATURES $Feature.file
        
        if (-not (Test-Path $featurePath)) {
            throw "Feature file not found: $featurePath"
        }
        
        . $featurePath
        
        # EXECUTE FEATURE FUNCTION
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
        Pause -Message "Press any key to return to main menu..."
    }
}
