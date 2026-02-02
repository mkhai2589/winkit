# ui/Theme.ps1
# WinKit Color System - 4 Colors Max, No Icons, No Emoji

$Global:WinKitTheme = $null

function Initialize-Theme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('default', 'classic', 'highcontrast')]
        [string]$ColorScheme = 'default'
    )
    
    Write-Log -Level INFO -Message "Initializing theme: $ColorScheme" -Silent $true
    
    # Define color schemes (4 colors max as per design)
    $themes = @{
        default = @{
            Header    = "Cyan"
            Section   = "Green"
            MenuItem  = "White"
            Status    = "Yellow"
            Error     = "Red"
            Prompt    = "Yellow"
            Separator = "Gray"
        }
        classic = @{
            Header    = "Cyan"
            Section   = "Green"
            MenuItem  = "White"
            Status    = "Yellow"
            Error     = "Red"
            Prompt    = "White"
            Separator = "DarkGray"
        }
        highcontrast = @{
            Header    = "White"
            Section   = "White"
            MenuItem  = "White"
            Status    = "Yellow"
            Error     = "Red"
            Prompt    = "White"
            Separator = "White"
        }
    }
    
    # Select theme
    if (-not $themes.ContainsKey($ColorScheme)) {
        $ColorScheme = 'default'
        Write-Log -Level WARN -Message "Invalid color scheme, defaulting to: $ColorScheme" -Silent $true
    }
    
    $Global:WinKitTheme = $themes[$ColorScheme]
    
    Write-Log -Level INFO -Message "Theme initialized with $($Global:WinKitTheme.Count) colors" -Silent $true
    return $Global:WinKitTheme
}

function Get-Theme {
    [CmdletBinding()]
    param()
    
    if (-not $Global:WinKitTheme) {
        Initialize-Theme -ColorScheme 'default' | Out-Null
    }
    
    return $Global:WinKitTheme
}

function Write-Colored {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Text,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Header', 'Section', 'MenuItem', 'Status', 'Error', 'Prompt', 'Separator')]
        [string]$Style = 'MenuItem',
        
        [Parameter(Mandatory=$false)]
        [switch]$NoNewLine,
        
        [Parameter(Mandatory=$false)]
        [switch]$Center
    )
    
    begin {
        $theme = Get-Theme
        
        if (-not $theme.ContainsKey($Style)) {
            $Style = 'MenuItem'
        }
        
        $color = $theme[$Style]
        $originalColor = $host.UI.RawUI.ForegroundColor
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
        
        # Set color and write
        try {
            $host.UI.RawUI.ForegroundColor = $color
        }
        catch {
            $host.UI.RawUI.ForegroundColor = "White"
        }
        
        if ($NoNewLine) {
            Write-Host $Text -NoNewline
        }
        else {
            Write-Host $Text
        }
        
        # Restore original color
        $host.UI.RawUI.ForegroundColor = $originalColor
    }
    
    end {
        # Ensure color is restored
        $host.UI.RawUI.ForegroundColor = $originalColor
    }
}

function Get-Color {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Header', 'Section', 'MenuItem', 'Status', 'Error', 'Prompt', 'Separator')]
        [string]$Style
    )
    
    $theme = Get-Theme
    
    if ($theme.ContainsKey($Style)) {
        return $theme[$Style]
    }
    
    return "White"
}

# Test theme rendering
function Test-Theme {
    [CmdletBinding()]
    param()
    
    Clear-Host
    
    Write-Colored "WinKit Theme Test" -Style Header
    Write-Colored "=================" -Style Separator
    Write-Host ""
    
    Write-Colored "Header Style" -Style Header
    Write-Colored "Section Style" -Style Section
    Write-Colored "MenuItem Style" -Style MenuItem
    Write-Colored "Status Style" -Style Status
    Write-Colored "Error Style" -Style Error
    Write-Colored "Prompt Style" -Style Prompt
    
    Write-Host ""
    Write-Colored "Theme test completed." -Style Status
}

# Export functions
$ExportFunctions = @(
    'Initialize-Theme',
    'Get-Theme',
    'Write-Colored',
    'Get-Color',
    'Test-Theme'
)

Export-ModuleMember -Function $ExportFunctions
