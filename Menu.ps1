# Menu.ps1
# WinKit Menu Generator - READ REGISTRY ONLY, No Business Logic
# KHÔNG Export-ModuleMember - dot-source only

function Start-Menu {
    [CmdletBinding()]
    param()
    
    Write-Log -Level INFO -Message "Starting main menu loop" -Silent $true
    
    $exitRequested = $false
    
    while (-not $exitRequested) {
        try {
            # Build dynamic menu layout từ registry
            $menuLayout = Build-MenuLayout
            
            # Chuyển đổi layout thành data cho UI
            $menuData = ConvertTo-MenuData -MenuLayout $menuLayout
            
            # Get exit number từ menu data
            $exitNumber = $menuData.ExitNumber
            
            # Show full interface (truyền data)
            Show-Header -WithStatus
            Show-Menu -MenuData $menuData
            
            # Show status bar với feature count
            $featureCount = (Get-AllFeatures).Count
            Show-StatusBar -Message "READY | Features: $featureCount" -Type info
            
            # Get user selection
            $selection = Show-Prompt -Message "TYPE OPTION" -Default $exitNumber
            
            # Handle selection
            if ($selection -eq $exitNumber) {
                # Exit
                Write-Log -Level INFO -Message "User selected Exit (option $exitNumber)" -Silent $true
                $exitRequested = $true
                continue
            }
            elseif ($menuLayout.ContainsKey([int]$selection)) {
                # Execute feature
                $selectedFeature = $menuLayout[[int]$selection]
                Write-Log -Level INFO -Message "User selected feature: $($selectedFeature.Id) (option $selection)" -Silent $true
                
                # Check feature requirements
                $requirement = @{
                    Id = $selectedFeature.Id
                    RequireAdmin = $selectedFeature.RequireAdmin
                    OnlineOnly = $selectedFeature.OnlineOnly
                }
                
                if (-not (Assert-Requirement -Requirement $requirement -ExitOnFail $false)) {
                    Show-StatusBar -Message "FEATURE REQUIREMENTS NOT MET: $($selectedFeature.Title)" -Type warning
                    Start-Sleep -Seconds 3
                    continue
                }
                
                # Execute feature wrapper
                Invoke-FeatureWrapper -Feature $selectedFeature
            }
            else {
                # Invalid selection
                Write-Log -Level WARN -Message "Invalid selection: $selection (valid: 1-$exitNumber)" -Silent $true
                Show-StatusBar -Message "INVALID OPTION: $selection" -Type warning
                Start-Sleep -Seconds 2
            }
        }
        catch {
            Write-Log -Level ERROR -Message "Menu loop error: $_" -Silent $true
            Show-StatusBar -Message "ERROR: $($_.Exception.Message)" -Type error
            Start-Sleep -Seconds 3
        }
    }
    
    # Clean exit
    Write-Log -Level INFO -Message "Exiting WinKit" -Silent $true
    Show-ExitScreen
}

function Build-MenuLayout {
    [CmdletBinding()]
    param()
    
    Write-Log -Level DEBUG -Message "Building menu layout from registry" -Silent $true
    
    $menuLayout = @{}
    $menuNumber = 1  # Bắt đầu từ 1
    
    # Lấy tất cả categories đã sort
    $categories = Get-FeatureCategories | Sort-Object
    
    foreach ($category in $categories) {
        # Lấy features trong category, sort theo Order
        $features = Get-FeaturesByCategory -Category $category | 
                    Sort-Object -Property Order
        
        foreach ($feature in $features) {
            # Chỉ thêm feature đã enable (nếu có property Enabled)
            if ((-not $feature.Enabled) -or ($feature.Enabled -eq $true)) {
                $menuLayout[$menuNumber] = $feature
                $menuNumber++
            } else {
                Write-Log -Level DEBUG -Message "Skipping disabled feature: $($feature.Id)" -Silent $true
            }
        }
    }
    
    # Thêm Exit là item cuối cùng
    $menuLayout[$menuNumber] = [PSCustomObject]@{
        Id = "Exit"
        Title = "Exit"
        Description = "Exit WinKit"
        IsExit = $true
    }
    
    $exitNumber = $menuNumber
    
    Write-Log -Level INFO -Message "Menu layout built with $($menuLayout.Count) items (Exit = $exitNumber)" -Silent $true
    return $menuLayout
}

