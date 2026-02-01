# ==========================================
# WinKit UI Module
# Console presentation layer - Ghost Toolbox style
# ==========================================

#region CORE UI FUNCTIONS

function Initialize-UI {
    <#
    .SYNOPSIS
    Initializes the console UI with header and ASCII art
    #>
    
    Clear-Host
    
    # Display ASCII art if available
    $asciiPath = Join-Path $global:WK_ROOT "assets\ascii.txt"
    if (Test-Path $asciiPath) {
        try {
            $asciiArt = Get-Content $asciiPath
            foreach ($line in $asciiArt) {
                Write-Host $line -ForegroundColor $WK_THEME.Header
            }
            Write-Host ""
        }
        catch {
            # Fallback if ASCII art fails
            Show-MinimalHeader
        }
    }
    else {
        Show-MinimalHeader
    }
}

function Show-MinimalHeader {
    <#
    .SYNOPSIS
    Displays minimal header when ASCII art is not available
    #>
    
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor $WK_THEME.Header
    Write-Host "║" -NoNewline -ForegroundColor $WK_THEME.Header
    Write-Host "         WinKit - Windows Toolkit          " -NoNewline -ForegroundColor $WK_THEME.Title
    Write-Host "║" -ForegroundColor $WK_THEME.Header
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor $WK_THEME.Header
    Write-Host ""
}

function Show-Header {
    <#
    .SYNOPSIS
    Displays system information header (Ghost Toolbox style)
    #>
    
    try {
        # Get system information
        $sysInfo = Get-WKSystemInfo
        
        Write-Host "┌─────────────────────────────────────────────────────────┐" -ForegroundColor $WK_THEME.Border
        
        # Line 1: User | Computer | OS | Build | Mode
        Write-Host "│ " -NoNewline -ForegroundColor $WK_THEME.Border
        Write-Host "USER:" -NoNewline -ForegroundColor $WK_THEME.Info
        Write-Host " $($sysInfo.User)" -NoNewline -ForegroundColor $WK_THEME.Primary
        Write-Host " | " -NoNewline -ForegroundColor $WK_THEME.Secondary
        Write-Host "PC:" -NoNewline -ForegroundColor $WK_THEME.Info
        Write-Host " $($sysInfo.Computer)" -NoNewline -ForegroundColor $WK_THEME.Primary
        Write-Host " | " -NoNewline -ForegroundColor $WK_THEME.Secondary
        Write-Host "OS:" -NoNewline -ForegroundColor $WK_THEME.Info
        Write-Host " $($sysInfo.OS)" -NoNewline -ForegroundColor $WK_THEME.Primary
        Write-Host " | " -NoNewline -ForegroundColor $WK_THEME.Secondary
        Write-Host "BUILD:" -NoNewline -ForegroundColor $WK_THEME.Info
        Write-Host " $($sysInfo.Build)" -ForegroundColor $WK_THEME.Primary
        
        # Line 2: TimeZone | Version | Social
        Write-Host "│ " -NoNewline -ForegroundColor $WK_THEME.Border
        Write-Host "TIMEZONE:" -NoNewline -ForegroundColor $WK_THEME.Info
        Write-Host " $($sysInfo.TimeZone)" -NoNewline -ForegroundColor $WK_THEME.Secondary
        Write-Host " | " -NoNewline -ForegroundColor $WK_THEME.Secondary
        Write-Host "VERSION:" -NoNewline -ForegroundColor $WK_THEME.Info
        Write-Host " $($sysInfo.Version)" -NoNewline -ForegroundColor $WK_THEME.Accent
        Write-Host " | " -NoNewline -ForegroundColor $WK_THEME.Secondary
        Write-Host "GITHUB:" -NoNewline -ForegroundColor $WK_THEME.Info
        Write-Host " mkhai2589/winkit" -ForegroundColor $WK_THEME.Highlight
        
        Write-Host "├─────────────────────────────────────────────────────────┤" -ForegroundColor $WK_THEME.Border
    }
    catch {
        # Fallback header if system info fails
        Write-Host "┌─────────────────────────────────────────────────────────┐" -ForegroundColor $WK_THEME.Border
        Write-Host "│ " -NoNewline -ForegroundColor $WK_THEME.Border
        Write-Host "WinKit - Windows Optimization Toolkit" -ForegroundColor $WK_THEME.Primary
        Write-Host "├─────────────────────────────────────────────────────────┤" -ForegroundColor $WK_THEME.Border
    }
}

function Show-Footer {
    <#
    .SYNOPSIS
    Displays footer with version information
    #>
    
    try {
        $versionPath = Join-Path $global:WK_ROOT "version.json"
        if (Test-Path $versionPath) {
            $version = Read-Json -Path $versionPath
            Write-Host "└─────────────────────────────────────────────────────────┘" -ForegroundColor $WK_THEME.Border
            Write-Host "Version $($version.version) ($($version.channel))" -ForegroundColor $WK_THEME.Secondary
            Write-Host ""
        }
    }
    catch {
        Write-Host "└─────────────────────────────────────────────────────────┘" -ForegroundColor $WK_THEME.Border
        Write-Host "WinKit v1.0.0" -ForegroundColor $WK_THEME.Secondary
        Write-Host ""
    }
}

