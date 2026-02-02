# ui/Theme.ps1
# WinKit Color System - 4 Colors Max, No Icons, No Emoji
# KHÔNG Export-ModuleMember - Dot-source only

# ============================================
# GLOBAL THEME CONFIGURATION
# ============================================

$Global:WinKitTheme = $null
$Global:WinKitColorMap = @{
    # 4 colors cố định theo thiết kế
    Cyan    = "Cyan"
    Green   = "Green"
    White   = "White"
    Yellow  = "Yellow"
    Red     = "Red"
    Gray    = "Gray"
    DarkGray = "DarkGray"
}

# ============================================
# THEME INITIALIZATION
# ============================================

function Initialize-Theme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('default', 'classic', 'highcontrast', 'minimal')]
        [string]$ColorScheme = 'default'
    )
    
    # Define color schemes (4 colors max as per design)
    $themes = @{
        default = @{
            Header     = $Global:WinKitColorMap.Cyan
            Section    = $Global:WinKitColorMap.Green
            MenuItem   = $Global:WinKitColorMap.White
            Status     = $Global:WinKitColorMap.Yellow
            Error      = $Global:WinKitColorMap.Red
            Prompt     = $Global:WinKitColorMap.Yellow
            Separator  = $Global:WinKitColorMap.Gray
            Highlight  = $Global:WinKitColorMap.Cyan
            Success    = $Global:WinKitColorMap.Green
            Warning    = $Global:WinKitColorMap.Yellow
            Info       = $Global:WinKitColorMap.White
            Debug      = $Global:WinKitColorMap.Gray
        }
        
        classic = @{
            Header     = $Global:WinKitColorMap.White
            Section    = $Global:WinKitColorMap.Cyan
            MenuItem   = $Global:WinKitColorMap.White
            Status     = $Global:WinKitColorMap.Yellow
            Error      = $Global:WinKitColorMap.Red
            Prompt     = $Global:WinKitColorMap.White
            Separator  = $Global:WinKitColorMap.DarkGray
            Highlight  = $Global:WinKitColorMap.Cyan
            Success    = $Global:WinKitColorMap.Green
            Warning    = $Global:WinKitColorMap.Yellow
            Info       = $Global:WinKitColorMap.White
            Debug      = $Global:WinKitColorMap.DarkGray
        }
        
        highcontrast = @{
            Header     = $Global:WinKitColorMap.White
            Section    = $Global:WinKitColorMap.White
            MenuItem   = $Global:WinKitColorMap.White
            Status     = $Global:WinKitColorMap.Yellow
            Error      = $Global:WinKitColorMap.Red
            Prompt     = $Global:WinKitColorMap.White
            Separator  = $Global:WinKitColorMap.White
            Highlight  = $Global:WinKitColorMap.White
            Success    = $Global:WinKitColorMap.White
            Warning    = $Global:WinKitColorMap.Yellow
            Info       = $Global:WinKitColorMap.White
            Debug      = $Global:WinKitColorMap.White
        }
        
        minimal = @{
            Header     = $Global:WinKitColorMap.White
            Section    = $Global:WinKitColorMap.Gray
            MenuItem   = $Global:WinKitColorMap.White
            Status     = $Global:WinKitColorMap.Gray
            Error      = $Global:WinKitColorMap.Gray
            Prompt     = $Global:WinKitColorMap.White
            Separator  = $Global:WinKitColorMap.DarkGray
            Highlight  = $Global:WinKitColorMap.White
            Success    = $Global:WinKitColorMap.Gray
            Warning    = $Global:WinKitColorMap.Gray
            Info       = $Global:WinKitColorMap.White
            Debug      = $Global:WinKitColorMap.DarkGray
        }
    }
    
    # Select theme
    if (-not $themes.ContainsKey($ColorScheme)) {
        $ColorScheme = 'default'
    }
    
    # Set global theme
    $Global:WinKitTheme = $themes[$ColorScheme]
    
    # Log theme initialization
    try {
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Level INFO -Message "Theme initialized: $ColorScheme with $(($Global:WinKitTheme.Keys | Measure-Object).Count) colors" -Silent $true
        }
    }
    catch {
        # Silent fail if logger not available
    }
    
    return $Global:WinKitTheme
}