function ConvertTo-MenuData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$MenuLayout
    )
    
    # Tạo structure cho UI render
    $categories = Get-FeatureCategories | Sort-Object
    $itemsByCategory = @{}
    
    # Khởi tạo categories
    foreach ($category in $categories) {
        $itemsByCategory[$category] = @()
    }
    
    # Phân loại feature vào từng category (bỏ Exit)
    foreach ($menuNumber in $MenuLayout.Keys | Sort-Object) {
        $item = $MenuLayout[$menuNumber]
        
        if (-not $item.IsExit) {
            $category = $item.Category
            if ($itemsByCategory.ContainsKey($category)) {
                $itemsByCategory[$category] += @{
                    MenuNumber = $menuNumber
                    Title = $item.Title
                    Id = $item.Id
                    Description = $item.Description
                }
            }
        }
    }
    
    # Xác định exit number (số lớn nhất)
    $exitNumber = ($MenuLayout.Keys | Measure-Object -Maximum).Maximum
    
    $menuData = @{
        Categories = $categories
        ItemsByCategory = $itemsByCategory
        ExitNumber = $exitNumber
    }
    
    Write-Log -Level DEBUG -Message "Converted menu layout to UI data" -Silent $true
    return $menuData
}

function Invoke-FeatureWrapper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSObject]$Feature
    )
    
    try {
        # Clear screen and show processing message
        Clear-ScreenSafe
        Show-Logo -Centered
        Write-Host ""
        Write-Separator
        Write-Host ""
        
        Write-Colored "EXECUTING: $($Feature.Title)" -Style Section -Center
        Write-Colored "Description: $($Feature.Description)" -Style Status -Center
        
        Write-Host ""
        Write-Separator
        Write-Host ""
        
        Write-Colored "Processing..." -Style Status -Center
        
        # Execute the feature
        $startTime = Get-Date
        $result = Invoke-Feature -Id $Feature.Id
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        # Show result
        Clear-ScreenSafe
        Show-Logo -Centered
        Write-Host ""
        Write-Separator
        Write-Host ""
        
        if ($result -eq $true) {
            Write-Colored "✓ COMPLETED: $($Feature.Title)" -Style Success -Center
            Write-Colored "Execution time: $($duration.TotalSeconds.ToString('0.00')) seconds" -Style Status -Center
            Show-StatusBar -Message "SUCCESS: $($Feature.Title) completed" -Type success
        }
        elseif ($result -eq $false) {
            Write-Colored "✗ FAILED: $($Feature.Title)" -Style Error -Center
            Write-Colored "Check log file for details" -Style Status -Center
            Show-StatusBar -Message "FAILED: $($Feature.Title)" -Type error
        }
        else {
            Write-Colored "↷ RETURNED: $($Feature.Title)" -Style Warning -Center
            Write-Colored "Result: $result" -Style Status -Center
            Write-Colored "Execution time: $($duration.TotalSeconds.ToString('0.00')) seconds" -Style Status -Center
            Show-StatusBar -Message "COMPLETED: $($Feature.Title) with custom result" -Type info
        }
        
        Write-Host ""
        Write-Colored "Press any key to return to menu..." -Style Prompt -Center
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
    }
    catch {
        Write-Log -Level ERROR -Message "Feature wrapper error for $($Feature.Id): $_" -Silent $true
        
        Clear-ScreenSafe
        Show-Logo -Centered
        Write-Host ""
        Write-Separator
        Write-Host ""
        
        Write-Colored "ERROR: $($Feature.Title)" -Style Error -Center
        Write-Colored "Details: $($_.Exception.Message)" -Style Status -Center
        Write-Colored "Check log file for complete error information" -Style Status -Center
        
        Write-Host ""
        Write-Colored "Press any key to return to menu..." -Style Prompt -Center
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Show-ExitScreen {
    [CmdletBinding()]
    param()
    
    Clear-ScreenSafe
    Show-Logo -Centered
    Write-Host ""
    Write-Separator
    Write-Host ""
    
    Write-Colored "Thank you for using WinKit!" -Style Section -Center
    Write-Host ""
    
    # Show log path
    $logPath = Get-LogPath
    if ($logPath -and (Test-Path $logPath)) {
        $fileInfo = Get-Item $logPath
        $sizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
        Write-Colored "Log file: $logPath ($sizeKB KB)" -Style Status -Center
    }
    
    Write-Host ""
    Write-Colored "Closing in 3 seconds..." -Style Prompt -Center
    
    Start-Sleep -Seconds 3
    Clear-Host
}

# ============================================
# KHÔNG Export-ModuleMember - dot-source only
# ============================================
