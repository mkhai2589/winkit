# =========================================================
# ui/Theme.ps1
# WinKit Theme & Color System
#
# DESIGN RULES:
# - UI only
# - No business logic
# - No feature / context knowledge
# - Dot-source only (NO Export-ModuleMember)
#
# COLOR POLICY:
# - Limited, readable, console-safe
# - No icons, no emoji, ASCII only
# =========================================================

# =========================================================
# INTERNAL STATE (SCRIPT SCOPE ONLY)
# =========================================================
$script:WinKitTheme = $null

$script:WinKitColorMap = @{
    Cyan      = 'Cyan'
    Green     = 'Green'
    White     = 'White'
    Yellow    = 'Yellow'
    Red       = 'Red'
    Gray      = 'Gray'
    DarkGray  = 'DarkGray'
}

# =========================================================
# THEME INITIALIZATION
# =========================================================
function Initialize-Theme {
    [CmdletBinding()]
    param(
        [ValidateSet('default', 'classic', 'highcontrast', 'minimal')]
        [string]$ColorScheme = 'default'
    )

    $themes = @{
        default = @{
            Header    = $script:WinKitColorMap.Cyan
            Section   = $script:WinKitColorMap.Green
            MenuItem  = $script:WinKitColorMap.White
            Status    = $script:WinKitColorMap.Yellow
            Error     = $script:WinKitColorMap.Red
            Prompt    = $script:WinKitColorMap.Yellow
            Separator = $script:WinKitColorMap.Gray
            Highlight = $script:WinKitColorMap.Cyan
            Success   = $script:WinKitColorMap.Green
            Warning   = $script:WinKitColorMap.Yellow
            Info      = $script:WinKitColorMap.White
            Debug     = $script:WinKitColorMap.Gray
        }

        classic = @{
            Header    = $script:WinKitColorMap.White
            Section   = $script:WinKitColorMap.Cyan
            MenuItem  = $script:WinKitColorMap.White
            Status    = $script:WinKitColorMap.Yellow
            Error     = $script:WinKitColorMap.Red
            Prompt    = $script:WinKitColorMap.White
            Separator = $script:WinKitColorMap.DarkGray
            Highlight = $script:WinKitColorMap.Cyan
            Success   = $script:WinKitColorMap.Green
            Warning   = $script:WinKitColorMap.Yellow
            Info      = $script:WinKitColorMap.White
            Debug     = $script:WinKitColorMap.DarkGray
        }

        highcontrast = @{
            Header    = $script:WinKitColorMap.White
            Section   = $script:WinKitColorMap.White
            MenuItem  = $script:WinKitColorMap.White
            Status    = $script:WinKitColorMap.Yellow
            Error     = $script:WinKitColorMap.Red
            Prompt    = $script:WinKitColorMap.White
            Separator = $script:WinKitColorMap.White
            Highlight = $script:WinKitColorMap.White
            Success   = $script:WinKitColorMap.White
            Warning   = $script:WinKitColorMap.Yellow
            Info      = $script:WinKitColorMap.White
            Debug     = $script:WinKitColorMap.White
        }

        minimal = @{
            Header    = $script:WinKitColorMap.White
            Section   = $script:WinKitColorMap.Gray
            MenuItem  = $script:WinKitColorMap.White
            Status    = $script:WinKitColorMap.Gray
            Error     = $script:WinKitColorMap.Gray
            Prompt    = $script:WinKitColorMap.White
            Separator = $script:WinKitColorMap.DarkGray
            Highlight = $script:WinKitColorMap.White
            Success   = $script:WinKitColorMap.Gray
            Warning   = $script:WinKitColorMap.Gray
            Info      = $script:WinKitColorMap.White
            Debug     = $script:WinKitColorMap.DarkGray
        }
    }

    if (-not $themes.ContainsKey($ColorScheme)) {
        $ColorScheme = 'default'
    }

    $script:WinKitTheme = $themes[$ColorScheme]

    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log -Level INFO -Message "Theme initialized: $ColorScheme" -Silent $true
    }

    return $script:WinKitTheme
}

# =========================================================
# THEME ACCESS
# =========================================================
function Get-Theme {
    if (-not $script:WinKitTheme) {
        Initialize-Theme | Out-Null
    }
    return $script:WinKitTheme
}

