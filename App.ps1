# =========================================================
# App.ps1 - WinKit Application Orchestrator (FINAL)
# =========================================================

function Start-WinKit {
    [CmdletBinding()]
    param()
    
    try {
        # ✅ Initialize WinKit (từ core/Interface.ps1 - phải tồn tại)
        Initialize-WinKit -ConfigPath "config.json"
        
        # Initialize UI
        Initialize-UI
        
        # Main application loop
        while ($true) {
            Clear-ScreenSafe
            Show-Header -WithStatus
            
            # Get menu data và hiển thị menu
            $menuData = Get-MenuData
            if (-not $menuData -or $menuData.Categories.Count -eq 0) {
                Write-Colored "No features available" -Style Error -Center
                Start-Sleep -Seconds 3
                break
            }
            
            Show-Menu -MenuData $menuData
            
            # Show status bar
            $featureCount = (Get-AllFeatures).Count
            Show-StatusBar -Message "READY | Features: $featureCount" -Type info
            
            # Get user selection
            $choice = Show-Prompt -Message "SELECT OPTION" -Default $menuData.ExitNumber
            
            # Handle exit
            if ($choice -eq $menuData.ExitNumber) {
                Write-Colored "Exiting WinKit..." -Style Status
                break
            }
            
            # Get feature by number
            $feature = Get-FeatureByNumber -Number ([int]$choice)
            
            if (-not $feature) {
                Write-Colored "Invalid option!" -Style Error
                Start-Sleep -Seconds 1
                continue
            }
            
            # Check requirements
            $requirementResult = Assert-Requirement -Feature $feature -ExitOnFail $false -ReturnMessage
            
            if (-not $requirementResult[0]) {
                Write-Colored "Requirements not met: $($requirementResult[1])" -Style Warning
                Start-Sleep -Seconds 3
                continue
            }
            
            # Execute feature wrapper
            Invoke-FeatureWrapper -Feature $feature
            
            # Pause before returning to menu
            Write-Colored "Press Enter to return to menu..." -Style Prompt
            Read-Host | Out-Null
        }
        
        # Clean exit
        Exit-WinKit
    }
    catch {
        Write-Colored "Fatal error: $($_.Exception.Message)" -Style Error
        Start-Sleep -Seconds 5
    }
}

function Initialize-UI {
    [CmdletBinding()]
    param()
    
    # Load configuration
    $config = $Global:WinKitConfig
    
    # Initialize theme
    $themeName = if ($config.UI.ColorScheme) { $config.UI.ColorScheme } else { "default" }
    Initialize-Theme -ColorScheme $themeName | Out-Null
    
    # Initialize window (if supported)
    try {
        if ($config.Window.ResizeOnStart) {
            Initialize-Window -Width $config.Window.Width -Height $config.Window.Height
        }
    }
    catch {
        # Silent fail if window resize not supported
    }
}

function Get-MenuData {
    [CmdletBinding()]
    param()
    
    try {
        $menuLayout = Build-MenuLayout
        return ConvertTo-MenuData -MenuLayout $menuLayout
    }
    catch {
        return $null
    }
}

function Get-FeatureByNumber {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Number
    )
    
    try {
        # Build mapping từ registry
        $menuNumber = 1
        $categories = Get-FeatureCategories | Sort-Object
        
        foreach ($category in $categories) {
            $features = Get-FeaturesByCategory -Category $category | Sort-Object -Property Order
            
            foreach ($feature in $features) {
                if ((-not $feature.Enabled) -or ($feature.Enabled -eq $true)) {
                    if ($menuNumber -eq $Number) {
                        return $feature
                    }
                    $menuNumber++
                }
            }
        }
        
        return $null
    }
    catch {
        return $null
    }
}

function Exit-WinKit {
    [CmdletBinding()]
    param()
    
    # Show exit screen
    Show-ExitScreen
    
    # Cleanup global states
    $Global:WinKitFeatureRegistry = @()
    $Global:WinKitConfig = @{}
}
