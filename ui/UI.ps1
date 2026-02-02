# Global padding settings
$global:WK_PADDING = "  "  # 2 spaces
$global:WK_COLUMN_WIDTH = 35

function Initialize-UI {
    Clear-Host
    Show-Header
    Show-SystemInfoBar
}

function Show-Header {
    $logoPath = Join-Path $PSScriptRoot "logo.ps1"
    
    if (Test-Path $logoPath) {
        try {
            . $logoPath
            Show-Logo
        }
        catch {
            Write-Padded "------------------------------------------" -Color Cyan
            Write-Padded "              W I N K I T                 " -Color White
            Write-Padded "    Windows Optimization Toolkit          " -Color Gray
            Write-Padded "------------------------------------------" -Color Cyan
        }
    }
    else {
        Write-Padded "------------------------------------------" -Color Cyan
        Write-Padded "              W I N K I T                 " -Color White
        Write-Padded "    Windows Optimization Toolkit          " -Color Gray
        Write-Padded "------------------------------------------" -Color Cyan
    }
}

function Show-SystemInfoBar {
    try {
        $sysInfo = Get-WKSystemInfo
        
        Write-Padded ""  # Empty line
        Write-Padded "SYSTEM STATUS" -Color White
        Write-Padded "-------------" -Color DarkGray
        Write-Padded ""  # Empty line
        
        # Line 1: OS + PowerShell + Admin + Network
        $osText = "$($sysInfo.OS) | "
        $psText = "PowerShell $($sysInfo.PSVersion) | "
        $adminText = if ($sysInfo.Admin -eq "YES") { "Admin | " } else { "User | " }
        $modeText = if ($sysInfo.Mode -eq "Online") { "Online" } else { "Offline" }
        
        Write-Padded $($osText + $psText + $adminText + $modeText) -Color Gray
        Write-Padded ""  # Empty line
        
        # Line 2: User + TPM + Timezone
        $userText = "User: $($sysInfo.User) | "
        $tpmText = "TPM: $($sysInfo.TPM) | "
        $tzText = "Timezone: $($sysInfo.TimeZone)"
        
        Write-Padded $($userText + $tpmText + $tzText) -Color Gray
        Write-Padded ""  # Empty line
        
        # Line 3: Disk info (all on one line if possible)
        if ($sysInfo.Disks.Count -gt 0) {
            $diskText = "Disk: "
            $diskItems = @()
            
            # Create a copy to avoid collection modification
            $disksCopy = @($sysInfo.Disks)
            
            foreach ($disk in $disksCopy) {
                $color = if ($disk.Percentage -gt 90) { "Red" } elseif ($disk.Percentage -gt 75) { "Yellow" } else { "Green" }
                $diskItems += "$($disk.Name): $($disk.FreeGB)GB free ($($disk.Percentage)% used)"
            }
            
            $diskLine = $diskText + ($diskItems -join " | ")
            
            # If line is too long, break it
            if ($diskLine.Length -gt 70) {
                Write-Padded $diskText -Color Gray -NoNewLine
                $currentLine = ""
                
                foreach ($item in $diskItems) {
                    if ($currentLine.Length + $item.Length -gt 65) {
                        Write-Host ""
                        Write-Padded "      " -Color Gray -NoNewLine
                        $currentLine = $item + " | "
                    } else {
                        $currentLine += $item + " | "
                    }
                }
                
                # Remove last separator
                if ($currentLine.EndsWith(" | ")) {
                    $currentLine = $currentLine.Substring(0, $currentLine.Length - 3)
                }
                
                Write-Host $currentLine -ForegroundColor Gray
            } else {
                Write-Padded $diskLine -Color Gray
            }
        }
        
        Write-Padded ""  # Empty line
        Write-Padded "------------------------------------------" -Color DarkGray
        Write-Padded ""  # Empty line
        
    }
    catch {
        Write-Padded "System information unavailable" -Color Red
        Write-Padded ""  # Empty line
    }
}

# Helper function for consistent padding
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
    } else {
        if ($NoNewLine) {
            Write-Host "$indent$Text" -ForegroundColor $Color -NoNewline
        } else {
            Write-Host "$indent$Text" -ForegroundColor $Color
        }
    }
}
