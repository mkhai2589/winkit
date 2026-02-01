# =========================================================
# WinKit - Utils.ps1
# Shared utility functions for whole system
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -------------------------
# GLOBAL STATE
# -------------------------
if (-not $Global:WinKit) {
    $Global:WinKit = @{
        Version = "0.1.0"
        Root    = Split-Path -Parent $PSScriptRoot
        Logs    = @()
    }
}

# -------------------------
# COLOR OUTPUT
# -------------------------
function Write-Color {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [switch]$NoNewLine
    )

    $oldColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color

    if ($NoNewLine) {
        Write-Host $Text -NoNewline
    } else {
        Write-Host $Text
    }

    $Host.UI.RawUI.ForegroundColor = $oldColor
}

function Write-Info    { Write-Color "[*] $($args[0])" Cyan }
function Write-Success { Write-Color "[+] $($args[0])" Green }
function Write-Warn    { Write-Color "[!] $($args[0])" Yellow }
function Write-ErrorX  { Write-Color "[x] $($args[0])" Red }

# -------------------------
# USER INPUT
# -------------------------
function Read-Choice {
    param(
        [string]$Prompt = "Select",
        [int[]]$ValidChoices
    )

    while ($true) {
        Write-Color "$Prompt: " White -NoNewLine
        $input = Read-Host

        if ($input -match '^\d+$') {
            $choice = [int]$input
            if (-not $ValidChoices -or $ValidChoices -contains $choice) {
                return $choice
            }
        }

        Write-Warn "Invalid choice"
    }
}

function Confirm-Action {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Warn $Message
    Write-Color "Continue? (Y/N): " Yellow -NoNewLine
    $answer = Read-Host

    return ($answer -match '^(y|yes)$')
}

# -------------------------
# FLOW CONTROL
# -------------------------
function Pause-Console {
    Write-Color ""
    Write-Color "Press ENTER to continue..." DarkGray
    Read-Host | Out-Null
}

function Exit-WinKit {
    Write-Color ""
    Write-Info "Exit WinKit"
    exit 0
}

# -------------------------
# SAFE EXECUTION
# -------------------------
function Invoke-Safe {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Script,

        [string]$ActionName = "Action"
    )

    try {
        Write-Info "$ActionName started"
        & $Script
        Write-Success "$ActionName completed"
        Add-Log "$ActionName completed"
    }
    catch {
        Write-ErrorX "$ActionName failed"
        Write-ErrorX $_.Exception.Message
        Add-Log "$ActionName failed: $($_.Exception.Message)"
    }
}

# -------------------------
# LOGGING (IN-MEMORY)
# -------------------------
function Add-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    $Global:WinKit.Logs += @{
        Time    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Message = $Message
    }
}

function Show-Logs {
    if ($Global:WinKit.Logs.Count -eq 0) {
        Write-Info "No logs available"
        return
    }

    Write-Color "---- LOGS ----" DarkGray
    foreach ($log in $Global:WinKit.Logs) {
        Write-Color "[$($log.Time)] $($log.Message)" DarkGray
    }
}

# -------------------------
# FILE & PATH HELPERS
# -------------------------
function Resolve-WinKitPath {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath
    )

    return Join-Path $Global:WinKit.Root $RelativePath
}

function Test-WinKitFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Required file not found: $Path"
    }
}

# -------------------------
# CLEAN EXIT HANDLER
# -------------------------
Register-EngineEvent PowerShell.Exiting -Action {
    # placeholder for future persistent logging
}
