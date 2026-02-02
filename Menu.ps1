function Show-MainMenu {
    while ($true) {
        try {
            Clear-Host
            Show-Header
            Show-SystemInfoBar
            
            # LOAD CONFIGURATION - DATA-DRIVEN
            $configPath = Join-Path $global:WK_ROOT "config.json"
            if (-not (Test-Path $configPath)) {
                throw "Configuration file not found at: $configPath"
            }
            
            $config = Read-Json -Path $configPath
            
            # GET AVAILABLE FEATURES (Self-registration)
            $availableFeatures = @()
            
            # Create a copy of features array
            $featuresCopy = @($config.features)
            
            foreach ($feature in $featuresCopy) {
                $featurePath = Join-Path $global:WK_FEATURES $feature.file
                if (Test-Path $featurePath) {
                    # Feature tự đăng ký: kiểm tra file tồn tại
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
            
            # SORT FEATURES IN EACH CATEGORY by order from config
            $categoryKeys = @($categories.Keys)
            foreach ($category in $categoryKeys) {
                $sortedFeatures = $categories[$category] | Sort-Object order
                $categories[$category] = @($sortedFeatures)
            }
            
            # DISPLAY CATEGORIES IN SPECIFIED ORDER
            if ($config.ui -and $config.ui.categoryOrder) {
                $categoryOrder = $config.ui.categoryOrder
            } else {
                # Default order
                $categoryOrder = @("Essential", "Advanced", "Tools")
            }
            
            # DISPLAY DUAL COLUMN LAYOUT
            Write-Padded ""  # Empty line before menu
            
            # Essential (Left) and Advanced (Right) side by side
            $essentialFeatures = if ($categories.ContainsKey("Essential")) { $categories["Essential"] } else { @() }
            $advancedFeatures = if ($categories.ContainsKey("Advanced")) { $categories["Advanced"] } else { @() }
            
            if ($essentialFeatures.Count -gt 0 -or $advancedFeatures.Count -gt 0) {
                # Calculate max rows needed
                $maxRows = [math]::Max($essentialFeatures.Count, $advancedFeatures.Count)
                
                # Display section headers side by side
                $essentialHeader = "[ Essential ]"
                $advancedHeader = "[ Advanced ]"
                
                # Calculate padding for headers
                $headerPadding = $global:WK_COLUMN_WIDTH - $essentialHeader.Length
                $headerLine = $essentialHeader + (" " * $headerPadding) + $advancedHeader
                
                Write-Padded $headerLine -Color Green
                Write-Padded ""  # Empty line
                
                # Display features in parallel columns
                for ($i = 0; $i -lt $maxRows; $i++) {
                    $line = ""
                    
                    # Essential column
                    if ($i -lt $essentialFeatures.Count) {
                        $feature1 = $essentialFeatures[$i]
                        $col1 = " [$($feature1.order)] $($feature1.title)"
                        $line += $col1.PadRight($global:WK_COLUMN_WIDTH)
                    } else {
                        $line += "".PadRight($global:WK_COLUMN_WIDTH)
                    }
                    
                    # Advanced column
                    if ($i -lt $advancedFeatures.Count) {
                        $feature2 = $advancedFeatures[$i]
                        $col2 = " [$($feature2.order)] $($feature2.title)"
                        $line += $col2
                    }
                    
                    Write-Padded $line -Color White
                }
                
                Write-Padded ""  # Empty line
                Write-Separator
            }
            
            # Tools category (full width)
            if ($categories.ContainsKey("Tools") -and $categories["Tools"].Count -gt 0) {
                Write-Section -Text "Tools" -Color "Cyan"
                
                $toolsFeatures = $categories["Tools"]
                foreach ($feature in $toolsFeatures) {
                    Write-Padded " [$($feature.order)] $($feature.title)" -Color White
                }
                
                Write-Padded ""  # Empty line
                Write-Separator
            }
            
            # EXIT OPTION
            Write-Padded " [0] Exit" -Color Gray
            Write-Padded ""  # Empty line
            Write-Separator
            
            # FOOTER with improved status
            Show-Footer -Status "READY"
            
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
            Show-Footer -Status "RUNNING: $($Feature.title)"
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

function Show-Footer([string]$Status = "READY") {
    # Determine color based on status
    $statusColor = switch -Wildcard ($Status) {
        "*READY*" { "Green" }
        "*RUNNING*" { "Yellow" }
        "*ERROR*" { "Red" }
        default { "Cyan" }
    }
    
    Write-Padded ""  # Empty line
    Write-Padded "─" * $global:WK_MENU_WIDTH -Color DarkGray
    Write-Padded "Status: " -Color White -NoNewLine
    Write-Host $Status -ForegroundColor $statusColor -NoNewline
    Write-Host " | Log: $global:WK_LOG" -ForegroundColor Gray
    Write-Padded ""  # Empty line
}

function Pause {
    param([string]$Message = "Press any key to continue...")
    Write-Host ""
    Write-Padded $Message -NoNewline -Color DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
