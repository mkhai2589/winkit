# Menu.ps1
# WinKit Menu Generator - READ REGISTRY ONLY, No Business Logic

function Start-Menu {
    [CmdletBinding()]
    param()
    
    Write-Log -Level INFO -Message "Starting main menu loop" -Silent $true
    
    $exitRequested = $false
    
    while (-not $exitRequested) {
        try {
            # Show full interface
            Show-Header -WithStatus
            Show-Menu
            
            # Get user selection
            $selection = Show-Prompt -Message "TYPE OPTION" -Default "0"
            
            # Handle selection
            switch ($selection) {
                "0" {
                    # Exit
                    Write-Log -Level INFO -Message "User selected Exit" -Silent $true
                    $exitRequested = $true
                    break
                }
                default {
                    # Find feature by order number
                    $allFeatures = Get-AllFeatures
                    $selectedFeature = $allFeatures | Where-Object { $_.Order -eq [int]$selection }
                    
                    if ($selectedFeature) {
                        # Execute feature
                        Write-Log -Level INFO -Message "User selected feature: $($selectedFeature.Id)" -Silent $true
                        Invoke-FeatureWrapper -Feature $selectedFeature
                    }
                    else {
                        # Invalid selection
                        Write-Log -Level WARN -Message "Invalid selection: $selection" -Silent $true
                        Show-StatusBar -Message "INVALID OPTION: $selection" -Type warning
                        Start-Sleep -Seconds 2
                    }
                }
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
            Write-Colored "✓ COMPLETED: $($Feature.Title)" -Style Section -Center
            Write-Colored "Execution time: $($duration.TotalSeconds.ToString('0.00')) seconds" -Style Status -Center
            Show-StatusBar -Message "SUCCESS: $($Feature.Title) completed" -Type success
        }
        else {
            Write-Colored "✗ FAILED: $($Feature.Title)" -Style Error -Center
            Write-Colored "Check log file for details" -Style Status -Center
            Show-StatusBar -Message "FAILED: $($Feature.Title)" -Type error
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
    Write-Colored "Log file: $(Get-LogPath)" -Style Status -Center
    Write-Host ""
    Write-Colored "Closing in 3 seconds..." -Style Prompt -Center
    
    Start-Sleep -Seconds 3
    Clear-Host
}

function Get-MenuLayout {
    [CmdletBinding()]
    param()
    
    # This function demonstrates the data-driven nature of the menu
    # It only reads from registry and returns structured data
    
    $categories = Get-FeatureCategories
    $layout = @{}
    
    foreach ($category in $categories) {
        $features = Get-FeaturesByCategory -Category $category | Sort-Object Order
        $layout[$category] = @{
            Count = $features.Count
            Features = $features | ForEach-Object {
                @{
                    Order = $_.Order
                    Title = $_.Title
                    Id = $_.Id
                }
            }
        }
    }
    
    return $layout
}

# Export functions
$ExportFunctions = @(
    'Start-Menu',
    'Get-MenuLayout',
    'Show-ExitScreen'
)

Export-ModuleMember -Function $ExportFunctions
