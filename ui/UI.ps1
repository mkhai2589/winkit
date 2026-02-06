# =========================================================
# ui/UI.ps1
# WinKit UI Renderer
#
# RESPONSIBILITY:
# - Render header, status, menu, prompts
#
# HARD RULES:
# - DISPLAY ONLY
# - NO system checks
# - NO feature logic
# - DATA-IN → DISPLAY-OUT
# =========================================================

# =========================================================
# HEADER
# =========================================================
function Show-Header {
    [CmdletBinding()]
    param(
        [switch]$WithStatus,
        [hashtable]$StatusData
    )

    try {
        Clear-Host

        if (Get-Command Show-Logo -ErrorAction SilentlyContinue) {
            Show-Logo -Centered
        } else {
            Write-Colored "WinKit" -Style Header -Center
        }

        Write-Host ""
        Write-Separator
        Write-Host ""

        if ($WithStatus -and $StatusData) {
            Show-SystemStatus -StatusData $StatusData
            Write-Host ""
            Write-Separator
            Write-Host ""
        }

        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Level DEBUG -Message "Header rendered" -Silent $true
        }
    }
    catch {
        Clear-Host
        Write-Colored "WinKit" -Style Header
        Write-Separator
    }
}

# =========================================================
# SYSTEM STATUS (DISPLAY ONLY)
# =========================================================
function Show-SystemStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$StatusData
    )

    try {
        Write-Colored "SYSTEM STATUS" -Style Section -Center
        Write-Separator

        foreach ($line in $StatusData.Lines) {
            Write-Colored $line -Style Status
        }

        Write-Separator
    }
    catch {
        Write-Colored "SYSTEM STATUS UNAVAILABLE" -Style Error
    }
}

# =========================================================
# MENU RENDERER
# =========================================================
function Show-Menu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$MenuData
    )

    try {
        foreach ($category in $MenuData.Categories) {

            $items = $MenuData.ItemsByCategory[$category]
            if (-not $items -or $items.Count -eq 0) { continue }

            Write-Host ""
            Write-Colored "[ $category ]" -Style Section
            Write-Separator -Length 40
            Write-Host ""

            $columns = $MenuData.Columns
            if (-not $columns -or $columns -lt 1) { $columns = 2 }

            $perColumn = [math]::Ceiling($items.Count / $columns)

            $grid = for ($c = 0; $c -lt $columns; $c++) {
                $start = $c * $perColumn
                $end   = [math]::Min($start + $perColumn - 1, $items.Count - 1)
                if ($start -le $end) { ,@($items[$start..$end]) } else { ,@() }
            }

            for ($r = 0; $r -lt $perColumn; $r++) {
                $line = ""

                for ($c = 0; $c -lt $columns; $c++) {
                    if ($r -lt $grid[$c].Count) {
                        $item = $grid[$c][$r]
                        $text = "[$($item.MenuNumber)] $($item.Title)"

                        if ($c -gt 0) {
                            $pad = 40 - ($line.Length % 40)
                            if ($pad -gt 0 -and $pad -lt 40) {
                                $line += ' ' * $pad
                            }
                        }

                        $line += $text
                    }
                }

                if ($line.Trim()) {
                    Write-Colored $line -Style MenuItem
                }
            }
        }

        Write-Host ""
        Write-Separator -Length 80
        Write-Host ""
        Write-Colored "[$($MenuData.ExitNumber)] Exit" -Style MenuItem

        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Level DEBUG -Message "Menu rendered" -Silent $true
        }
    }
    catch {
        Write-Colored "MENU RENDER FAILED" -Style Error
    }
}

# =========================================================
# PROMPT
# =========================================================
function Show-Prompt {
    [CmdletBinding()]
    param(
        [string]$Message = "SELECT OPTION",
        [string]$Default = ""
    )

    $text = "$Message : "
    if ($Default) { $text += "[$Default] " }

    Write-Colored $text -Style Prompt -NoNewLine
    return Read-Host
}

# =========================================================
# STATUS BAR
# =========================================================
function Show-StatusBar {
    [CmdletBinding()]
    param(
        [string]$Message = "READY",
        [ValidateSet('info','success','warning','error')]
        [string]$Type = 'info'
    )

    $styleMap = @{
        info    = 'Status'
        success = 'Success'
        warning = 'Warning'
        error   = 'Error'
    }

    $style = $styleMap[$Type]
    $time  = Get-Date -Format "HH:mm:ss"

    Write-Separator
    Write-Colored "STATUS: $Message | $time" -Style $style
    Write-Separator
}

# =========================================================
# SAFE CLEAR
# =========================================================
function Clear-ScreenSafe {
    try {
        Clear-Host
    }
    catch {
        Write-Host "`n" * 100
    }
}
