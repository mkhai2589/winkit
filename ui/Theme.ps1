# ui/Theme.ps1
# WinKit Color System - 4 Colors Max, No Icons, No Emoji

$Global:WinKitTheme = $null

function Initialize-Theme {
    [CmdletBinding()]
    param(
        [string]$ColorScheme = "default"
    )
    
    $themes = @{
        default = @{
            Header = "Cyan"
            Section = "Green"
            MenuItem = "White"
            Status = "Yellow"
            Error = "Red"
            Prompt = "Yellow"
        }
    }
    
    $Global:WinKitTheme = $themes.default
    
    return $Global:WinKitTheme
}

    
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
        [string]$Text,
        [string]$Style = "MenuItem"
    )
    
    $color = if ($Global:WinKitTheme -and $Global:WinKitTheme.ContainsKey($Style)) {
        $Global:WinKitTheme[$Style]
    } else {
        "White"
    }
    
    Write-Host $Text -ForegroundColor $color
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



