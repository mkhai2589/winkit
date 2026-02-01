# =========================================================
# WinKit - Theme.ps1
# Console color & style system
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -------------------------
# THEME COLORS
# -------------------------
$Global:WinKitTheme = @{
    Title       = "Cyan"
    Accent      = "DarkCyan"
    Success     = "Green"
    Warning     = "Yellow"
    Error       = "Red"
    Info        = "Gray"
    MenuIndex   = "Cyan"
    MenuText    = "White"
    Description = "DarkGray"
}

# -------------------------
# CORE OUTPUT HELPERS
# -------------------------
function Write-Colored {
    param (
        [Parameter(Mandatory)]
        [string]$Text,

        [string]$Color = "White",

        [switch]$NoNewline
    )

    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    }
    else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Write-Title {
    param ([string]$Text)
    Write-Colored $Text $Global:WinKitTheme.Title
}

function Write-Accent {
    param ([string]$Text)
    Write-Colored $Text $Global:WinKitTheme.Accent
}

function Write-Success {
    param ([string]$Text)
    Write-Colored "[+] $Text" $Global:WinKitTheme.Success
}

function Write-Warn {
    param ([string]$Text)
    Write-Colored "[!] $Text" $Global:WinKitTheme.Warning
}

function Write-ErrorX {
    param ([string]$Text)
    Write-Colored "[x] $Text" $Global:WinKitTheme.Error
}

function Write-Info {
    param ([string]$Text)
    Write-Colored "[i] $Text" $Global:WinKitTheme.Info
}

# -------------------------
# MENU RENDERING
# -------------------------
function Write-MenuItem {
    param (
        [Parameter(Mandatory)]
        [int]$Index,

        [Parameter(Mandatory)]
        [string]$Text,

        [string]$Description
    )

    Write-Colored ("[{0}] " -f $Index) $Global:WinKitTheme.MenuIndex -NoNewline
    Write-Colored $Text $Global:WinKitTheme.MenuText

    if ($Description) {
        Write-Colored ("    {0}" -f $Description) $Global:WinKitTheme.Description
    }
}

# -------------------------
# INPUT / FLOW
# -------------------------
function Read-Choice {
    param (
        [string]$Prompt = "Select option"
    )

    Write-Colored ("`n> {0}: " -f $Prompt) $Global:WinKitTheme.Accent -NoNewline
    $input = Read-Host

    if ($input -match '^\d+$') {
        return [int]$input
    }

    return -1
}

function Pause-Console {
    Write-Colored "`nPress Enter to continue..." $Global:WinKitTheme.Info
    Read-Host | Out-Null
}

function Exit-WinKit {
    Write-Colored "`nExiting WinKit..." $Global:WinKitTheme.Accent
    Start-Sleep -Milliseconds 500
    exit
}
