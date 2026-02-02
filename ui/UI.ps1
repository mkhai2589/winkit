# Global padding settings
$global:WK_PADDING = "  "
$global:WK_COLUMN_WIDTH = 38
$global:WK_MENU_WIDTH = 76

function Initialize-UI {
    Clear-Host
    Show-Header
    Show-SystemInfoBar
}

function Show-Header {
    $logoPath = Join-Path $PSScriptRoot "Logo.ps1"
    
    if (Test-Path $logoPath) {
        try {
            . $logoPath
            Show-Logo
        }
        catch {
            Write-Padded "================================================================" -Color Cyan
            Write-Padded "  W I N K I T                                                   " -Color White
            Write-Padded "  Windows Optimization Toolkit                                  " -Color Gray
            Write-Padded "                                                                " -Color Cyan
            Write-Padded "  Author: Minh Khai | 0333 090 930                              " -Color Gray
            Write-Padded "================================================================" -Color Cyan
            Write-Host ""
        }
    }
    else {
        Write-Padded "================================================================" -Color Cyan
        Write-Padded "  W I N K I T                                                   " -Color White
        Write-Padded "  Windows Optimization Toolkit                                  " -Color Gray
        Write-Padded "                                                                " -Color Cyan
        Write-Padded "  Author: Minh Khai | 0333 090 930                              " -Color Gray
        Write-Padded "================================================================" -Color Cyan
        Write-Host ""
    }
}

function Show-SystemInfoBar {
    try {
        $sysInfo = Get-WKSystemInfo
        
        Write-Padded ""
        Write-Padded "SYSTEM STATUS" -Color White
        Write-Padded ("-" * $global:WK_MENU_WIDTH) -Color DarkGray
        Write-Padded ""
        
        $line1 = "OS: $($sysInfo.OS) | Shell: PowerShell $($sysInfo.PSVersion) | "
        $line1 += "Privilege: $($sysInfo.Admin) | Mode: $($sysInfo.Mode)"
        
        Write-Padded $line1 -Color Gray
        Write-Padded ""
        
        $line2 = "User: $($sysInfo.User) | Computer: $($sysInfo.Computer) | "
        $line2 += "TPM: $($sysInfo.TPM) | Timezone: $($sysInfo.TimeZone)"
        
        Write-Padded $line2 -Color Gray
        Write-Padded ""
        
        if ($sysInfo.Disks.Count -gt 0) {
            $diskText = "Disk: "
            $diskItems = @()
            
            foreach ($disk in $sysInfo.Disks) {
                $diskItems += "$($disk.Name): $($disk.FreeGB)GB free ($($disk.Percentage)% used)"
            }
            
            $diskLine = $diskText + ($diskItems -join " | ")
            
            if ($diskLine.Length -gt $global:WK_MENU_WIDTH) {
                Write-Padded $diskText -Color Gray -NoNewLine
                $currentLine = ""
                
                foreach ($item in $diskItems) {
                    if ($currentLine.Length + $item.Length -gt ($global:WK_MENU_WIDTH - 6)) {
                        Write-Host ""
                        Write-Padded "      " -Color Gray -NoNewLine
                        $currentLine = $item + " | "
                    }
                    else {
                        $currentLine += $item + " | "
                    }
                }
                
                if ($currentLine.EndsWith(" | ")) {
                    $currentLine = $currentLine.Substring(0, $currentLine.Length - 3)
                }
                
                Write-Host $currentLine -ForegroundColor Gray
            }
            else {
                Write-Padded $diskLine -Color Gray
            }
        }
        
        Write-Padded ""
        Write-Padded ("-" * $global:WK_MENU_WIDTH) -Color DarkGray
        Write-Padded ""
        
    }
    catch {
        Write-Padded "System information unavailable" -Color Red
        Write-Padded ""
    }
}

function Write-Padded {
    param(
        [string]$Text,
        [string]$Color = "White",
        [int]$IndentLevel = 1,
        [switch]$NoNewLine
    )
    
    $indent = $global:WK_PADDING * $IndentLevel
    
    if ($Text -eq "") {
        if (-not $NoNewLine) {
            Write-Host ""
        }
    }
    else {
        if ($NoNewLine) {
            Write-Host "$indent$Text" -ForegroundColor $Color -NoNewline
        }
        else {
            Write-Host "$indent$Text" -ForegroundColor $Color
        }
    }
}

function Write-Section {
    param(
        [string]$Text,
        [string]$Color = "Green"
    )
    
    Write-Padded "[ $Text ]" -Color $Color
    Write-Padded ""
}

function Write-Separator {
    Write-Padded ("-" * $global:WK_MENU_WIDTH) -Color DarkGray
    Write-Padded ""
}
