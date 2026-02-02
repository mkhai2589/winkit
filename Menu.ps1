function Show-MainMenu {
    while ($true) {
        try {
            Clear-Host
            Show-Header
            Show-SystemInfoBar
            
            $allFeatures = Get-AllFeatures
            
            if ($allFeatures.Count -eq 0) {
                Write-Padded "No features available. Please check feature files." -Color Red
                Write-Padded ""
                Write-Padded "Press any key to exit..." -NoNewline -Color DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                exit 1
            }
            
            Sort-FeaturesByConfigOrder
            
            Render-MenuByArchitecture
            
            Show-Footer -Status "READY"
            
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
    $categoryOrder = if ($global:WK_CONFIG -and $global:WK_CONFIG.ui -and $global:WK_CONFIG.ui.categoryOrder) {
        $global:WK_CONFIG.ui.categoryOrder
    }
    else {
        @("Essential", "Advanced", "Tools")
    }
    
    Write-Padded ""
    
    $essentialFeatures = Get-FeaturesByCategory -Category "Essential"
    $advancedFeatures = Get-FeaturesByCategory -Category "Advanced"
    
    if ($essentialFeatures.Count -gt 0 -or $advancedFeatures.Count -gt 0) {
        $maxRows = [math]::Max($essentialFeatures.Count, $advancedFeatures.Count)
        
        $essentialHeader = "[ Essential ]"
        $advancedHeader = "[ Advanced ]"
        
        $colWidth = 38
        $leftPadding = $colWidth - $essentialHeader.Length
        $headerLine = $essentialHeader + (" " * $leftPadding) + $advancedHeader
        
        Write-Padded $headerLine -Color Green
        Write-Padded ""
        
        for ($i = 0; $i -lt $maxRows; $i++) {
            $line = "  "
            
            if ($i -lt $essentialFeatures.Count) {
                $feature1 = $essentialFeatures[$i]
                $col1 = "[$($feature1.Order)] $($feature1.Title)"
                $line += $col1.PadRight($colWidth)
            }
            else {
                $line += "".PadRight($colWidth)
            }
            
            if ($i -lt $advancedFeatures.Count) {
                $feature2 = $advancedFeatures[$i]
                $col2 = "[$($feature2.Order)] $($feature2.Title)"
                $line += $col2
            }
            
            Write-Padded $line -Color White
        }
        
        Write-Padded ""
        Write-Separator
    }
    
    $toolsFeatures = Get-FeaturesByCategory -Category "Tools"
    
    if ($toolsFeatures.Count -gt 0) {
        Write-Section -Text "Tools" -Color "Cyan"
        
        foreach ($feature in $toolsFeatures) {
            Write-Padded "  [$($feature.Order)] $($feature.Title)" -Color White
        }
        
        Write-Padded ""
        Write-Separator
    }
    
    Write-Padded "  [0] Exit" -Color Gray
    Write-Padded ""
    Write-Separator
}

function Handle-UserInput {
    param([array]$Features)
    
    $maxOrder = if ($Features.Count -gt 0) { 
        ($Features | Measure-Object -Property Order -Maximum).Maximum 
    }
    else { 0 }
    
    $promptText = "Select an option [0-$maxOrder]: "
    Write-Padded $promptText -NoNewline -Color Yellow
    
    $choice = Read-Host
    
    if ($choice -eq "0") {
        Write-Host ""
        Write-Padded "Exiting WinKit. Goodbye!" -Color Cyan
        exit 0
    }
    
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
    
    Execute-Feature -Feature $selectedFeature
}

function Execute-Feature([PSCustomObject]$Feature) {
    try {
        Clear-Host
        
        $titleLine = "=== $($Feature.Title) "
        $remainingWidth = $global:WK_MENU_WIDTH - $titleLine.Length
        $borderLine = $titleLine + ("=" * [math]::Max(0, $remainingWidth))
        
        Write-Padded $borderLine -Color Cyan -IndentLevel 0
        Write-Padded ""
        
        if ($Feature.Description) {
            Write-Padded "  Description: $($Feature.Description)" -Color Gray
            Write-Padded ""
        }
        
        Write-Padded "  Category: $($Feature.Category)" -Color Gray
        Write-Padded "  File: $($Feature.FileName)" -Color Gray
        Write-Padded "  Source: $($Feature.Source)" -Color Gray
        Write-Padded ""
        
        Show-Footer -Status "RUNNING: $($Feature.Title)"
        Write-Padded ""
        
        Write-Padded "Starting execution..." -Color Yellow
        Write-Padded ""
        
        Invoke-Feature -FeatureId $Feature.Id
        
        Write-Padded ""
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
        Write-Padded ("-" * $global:WK_MENU_WIDTH) -Color DarkGray
        Write-Padded "Press any key to return to menu..." -NoNewline -Color DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Show-Footer([string]$Status = "READY") {
    $statusColor = switch -Wildcard ($Status) {
        "*READY*" { $global:WK_THEME.Ready }
        "*RUNNING*" { $global:WK_THEME.Running }
        "*ERROR*" { $global:WK_THEME.ErrorStatus }
        default { "Cyan" }
    }
    
    Write-Padded ""
    Write-Padded ("-" * $global:WK_MENU_WIDTH) -Color DarkGray
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
