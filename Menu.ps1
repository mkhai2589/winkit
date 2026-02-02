function Show-MainMenu {
    while ($true) {
        try {
            Clear-Host
            Show-Header
            Show-SystemInfoBar
            
            # Lấy danh sách feature đã tự đăng ký
            $allFeatures = Get-AllFeatures
            
            if ($allFeatures.Count -eq 0) {
                Write-Padded "No features available. Please check feature files." -Color Red
                Write-Padded ""  # Empty line
                Write-Padded "Press any key to exit..." -NoNewline -Color DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                exit 1
            }
            
            # Hiển thị menu theo kiến trúc: Essential/Advanced 2 cột, Tools full width
            Render-MenuByArchitecture
            
            # FOOTER với status
            Show-Footer -Status "READY"
            
            # XỬ LÝ INPUT - Menu chỉ gọi hàm, không chứa logic feature
            Handle-UserInput -Features $allFeatures
            
        }
        catch {
            Write-Padded "Menu Error: $_" -Color Red
            Write-Padded "Returning to menu in 3 seconds..." -Color Yellow
            Start-Sleep -Seconds 3
        }
    }
}

function Render-MenuByArchitecture {
    # 1. Essential (Left) và Advanced (Right) - 2 cột
    $essentialFeatures = Get-FeaturesByCategory -Category "Essential"
    $advancedFeatures = Get-FeaturesByCategory -Category "Advanced"
    
    Write-Padded ""  # Empty line before menu
    
    # Calculate max rows needed
    $maxRows = [math]::Max($essentialFeatures.Count, $advancedFeatures.Count)
    
    if ($maxRows -gt 0) {
        # Display section headers
        $essentialHeader = "[ Essential ]"
        $advancedHeader = "[ Advanced ]"
        
        # Calculate padding để canh 2 cột
        $colWidth = 38
        $leftPadding = $colWidth - $essentialHeader.Length
        $headerLine = $essentialHeader + (" " * $leftPadding) + $advancedHeader
        
        Write-Padded $headerLine -Color Green
        Write-Padded ""  # Empty line
        
        # Display features in parallel columns
        for ($i = 0; $i -lt $maxRows; $i++) {
            $line = "  "  # Indentation
            
            # Essential column
            if ($i -lt $essentialFeatures.Count) {
                $feature1 = $essentialFeatures[$i]
                $col1 = "[$($feature1.Order)] $($feature1.Title)"
                $line += $col1.PadRight($colWidth)
            } else {
                $line += "".PadRight($colWidth)
            }
            
            # Advanced column
            if ($i -lt $advancedFeatures.Count) {
                $feature2 = $advancedFeatures[$i]
                $col2 = "[$($feature2.Order)] $($feature2.Title)"
                $line += $col2
            }
            
            Write-Padded $line -Color White
        }
        
        Write-Padded ""  # Empty line
        Write-Separator
    }
    
    # 2. Tools category (full width)
    $toolsFeatures = Get-FeaturesByCategory -Category "Tools"
    
    if ($toolsFeatures.Count -gt 0) {
        Write-Section -Text "Tools" -Color "Cyan"
        
        foreach ($feature in $toolsFeatures) {
            Write-Padded "  [$($feature.Order)] $($feature.Title)" -Color White
        }
        
        Write-Padded ""  # Empty line
        Write-Separator
    }
    
    # 3. Exit option
    Write-Padded "  [0] Exit" -Color Gray
    Write-Padded ""  # Empty line
    Write-Separator
}

function Handle-UserInput {
    param([array]$Features)
    
    $maxOrder = if ($Features.Count -gt 0) { 
        ($Features | Measure-Object -Property Order -Maximum).Maximum 
    } else { 0 }
    
    # Hiển thị prompt đúng format
    $promptText = "Select an option [0-$maxOrder]: "
    Write-Padded $promptText -NoNewline -Color Yellow
    
    $choice = Read-Host
    
    if ($choice -eq "0") {
        Write-Host ""
        Write-Padded "Exiting WinKit. Goodbye!" -Color Cyan
        exit 0
    }
    
    # Validate input
    if (-not ($choice -match '^\d+$')) {
        Write-Padded "Invalid input! Please enter a number." -Color Red
        Pause
        return
    }
    
    $selectedFeature = Get-FeatureByOrder -Order ([int]$choice)
    
    if (-not $selectedFeature) {
        Write-Padded "Option $choice not available!" -Color Red
        Pause
        return
    }
    
    # Execute feature thông qua Interface
    Execute-Feature -Feature $selectedFeature
}

function Execute-Feature([PSCustomObject]$Feature) {
    try {
        Clear-Host
        
        # Feature header với border đúng chiều rộng
        $titleLine = "═══ $($Feature.Title) "
        $remainingWidth = $global:WK_MENU_WIDTH - $titleLine.Length
        $borderLine = $titleLine + ("═" * [math]::Max(0, $remainingWidth))
        
        Write-Padded $borderLine -Color Cyan -IndentLevel 0
        Write-Padded ""  # Empty line
        
        if ($Feature.Description) {
            Write-Padded "  Description: $($Feature.Description)" -Color Gray
            Write-Padded ""  # Empty line
        }
        
        Write-Padded "  Category: $($Feature.Category)" -Color Gray
        Write-Padded "  File: $($Feature.FileName)" -Color Gray
        Write-Padded ""  # Empty line
        
        # Update footer status
        Show-Footer -Status "RUNNING: $($Feature.Title)"
        Write-Padded ""  # Empty line
        
        # Execute feature thông qua Interface
        Write-Padded "Starting execution..." -Color Yellow
        Write-Padded ""  # Empty line
        
        Invoke-Feature -FeatureId $Feature.Id
        
        Write-Padded ""  # Empty line
        Write-Padded "Feature completed successfully!" -Color Green
        
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Message "Feature executed: $($Feature.Id)" -Level "INFO"
        }
    }
    catch {
        Write-Padded "Feature Error: $_" -Color Red
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Message "Feature failed: $($Feature.Id) - $_" -Level "ERROR"
        }
    }
    finally {
        Write-Host ""
        Write-Padded "─" * $global:WK_MENU_WIDTH -Color DarkGray
        Write-Padded "Press any key to return to menu..." -NoNewline -Color DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Show-Footer([string]$Status = "READY") {
    # Determine color based on status
    $statusColor = switch -Wildcard ($Status) {
        "*READY*" { $global:WK_THEME.Ready }
        "*RUNNING*" { $global:WK_THEME.Running }
        "*ERROR*" { $global:WK_THEME.ErrorStatus }
        default { "Cyan" }
    }
    
    Write-Padded ""  # Empty line
    Write-Padded ("─" * $global:WK_MENU_WIDTH) -Color DarkGray
    Write-Padded "Status: " -Color White -NoNewLine
    Write-Host $Status -ForegroundColor $statusColor -NoNewline
    Write-Host " | Log: $global:WK_LOG" -ForegroundColor Gray
}

function Pause {
    param([string]$Message = "Press any key to continue...")
    Write-Host ""
    Write-Padded $Message -NoNewline -Color DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