# ============================================
# THEME ACCESSORS
# ============================================

function Get-Theme {
    [CmdletBinding()]
    param()
    
    if (-not $Global:WinKitTheme) {
        Initialize-Theme -ColorScheme 'default' | Out-Null
    }
    
    return $Global:WinKitTheme
}

function Get-ThemeColor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Header', 'Section', 'MenuItem', 'Status', 'Error', 'Prompt', 'Separator', 'Highlight', 'Success', 'Warning', 'Info', 'Debug')]
        [string]$Component
    )
    
    $theme = Get-Theme
    
    if ($theme.ContainsKey($Component)) {
        return $theme[$Component]
    }
    
    # Fallback to White if component not found
    return $Global:WinKitColorMap.White
}

# ============================================
# COLORED OUTPUT FUNCTIONS
# ============================================

function Write-Colored {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Text,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Header', 'Section', 'MenuItem', 'Status', 'Error', 'Prompt', 'Separator', 'Highlight', 'Success', 'Warning', 'Info', 'Debug')]
        [string]$Style = 'MenuItem',
        
        [Parameter(Mandatory=$false)]
        [switch]$NoNewLine,
        
        [Parameter(Mandatory=$false)]
        [switch]$Center,
        
        [Parameter(Mandatory=$false)]
        [switch]$NoColor
    )
    
    begin {
        $theme = Get-Theme
        
        if (-not $theme.ContainsKey($Style)) {
            $Style = 'MenuItem'
        }
        
        $color = $theme[$Style]
        $originalForeground = $host.UI.RawUI.ForegroundColor
        $originalBackground = $host.UI.RawUI.BackgroundColor
    }
    
    process {
        # Center text if requested
        if ($Center) {
            $consoleWidth = $host.UI.RawUI.WindowSize.Width
            if ($consoleWidth -gt 0) {
                $padding = [math]::Max(0, [math]::Floor(($consoleWidth - $Text.Length) / 2))
                $Text = (" " * $padding) + $Text
            }
        }
        
        # Set color and write (or skip color if NoColor specified)
        if (-not $NoColor) {
            try {
                $host.UI.RawUI.ForegroundColor = $color
            }
            catch {
                # Invalid color, use default
                $host.UI.RawUI.ForegroundColor = $originalForeground
            }
        }
        
        # Write text
        if ($NoNewLine) {
            Write-Host $Text -NoNewline
        }
        else {
            Write-Host $Text
        }
        
        # Restore original color
        $host.UI.RawUI.ForegroundColor = $originalForeground
        $host.UI.RawUI.BackgroundColor = $originalBackground
    }
    
    end {
        # Ensure colors are restored
        $host.UI.RawUI.ForegroundColor = $originalForeground
        $host.UI.RawUI.BackgroundColor = $originalBackground
    }
}

function Write-Status {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('info', 'success', 'warning', 'error', 'debug')]
        [string]$Type = 'info',
        
        [Parameter(Mandatory=$false)]
        [switch]$NoNewLine
    )
    
    $styleMap = @{
        info    = 'Status'
        success = 'Success'
        warning = 'Warning'
        error   = 'Error'
        debug   = 'Debug'
    }
    
    $style = if ($styleMap.ContainsKey($Type)) { $styleMap[$Type] } else { 'Status' }
    
    Write-Colored $Message -Style $style -NoNewLine:$NoNewLine
}

function Write-Separator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Char = "-",
        
        [Parameter(Mandatory=$false)]
        [int]$Length = 0,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Separator', 'Header', 'Section')]
        [string]$Style = 'Separator'
    )
    
    if ($Length -eq 0) {
        $Length = $host.UI.RawUI.WindowSize.Width
        if ($Length -le 0) { $Length = 120 } # Default fallback
    }
    
    $separator = $Char * $Length
    Write-Colored $separator -Style $Style
}

# ============================================
# FORMATTING HELPERS
# ============================================

