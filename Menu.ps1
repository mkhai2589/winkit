function Show-MainMenu {
    while ($true) {
        try {
            Clear-Host
            Show-Header
            Write-Host ""  # Thêm dòng trống
            Show-SystemInfoBar
            
            # LOAD CONFIGURATION
            $config = Read-Json -Path (Join-Path $global:WK_ROOT "config.json")
            
            # GET AVAILABLE FEATURES
            $availableFeatures = @()
            foreach ($feature in $config.features) {
                $featurePath = Join-Path $global:WK_FEATURES $feature.file
                if (Test-Path $featurePath) {
                    $availableFeatures += $feature
                }
            }
            
            # GROUP FEATURES BY CATEGORY
            $categories = @{}
            foreach ($feature in $availableFeatures) {
                if (-not $categories.ContainsKey($feature.category)) {
                    $categories[$feature.category] = @()
                }
                $categories[$feature.category] += $feature
            }
            
            # SORT FEATURES IN EACH CATEGORY
            foreach ($category in $categories.Keys) {
                $categories[$category] = $categories[$category] | Sort-Object order
            }
            
            # DISPLAY CATEGORIES IN SPECIFIED ORDER
            $categoryOrder = $config.ui.categoryOrder
            foreach ($category in $categoryOrder) {
                if ($categories.ContainsKey($category) -and $categories[$category].Count -gt 0) {
                    $categoryColor = if ($config.ui.categoryColors.$category) { 
                        $config.ui.categoryColors.$category 
                    } else { 
                        $WK_THEME[$category] 
                    }
                    
                    Write-Host ""
                    Write-Host "[ $category ]" -ForegroundColor $categoryColor
                    Write-Host ""
                    
                    foreach ($feature in $categories[$category]) {
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
            $maxOption = ($availableFeatures | Measure-Object -Property order -Maximum).Maximum
            Write-Host "Select an option [0-$maxOption]: " -NoNewline -ForegroundColor Yellow
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
            Pause
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
            & $functionName
            Write-Log -Message "Feature executed: $($Feature.id)" -Level "INFO"
        }
        else {
            throw "Function $functionName not found"
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

function Show-Footer([string]$Status = "Ready") {
    Write-Host ""
    Write-Host "------------------------------------------" -ForegroundColor DarkGray
    Write-Host "[INFO] $Status | Log: $global:WK_LOG" -ForegroundColor Cyan
    Write-Host ""
}
