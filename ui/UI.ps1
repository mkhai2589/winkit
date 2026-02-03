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
        $osVersion = "$($os.Version.Major).$($os.Version.Minor) Build $($os.Version.Build)"
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
        [Parameter(Mandatory=$true)]
        [hashtable]$MenuData  # NHẬN DATA TỪ MENU.PS1, KHÔNG TỰ LẤY
    )
    
    try {
        # MenuData có format:
        # @{
        #   Categories = @("Essential", "Advanced", "Tools")
        #   ItemsByCategory = @{
        #     "Essential" = @(
        #       @{MenuNumber = 1; Title = "Clean System"; Id = "CleanSystem"}
        #       @{MenuNumber = 2; Title = "Debloat Windows"; Id = "Debloat"}
        #     )
        #     "Advanced" = @(...)
        #   }
        #   ExitNumber = 10
        # }
        
        $categories = $MenuData.Categories
        $itemsByCategory = $MenuData.ItemsByCategory
        $exitNumber = $MenuData.ExitNumber
        
        if (($categories.Count -eq 0) -or ($itemsByCategory.Count -eq 0)) {
            Write-Colored "No menu data available." -Style Error
            return
        }
        
        foreach ($category in $categories) {
            $items = $itemsByCategory[$category]
            
            if ($items.Count -eq 0) {
                continue
            }
            
            # Display category header
            Write-Host ""
            Write-Colored "[ $category ]" -Style Section
            Write-Separator -Length 40
            Write-Host ""
            
            # Calculate columns: 2 cột theo config
            $columns = if ($Global:WinKitConfig.UI.Columns) { $Global:WinKitConfig.UI.Columns } else { 2 }
            $featuresPerColumn = [math]::Ceiling($items.Count / $columns)
            
            # Chia items thành các cột
            $columnsData = @()
            for ($col = 0; $col -lt $columns; $col++) {
                $startIdx = $col * $featuresPerColumn
                $endIdx = [math]::Min($startIdx + $featuresPerColumn - 1, $items.Count - 1)
                if ($startIdx -le $endIdx) {
                    $columnsData += , @($items[$startIdx..$endIdx])
                } else {
                    $columnsData += , @()
                }
            }
            
            # Hiển thị theo dòng (mỗi dòng có items từ tất cả cột)
            for ($row = 0; $row -lt $featuresPerColumn; $row++) {
                $line = ""
                
                for ($col = 0; $col -lt $columns; $col++) {
                    if ($row -lt $columnsData[$col].Count) {
                        $item = $columnsData[$col][$row]
                        $itemText = "[$($item.MenuNumber)] $($item.Title)"
                        
                        # Thêm padding giữa các cột
                        if ($col -gt 0) {
                            $columnWidth = 40  # Default width per column
                            $currentLength = $line.Length % $columnWidth
                            if ($currentLength -gt 0) {
                                $padding = $columnWidth - $currentLength
                                $line += " " * $padding
                            }
                        }
                        
                        $line += $itemText
                    }
                }
                
                if ($line.Trim() -ne "") {
                    Write-Colored $line -Style MenuItem
                }
            }
        }
        
        # Add Exit option
        Write-Host ""
        Write-Separator -Length 80
        Write-Host ""
        Write-Colored "[$exitNumber] Exit" -Style MenuItem
        
        Write-Log -Level DEBUG -Message "Menu displayed with $($categories.Count) categories" -Silent $true
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to render menu: $_" -Silent $true
        Write-Colored "Menu rendering failed." -Style Error
    }
}

function Show-Prompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Message = "TYPE OPTION",
        
        [Parameter(Mandatory=$false)]
        [string]$Default = ""
    )
    
    $promptText = "$Message : "
    
    if ($Default -and ($Default -ne "")) {
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
        warning = "Warning"
        error = "Error"
        success = "Success"
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
