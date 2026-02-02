# core/Interface.ps1
# Contract and Interface Helpers

function Initialize-WinKit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ConfigPath = "config.json"
    )
    
    Write-Log -Level INFO -Message "Initializing WinKit framework" -Silent $true
    
    # Load configuration
    $config = Load-Configuration -Path $ConfigPath
    
    # Initialize core components
    $initResults = @{
        Logger = Initialize-Log -LogPath $config.Logging.Path
        Window = Initialize-Window -Width $config.Window.Width -Height $config.Window.Height
        Theme = Initialize-Theme -ColorScheme $config.UI.ColorScheme
    }
    
    # Log initialization results
    foreach ($component in $initResults.Keys) {
        Write-Log -Level INFO -Message "$component initialized: $($initResults[$component])" -Silent $true
    }
    
    return $initResults
}

function Load-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    $defaultConfig = @{
        Window = @{
            Width = 120
            Height = 40
            Title = "WinKit - Windows Optimization Toolkit"
        }
        UI = @{
            Columns = 2
            ShowStatus = $true
            LogoStyle = "boxed"
            ColorScheme = "default"
        }
        Logging = @{
            Path = "$env:TEMP\winkit"
            MaxSizeMB = 1
            MaxBackupFiles = 3
        }
    }
    
    try {
        if (Test-Path $Path) {
            $configContent = Get-Content $Path -Raw -ErrorAction Stop
            $config = $configContent | ConvertFrom-Json -AsHashtable
            
            # Merge with defaults for missing values
            $config = Merge-Hashtables $defaultConfig, $config
            
            Write-Log -Level INFO -Message "Configuration loaded from: $Path" -Silent $true
        }
        else {
            $config = $defaultConfig
            Write-Log -Level WARN -Message "Config file not found, using defaults: $Path" -Silent $true
        }
        
        return $config
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to load configuration: $_" -Silent $true
        return $defaultConfig
    }
}

function Merge-Hashtables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [hashtable]$Base,
        
        [Parameter(Mandatory=$true, Position=1)]
        [hashtable[]]$Additional
    )
    
    $result = $Base.Clone()
    
    foreach ($hash in $Additional) {
        foreach ($key in $hash.Keys) {
            if ($result.ContainsKey($key) -and $result[$key] -is [hashtable] -and $hash[$key] -is [hashtable]) {
                # Recursive merge for nested hashtables
                $result[$key] = Merge-Hashtables $result[$key] $hash[$key]
            }
            else {
                $result[$key] = $hash[$key]
            }
        }
    }
    
    return $result
}

function Initialize-Window {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$Width = 120,
        
        [Parameter(Mandatory=$false)]
        [int]$Height = 40
    )
    
    try {
        # Set window size
        $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size($Width, $Height)
        
        # Set buffer size to match window
        $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($Width, $Height)
        
        Write-Log -Level INFO -Message "Window initialized: ${Width}x${Height}" -Silent $true
        return $true
    }
    catch {
        Write-Log -Level WARN -Message "Failed to resize window: $_" -Silent $true
        return $false
    }
}

function Initialize-Theme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ColorScheme = "default"
    )
    
    # Define color schemes
    $themes = @{
        default = @{
            Header = "Cyan"
            Section = "Green"
            MenuItem = "White"
            Status = "Yellow"
            Error = "Red"
            Success = "Green"
            Prompt = "Yellow"
            Highlight = "Magenta"
        }
        classic = @{
            Header = "White"
            Section = "Cyan"
            MenuItem = "Gray"
            Status = "Yellow"
            Error = "Red"
            Success = "Green"
            Prompt = "White"
            Highlight = "Cyan"
        }
        highcontrast = @{
            Header = "White"
            Section = "White"
            MenuItem = "White"
            Status = "Yellow"
            Error = "Red"
            Success = "White"
            Prompt = "White"
            Highlight = "White"
        }
    }
    
    if (-not $themes.ContainsKey($ColorScheme)) {
        $ColorScheme = "default"
    }
    
    $theme = $themes[$ColorScheme]
    
    # Store theme globally (will be used by UI module)
    $Global:WinKitTheme = $theme
    
    Write-Log -Level INFO -Message "Theme initialized: $ColorScheme" -Silent $true
    return $theme
}

function Get-ThemeColor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Header', 'Section', 'MenuItem', 'Status', 'Error', 'Success', 'Prompt', 'Highlight')]
        [string]$Component
    )
    
    if (-not $Global:WinKitTheme) {
        Initialize-Theme -ColorScheme "default" | Out-Null
    }
    
    return $Global:WinKitTheme[$Component]
}

function Write-Color {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Text,
        
        [Parameter(Mandatory=$false)]
        [string]$Color = "White",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoNewLine
    )
    
    begin {
        # Store original colors
        $originalForeground = $host.UI.RawUI.ForegroundColor
        $originalBackground = $host.UI.RawUI.BackgroundColor
    }
    
    process {
        # Set color
        try {
            $host.UI.RawUI.ForegroundColor = $Color
        }
        catch {
            # Invalid color, use default
            $host.UI.RawUI.ForegroundColor = "White"
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
    }
    
    end {
        # Ensure colors are restored
        $host.UI.RawUI.ForegroundColor = $originalForeground
        $host.UI.RawUI.BackgroundColor = $originalBackground
    }
}