function Show-Section {
    <#
    .SYNOPSIS
    Displays a section title with separator
    
    .PARAMETER Title
    The title of the section
    
    .PARAMETER Color
    Color of the title (default from theme)
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [string]$Color = $WK_THEME.Title
    )
    
    Write-Host ""
    Write-Host $Title -ForegroundColor $Color
    Write-Host ("─" * $Title.Length) -ForegroundColor $WK_THEME.Border
}

#endregion

#region UTILITY UI FUNCTIONS

function Show-MessageBox {
    <#
    .SYNOPSIS
    Displays a message in a bordered box
    
    .PARAMETER Message
    Message to display
    
    .PARAMETER Type
    Type of message (info, success, warning, error)
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [ValidateSet('info', 'success', 'warning', 'error')]
        [string]$Type = 'info'
    )
    
    # Determine colors based on type
    $borderColor = switch ($Type) {
        'info'    { $WK_THEME.Accent }
        'success' { $WK_THEME.Success }
        'warning' { $WK_THEME.Warning }
        'error'   { $WK_THEME.Error }
        default   { $WK_THEME.Border }
    }
    
    $textColor = switch ($Type) {
        'info'    { $WK_THEME.Primary }
        'success' { $WK_THEME.Success }
        'warning' { $WK_THEME.Warning }
        'error'   { $WK_THEME.Error }
        default   { $WK_THEME.Primary }
    }
    
    # Wrap message to 60 characters
    $wrappedLines = @()
    $words = $Message -split ' '
    $currentLine = ""
    
    foreach ($word in $words) {
        if (($currentLine + " " + $word).Length -le 58) {
            $currentLine += " " + $word
        }
        else {
            $wrappedLines += $currentLine.Trim()
            $currentLine = $word
        }
    }
    if ($currentLine) {
        $wrappedLines += $currentLine.Trim()
    }
    
    # Display box
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor $borderColor
    
    foreach ($line in $wrappedLines) {
        $paddedLine = $line.PadRight(58)
        Write-Host "║ " -NoNewline -ForegroundColor $borderColor
        Write-Host $paddedLine -NoNewline -ForegroundColor $textColor
        Write-Host " ║" -ForegroundColor $borderColor
    }
    
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor $borderColor
    Write-Host ""
}

function Show-ProgressBar {
    <#
    .SYNOPSIS
    Displays a simple progress bar
    
    .PARAMETER Activity
    Name of the activity
    
    .PARAMETER Status
    Current status message
    
    .PARAMETER PercentComplete
    Percentage complete (0-100)
    
    .PARAMETER Completed
    Marks the progress as completed
    #>
    
    param(
        [string]$Activity = "Processing",
        [string]$Status = "Working...",
        [int]$PercentComplete = -1,
        [switch]$Completed
    )
    
    if ($Completed) {
        Write-Progress -Activity $Activity -Completed
        return
    }
    
    if ($PercentComplete -ge 0 -and $PercentComplete -le 100) {
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    }
    else {
        Write-Progress -Activity $Activity -Status $Status
    }
}

function Show-HorizontalRule {
    <#
    .SYNOPSIS
    Displays a horizontal rule/separator
    
    .PARAMETER Character
    Character to use for the rule
    
    .PARAMETER Length
    Length of the rule (default: console width)
    
    .PARAMETER Color
    Color of the rule
    #>
    
    param(
        [string]$Character = "─",
        [int]$Length = 60,
        [string]$Color = $WK_THEME.Border
    )
    
    Write-Host ($Character * $Length) -ForegroundColor $Color
}

function Show-KeyValuePair {
    <#
    .SYNOPSIS
    Displays a key-value pair in formatted style
    
    .PARAMETER Key
    Key/label
    
    .PARAMETER Value
    Value
    
    .PARAMETER Indent
    Number of spaces to indent
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$Key,
        
        [Parameter(Mandatory=$true)]
        [string]$Value,
        
        [int]$Indent = 2
    )
    
    $indentSpaces = " " * $Indent
    Write-Host "$indentSpaces$Key" -NoNewline -ForegroundColor $WK_THEME.Info
    Write-Host ": $Value" -ForegroundColor $WK_THEME.Primary
}

function Show-BulletList {
    <#
    .SYNOPSIS
    Displays a bulleted list
    
    .PARAMETER Items
    Array of items to display
    
    .PARAMETER Bullet
    Bullet character
    
    .PARAMETER Indent
    Number of spaces to indent
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [array]$Items,
        
        [string]$Bullet = "•",
        
        [int]$Indent = 2
    )
    
    $indentSpaces = " " * $Indent
    
    foreach ($item in $Items) {
        Write-Host "$indentSpaces$Bullet" -NoNewline -ForegroundColor $WK_THEME.Accent
        Write-Host " $item" -ForegroundColor $WK_THEME.Primary
    }
}

