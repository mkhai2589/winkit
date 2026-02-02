function Show-MainMenu {
    while ($true) {
        try {
            Clear-Host
            Show-Header
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
            
            Write-Padded ""  # Empty line before menu
            
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
                    
                    # Category header
                    Write-Padded "[ $category ]" -Color $categoryColor
                    Write-Padded ""  # Empty line
                    
                    # Create copy of features in this category
                    $categoryFeatures = @($categories[$category])
                    
                    # Display features in 2 columns
                    for ($i = 0; $i -lt $categoryFeatures.Count; $i += 2) {
                        $line = ""
                        
                        # First column
                        if ($i -lt $categoryFeatures.Count) {
                            $feature1 = $categoryFeatures[$i]
                            $dangerIcon1 = switch ($feature1.dangerLevel) {
                                "High" { " (!)" }
                                "Medium" { " (?)" }
                                default { "" }
                            }
                            $col1 = " [$($feature1.order)]$dangerIcon1 $($feature1.title)"
                            $line += $col1.PadRight($global:WK_COLUMN_WIDTH)
                        }
                        
                        # Second column
                        if ($i + 1 -lt $categoryFeatures.Count) {
                            $feature2 = $categoryFeatures[$i + 1]
                            $dangerIcon2 = switch ($feature2.dangerLevel) {
                                "High" { " (!)" }
                                "Medium" { " (?)" }
                                default { "" }
                            }
                            $col2 = " [$($feature2.order)]$dangerIcon2 $($feature2.title)"
                            $line += $col2
                        }
                        
                        Write-Padded $line -Color White
                    }
                    
                    Write-Padded ""  # Empty line between categories
                }
            }
            
            # EXIT OPTION
            Write-Padded "------------------------------------------" -Color DarkGray
            Write-Padded " [0] Exit" -Color Gray
            Write-Padded ""  # Empty line
            
            # FOOTER
            Show-Footer -Status "Ready"
            
            # USER INPUT
            if ($availableFeatures.Count -gt 0) {
                $maxOption = ($availableFeatures | Measure-Object -Property order -Maximum).Maximum
                Write-Padded "Select an option [0-$maxOption]: " -NoNewline -Color Yellow
            } else {
                Write-Padded "No features available. Select [0] to exit: " -NoNewline -Color Yellow
            }
            
            $choice = Read-Host
            
            if ($choice -eq "0") {
                Write-Host ""
                Write-Padded "Exiting WinKit. Goodbye!" -Color Cyan
                exit 0
            }
            
            if (-not ($choice -match '^\d+$')) {
                Write-Host ""
                Write-Padded "Invalid input! Please enter a number." -Color Red
                Pause
                continue
            }
            
            $selectedFeature = $availableFeatures | Where-Object { $_.order -eq [int]$choice }
            
            if (-not $selectedFeature) {
                Write-Host ""
                Write-Padded "Option $choice not available!" -Color Red
                Pause
                continue
            }
            
            Execute-Feature -Feature $selectedFeature
            
        }
        catch {
            Write-Host ""
            Write-Padded "Menu Error: $_" -Color Red
            Write-Padded "Returning to menu in 3 seconds..." -Color Yellow
            Start-Sleep -Seconds 3
        }
    }
}

function Execute-Feature([PSCustomObject]$Feature) {
    try {
        Clear-Host
        
        # Feature header with padding
        Write-Padded "=== $($Feature.title) ===" -Color Cyan -IndentLevel 0
        Write-Padded ""  # Empty line
        
        if ($Feature.description) {
            Write-Padded "$($Feature.description)" -Color Gray
            Write-Padded ""  # Empty line
        }
        
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
            Write-Padded ""  # Empty line
            
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
        Write-Host ""
        Write-Padded "Feature Error: $_" -Color Red
        Write-Log -Message "Feature failed: $($Feature.id) - $_" -Level "ERROR"
    }
    finally {
        Write-Host ""
        Write-Padded "Press any key to return to menu..." -NoNewline -Color DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Show-Footer([string]$Status = "Ready") {
    Write-Padded ""  # Empty line
    Write-Padded "------------------------------------------" -Color DarkGray
    Write-Padded "[INFO] $Status | Log: $global:WK_LOG" -Color Cyan
    Write-Padded ""  # Empty line
}