function Get-ThemeColor {
    param(
        [ValidateSet(
            'Header','Section','MenuItem','Status','Error',
            'Prompt','Separator','Highlight','Success',
            'Warning','Info','Debug'
        )]
        [string]$Component
    )

    $theme = Get-Theme
    if ($theme.ContainsKey($Component)) {
        return $theme[$Component]
    }

    return $script:WinKitColorMap.White
}

# =========================================================
# OUTPUT PRIMITIVES
# =========================================================
function Write-Colored {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$Text,

        [string]$Style = 'MenuItem',

        [switch]$NoNewLine,
        [switch]$Center,
        [switch]$NoColor
    )

    $theme = Get-Theme
    if (-not $theme.ContainsKey($Style)) {
        $Style = 'MenuItem'
    }

    $color = $theme[$Style]
    $fg = $Host.UI.RawUI.ForegroundColor
    $bg = $Host.UI.RawUI.BackgroundColor

    if ($Center) {
        $width = $Host.UI.RawUI.WindowSize.Width
        if ($width -gt 0) {
            $pad = [math]::Max(0, [math]::Floor(($width - $Text.Length) / 2))
            $Text = (' ' * $pad) + $Text
        }
    }

    if (-not $NoColor) {
        try { $Host.UI.RawUI.ForegroundColor = $color } catch {}
    }

    if ($NoNewLine) {
        Write-Host $Text -NoNewline
    } else {
        Write-Host $Text
    }

    $Host.UI.RawUI.ForegroundColor = $fg
    $Host.UI.RawUI.BackgroundColor = $bg
}

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('info','success','warning','error','debug')]
        [string]$Type = 'info',
        [switch]$NoNewLine
    )

    $map = @{
        info    = 'Status'
        success = 'Success'
        warning = 'Warning'
        error   = 'Error'
        debug   = 'Debug'
    }

    Write-Colored $Message -Style $map[$Type] -NoNewLine:$NoNewLine
}

function Write-Separator {
    param(
        [string]$Char = '-',
        [int]$Length = 0,
        [string]$Style = 'Separator'
    )

    if ($Length -le 0) {
        $Length = $Host.UI.RawUI.WindowSize.Width
        if ($Length -le 0) { $Length = 120 }
    }

    Write-Colored ($Char * $Length) -Style $Style
}

# =========================================================
# FORMATTERS (ASCII ONLY)
# =========================================================
function Format-Box {
    param(
        [string]$Text,
        [string]$Style = 'MenuItem',
        [int]$Width = 80
    )

    $top = '+' + ('-' * ($Width - 2)) + '+'
    $bot = $top

    Write-Colored $top -Style $Style

    foreach ($line in ($Text -split "`n")) {
        if ($line.Length -gt ($Width - 4)) {
            $line = $line.Substring(0, $Width - 7) + '...'
        }
        $pad = $Width - $line.Length - 3
        Write-Colored ("| $line" + (' ' * $pad) + '|') -Style $Style
    }

    Write-Colored $bot -Style $Style
}

function Format-Table {
    param(
        [hashtable]$Data,
        [int]$KeyWidth = 20,
        [int]$ValueWidth = 60
    )

    foreach ($k in $Data.Keys) {
        $key = $k.PadRight($KeyWidth)
        $val = [string]$Data[$k]

        if ($val.Length -gt $ValueWidth) {
            $val = $val.Substring(0, $ValueWidth - 3) + '...'
        }

        Write-Colored "$key : " -Style Section -NoNewLine
        Write-Colored $val -Style MenuItem
    }
}

# =========================================================
# SELF TEST (DEV ONLY)
# =========================================================
function Test-Theme {
    param([string]$ColorScheme = 'default')

    Clear-Host
    Initialize-Theme -ColorScheme $ColorScheme | Out-Null

    Write-Colored "WinKit Theme Test [$ColorScheme]" -Style Header -Center
    Write-Separator -Char '='
    Write-Host ""

    'Header','Section','MenuItem','Status','Error','Prompt',
    'Separator','Success','Warning','Info','Debug' |
    ForEach-Object {
        Write-Colored "$_ style preview" -Style $_
    }

    Write-Host ""
    Write-Status "Info message" -Type info
    Write-Status "Success message" -Type success
    Write-Status "Warning message" -Type warning
    Write-Status "Error message" -Type error
}