#endregion

#region DASHBOARD LAYOUT FUNCTIONS (for future use)

function Show-TwoColumnLayout {
    <#
    .SYNOPSIS
    Displays content in two columns (Ghost Toolbox style)
    
    .PARAMETER LeftTitle
    Title for left column
    
    .PARAMETER LeftItems
    Array of items for left column
    
    .PARAMETER RightTitle
    Title for right column
    
    .PARAMETER RightItems
    Array of items for right column
    
    .EXAMPLE
    Show-TwoColumnLayout -LeftTitle "TWEAKS" -LeftItems @("Disable Telemetry", "Remove Bloatware") -RightTitle "APPS" -RightItems @("Install Chrome", "Install VSCode")
    #>
    
    param(
        [string]$LeftTitle = "TWEAKS",
        [array]$LeftItems = @(),
        [string]$RightTitle = "APPS",
        [array]$RightItems = @()
    )
    
    # Calculate layout
    $columnWidth = 30
    $totalWidth = 62
    
    # Column headers
    Write-Host "│ " -NoNewline -ForegroundColor $WK_THEME.Border
    Write-Host $LeftTitle.PadRight($columnWidth) -NoNewline -ForegroundColor $WK_THEME.Title
    Write-Host "│ " -NoNewline -ForegroundColor $WK_THEME.Border
    Write-Host $RightTitle.PadRight($columnWidth) -ForegroundColor $WK_THEME.Title
    
    # Separator
    Write-Host "├" -NoNewline -ForegroundColor $WK_THEME.Border
    Write-Host ("─" * ($columnWidth + 1)) -NoNewline -ForegroundColor $WK_THEME.Border
    Write-Host "┼" -NoNewline -ForegroundColor $WK_THEME.Border
    Write-Host ("─" * ($columnWidth + 1)) -NoNewline -ForegroundColor $WK_THEME.Border
    Write-Host "┤" -ForegroundColor $WK_THEME.Border
    
    # Display items
    $maxRows = [Math]::Max($LeftItems.Count, $RightItems.Count)
    
    for ($i = 0; $i -lt $maxRows; $i++) {
        $leftItem = if ($i -lt $LeftItems.Count) { $LeftItems[$i] } else { "" }
        $rightItem = if ($i -lt $RightItems.Count) { $RightItems[$i] } else { "" }
        
        Write-Host "│ " -NoNewline -ForegroundColor $WK_THEME.Border
        Write-Host $leftItem.PadRight($columnWidth) -NoNewline -ForegroundColor $WK_THEME.Primary
        Write-Host "│ " -NoNewline -ForegroundColor $WK_THEME.Border
        Write-Host $rightItem.PadRight($columnWidth) -NoNewline -ForegroundColor $WK_THEME.Primary
        Write-Host "│" -ForegroundColor $WK_THEME.Border
    }
}

function Show-CompactFeatureList {
    <#
    .SYNOPSIS
    Displays features in a compact numbered list
    
    .PARAMETER Features
    Array of feature objects (must have 'id', 'order', 'title')
    
    .PARAMETER ItemsPerRow
    Number of items per row
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [array]$Features,
        
        [int]$ItemsPerRow = 2
    )
    
    $sortedFeatures = $Features | Sort-Object order
    $featureCount = $sortedFeatures.Count
    
    for ($i = 0; $i -lt $featureCount; $i += $ItemsPerRow) {
        Write-Host "  " -NoNewline
        
        for ($j = 0; $j -lt $ItemsPerRow; $j++) {
            $index = $i + $j
            if ($index -lt $featureCount) {
                $feature = $sortedFeatures[$index]
                Write-Host "[$($feature.order)]" -NoNewline -ForegroundColor $WK_THEME.MenuItem
                Write-Host " $($feature.title.PadRight(25))" -NoNewline -ForegroundColor $WK_THEME.Primary
            }
        }
        
        Write-Host ""
    }
}

#endregion

#region INITIALIZATION

# Verify theme is loaded
if (-not $global:WK_THEME) {
    # Default theme if not loaded
    $global:WK_THEME = @{
        Primary = "White"
        Secondary = "Gray"
        Accent = "Cyan"
        Success = "Green"
        Warning = "Yellow"
        Error = "Red"
        Highlight = "Blue"
        Header = "Cyan"
        Title = "White"
        MenuItem = "Green"
        Description = "Gray"
        Border = "DarkGray"
        Info = "Cyan"
    }
}

# Export functions
Export-ModuleMember -Function Initialize-UI, Show-Header, Show-Footer, Show-Section, `
    Show-MessageBox, Show-ProgressBar, Show-HorizontalRule, Show-KeyValuePair, `
    Show-BulletList, Show-TwoColumnLayout, Show-CompactFeatureList, Show-MinimalHeader

# Log UI module load (if logger is available)
try {
    Write-Log -Message "UI module initialized" -Level "DEBUG"
}
catch {
    # Silently continue if logger not available
}

#endregion
