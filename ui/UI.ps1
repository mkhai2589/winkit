# ui/UI.ps1
# WinKit UI Renderer - Header, Status, Menu (Pure Display, No Logic)

function Show-Header {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$WithStatus
    )
    
    try {
        # Clear screen
        Clear-Host
        
        # Show logo
        Show-Logo -Centered
        
        # Show separator
        Write-Host ""
        Write-Separator
        Write-Host ""
        
        # Show system status if requested
        if ($WithStatus -and $Global:WinKitConfig.UI.ShowStatus) {
            Show-SystemStatus
            Write-Host ""
            Write-Separator
            Write-Host ""
        }
        
        Write-Log -Level DEBUG -Message "Header displayed" -Silent $true
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to show header: $_" -Silent $true
        # Fallback minimal header
        Clear-Host
        Write-Colored "WinKit" -Style Header
        Write-Colored "------" -Style Separator
    }
}

function Show-SystemStatus {
    [CmdletBinding()]
    param()
    
    try {
        # Get system information
        $os = [System.Environment]::OSVersion
        $osVersion = "$($os.Version.Major).$($os.Version.Minior) Build $($os.Version.Build)"
        $osArch = if ([Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
        
        $psVersion = $PSVersionTable.PSVersion.ToString()
        $isAdmin = Test-IsAdmin
        $isOnline = Test-IsOnline
        $currentUser = [System.Environment]::UserName
        $computerName = [System.Environment]::MachineName
        $logPath = Get-LogPath
        
        # Format status lines
        $statusLines = @()
        
        # Line 1: OS and PowerShell
        $statusLines += "OS: Windows $osVersion ($osArch) | PowerShell: $psVersion | Mode: $(if ($isOnline) { 'Online' } else { 'Offline' })"
        
        # Line 2: User and Admin
        $adminStatus = if ($isAdmin) { "Yes" } else { "No" }
        $statusLines += "User: $currentUser | Computer: $computerName | Administrator: $adminStatus"
        
        # Line 3: Log path
        if ($logPath) {
            $shortLogPath = $logPath
            if ($logPath.StartsWith($env:TEMP)) {
                $shortLogPath = "%TEMP%" + $logPath.Substring($env:TEMP.Length)
            }
            $statusLines += "Log: $shortLogPath"
        }
        
        # Display status with proper styling
        Write-Colored "SYSTEM STATUS" -Style Section -Center
        Write-Separator
        
        foreach ($line in $statusLines) {
            Write-Colored $line -Style Status
        }
        
        Write-Separator
        
        Write-Log -Level DEBUG -Message "System status displayed" -Silent $true
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to show system status: $_" -Silent $true
        Write-Colored "SYSTEM STATUS: UNAVAILABLE" -Style Error
    }
}

function Show-Menu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [array]$Features = (Get-AllFeatures)
    )
    
    try {
        if ($Features.Count -eq 0) {
            Write-Colored "No features available." -Style Error
            return
        }
        
        # Group features by category
        $categories = Get-FeatureCategories
        
        foreach ($category in $categories) {
            # Get features in this category
            $categoryFeatures = Get-FeaturesByCategory -Category $category | Sort-Object Order
            
            if ($categoryFeatures.Count -eq 0) {
                continue
            }
            
            # Display category header
            Write-Host ""
            Write-Colored "[ $category ]" -Style Section
            Write-Colored $(Get-SeparatorLine -Length 40) -Style Separator
            Write-Host ""
            
            # Calculate columns
            $featuresPerColumn = [math]::Ceiling($categoryFeatures.Count / 2)
            $leftColumn = $categoryFeatures[0..($featuresPerColumn - 1)]
            $rightColumn = $categoryFeatures[$featuresPerColumn..($categoryFeatures.Count - 1)]
            
            # Determine max item number
            $maxItemNumber = ($categoryFeatures | Measure-Object -Property Order -Maximum).Maximum
            
            # Display in two columns
            for ($i = 0; $i -lt $featuresPerColumn; $i++) {
                $leftItem = if ($i -lt $leftColumn.Count) { $leftColumn[$i] } else { $null }
                $rightItem = if ($i -lt $rightColumn.Count) { $rightColumn[$i] } else { $null }
                
                $line = ""
                
                # Left column
                if ($leftItem) {
                    $line += "[$($leftItem.Order)] $($leftItem.Title)"
                }
                
                # Add spacing between columns (adjust based on console width)
                $consoleWidth = $host.UI.RawUI.WindowSize.Width
                $columnWidth = if ($consoleWidth -gt 0) { [math]::Floor($consoleWidth / 2) - 10 } else { 40 }
                $padding = $columnWidth - $line.Length
                
                if ($padding -gt 0) {
                    $line += " " * $padding
                }
                
                # Right column
                if ($rightItem) {
                    $line += "[$($rightItem.Order)] $($rightItem.Title)"
                }
                
                Write-Colored $line -Style MenuItem
            }
        }
        
        # Add Exit option
        Write-Host ""
        Write-Colored $(Get-SeparatorLine -Length 80) -Style Separator
        Write-Host ""
        Write-Colored "[0] Exit" -Style MenuItem
        
        Write-Log -Level DEBUG -Message "Menu displayed with $($Features.Count) features" -Silent $true
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to show menu: $_" -Silent $true
        Write-Colored "Menu generation failed." -Style Error
    }
}

function Show-Prompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Message = "SELECT OPTION",
        
        [Parameter(Mandatory=$false)]
        [string]$Default = ""
    )
    
    $promptText = "$Message : "
    
    if ($Default) {
        $promptText += "[$Default] "
    }
    
    Write-Colored $promptText -Style Prompt -NoNewLine
    return Read-Host
}

function Show-StatusBar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Message = "READY",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('info', 'warning', 'error', 'success')]
        [string]$Type = 'info'
    )
    
    # Map type to color
    $colorMap = @{
        info = "Status"
        warning = "Status"
        error = "Error"
        success = "Section"
    }
    
    $color = if ($colorMap.ContainsKey($Type)) { $colorMap[$Type] } else { "Status" }
    
    # Get current time
    $time = Get-Date -Format "HH:mm:ss"
    
    # Format status bar
    $statusText = "STATUS: $Message | Time: $time"
    
    Write-Separator
    Write-Colored $statusText -Style $color
    Write-Separator
}

function Write-Separator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Char = "-",
        
        [Parameter(Mandatory=$false)]
        [int]$Length = 0
    )
    
    if ($Length -eq 0) {
        $Length = $host.UI.RawUI.WindowSize.Width
        if ($Length -le 0) { $Length = 120 } # Default fallback
    }
    
    $separator = $Char * $Length
    Write-Colored $separator -Style Separator
}

function Get-SeparatorLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Char = "-",
        
        [Parameter(Mandatory=$false)]
        [int]$Length = 80
    )
    
    return $Char * $Length
}

function Clear-ScreenSafe {
    [CmdletBinding()]
    param()
    
    try {
        Clear-Host
        Write-Log -Level DEBUG -Message "Screen cleared" -Silent $true
    }
    catch {
        # If Clear-Host fails, write enough newlines
        Write-Host "`n" * 100
    }
}