function Format-Box {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Header', 'Section', 'MenuItem')]
        [string]$Style = 'MenuItem',
        
        [Parameter(Mandatory=$false)]
        [int]$Width = 80
    )
    
    # ASCII box only - no Unicode
    $top = "+" + ("-" * ($Width - 2)) + "+"
    $bottom = "+" + ("-" * ($Width - 2)) + "+"
    
    $lines = $Text -split "`n"
    $formatted = @()
    
    $formatted += $top
    
    foreach ($line in $lines) {
        if ($line.Length -gt ($Width - 4)) {
            $line = $line.Substring(0, $Width - 7) + "..."
        }
        
        $padding = $Width - $line.Length - 3
        $formattedLine = "| " + $line + (" " * $padding) + "|"
        $formatted += $formattedLine
    }
    
    $formatted += $bottom
    
    # Output with color
    foreach ($line in $formatted) {
        Write-Colored $line -Style $Style
    }
}

function Format-Table {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Data,
        
        [Parameter(Mandatory=$false)]
        [int]$KeyWidth = 20,
        
        [Parameter(Mandatory=$false)]
        [int]$ValueWidth = 60
    )
    
    foreach ($key in $Data.Keys) {
        $keyFormatted = $key.PadRight($KeyWidth, ' ')
        $value = $Data[$key]
        
        if ($value.Length -gt $ValueWidth) {
            $value = $value.Substring(0, $ValueWidth - 3) + "..."
        }
        
        Write-Colored "$keyFormatted : " -Style 'Section' -NoNewLine
        Write-Colored $value -Style 'MenuItem'
    }
}

# ============================================
# THEME TESTING
# ============================================

function Test-Theme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ColorScheme = 'default'
    )
    
    Clear-Host
    
    # Initialize theme
    Initialize-Theme -ColorScheme $ColorScheme | Out-Null
    
    Write-Colored "WinKit Theme Test - $ColorScheme" -Style Header -Center
    Write-Separator -Char "=" -Style Separator
    Write-Host ""
    
    # Test all styles
    Write-Colored "Header Style (Cyan)" -Style Header
    Write-Colored "Section Style (Green)" -Style Section
    Write-Colored "MenuItem Style (White)" -Style MenuItem
    Write-Colored "Status Style (Yellow)" -Style Status
    Write-Colored "Error Style (Red)" -Style Error
    Write-Colored "Prompt Style (Yellow)" -Style Prompt
    Write-Colored "Separator Style (Gray)" -Style Separator
    Write-Colored "Success Style (Green)" -Style Success
    Write-Colored "Warning Style (Yellow)" -Style Warning
    Write-Colored "Info Style (White)" -Style Info
    Write-Colored "Debug Style (Gray)" -Style Debug
    
    Write-Host ""
    Write-Separator -Style Separator
    
    # Test status messages
    Write-Host ""
    Write-Status "This is an info message" -Type info
    Write-Status "This is a success message" -Type success
    Write-Status "This is a warning message" -Type warning
    Write-Status "This is an error message" -Type error
    
    Write-Host ""
    Write-Separator -Char "=" -Style Separator
    Write-Colored "Theme test completed successfully!" -Style Success -Center
}

# ============================================
# COLOR VALIDATION
# ============================================

function Test-ColorSupport {
    [CmdletBinding()]
    param()
    
    $results = @{
        SupportsColors = $true
        AvailableColors = @()
        Issues = @()
    }
    
    try {
        # Test basic colors
        $testColors = @('Black', 'White', 'Red', 'Green', 'Yellow', 'Blue', 'Magenta', 'Cyan', 'Gray', 'DarkGray')
        
        foreach ($color in $testColors) {
            try {
                $host.UI.RawUI.ForegroundColor = $color
                $results.AvailableColors += $color
                $host.UI.RawUI.ForegroundColor = 'White' # Reset
            }
            catch {
                $results.Issues += "Color not supported: $color"
            }
        }
        
        # Check if we have at least basic colors
        $requiredColors = @('White', 'Green', 'Yellow', 'Red', 'Cyan')
        foreach ($required in $requiredColors) {
            if ($required -notin $results.AvailableColors) {
                $results.SupportsColors = $false
                $results.Issues += "Required color missing: $required"
            }
        }
        
        return $results
    }
    catch {
        return @{
            SupportsColors = $false
            AvailableColors = @()
            Issues = @("Color test failed: $_")
        }
    }
}

# ============================================
# KHÔNG Export-ModuleMember
# Functions available when dot-sourced
# ============================================
