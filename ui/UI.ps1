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
        
        # Each info on its own line with left padding
        Write-Padded "OS:      $($sysInfo.OS) Build $($sysInfo.Build) ($($sysInfo.Arch))" -Color Gray
        Write-Padded "PS:      $($sysInfo.PSVersion)" -Color Gray
        Write-Padded "Admin:   $($sysInfo.Admin)" -Color $(if ($sysInfo.Admin -eq "YES") { "Green" } else { "Red" })
        Write-Padded "Mode:    $($sysInfo.Mode)" -Color $(if ($sysInfo.Mode -eq "Online") { "Green" } else { "Yellow" })
        Write-Padded ""  # Empty line
        
        Write-Padded "User:    $($sysInfo.User)" -Color Gray
        Write-Padded "PC:      $($sysInfo.Computer)" -Color Gray
        Write-Padded "TPM:     $($sysInfo.TPM)" -Color $(if ($sysInfo.TPM -eq "YES") { "Green" } else { "Gray" })
        Write-Padded ""  # Empty line
        
        Write-Padded "Timezone:$($sysInfo.TimeZone)" -Color Gray
        Write-Padded ""  # Empty line
        
        # Disk information - compact, 2 per line if multiple
        if ($sysInfo.Disks.Count -gt 0) {
            Write-Padded "Disks:" -Color Gray
            $diskLines = @()
            $currentLine = ""
            
            foreach ($disk in $sysInfo.Disks) {
                $color = if ($disk.Percentage -gt 90) { "Red" } elseif ($disk.Percentage -gt 75) { "Yellow" } else { "Green" }
                $diskText = "  $($disk.Name): $($disk.FreeGB)GB free ($($disk.Percentage)% used)"
                
                if ($currentLine.Length + $diskText.Length -lt 60 -and $sysInfo.Disks.IndexOf($disk) -ne $sysInfo.Disks.Count - 1) {
                    $currentLine += $diskText + " | "
                }
                else {
                    if ($currentLine) {
                        $diskLines += $currentLine.TrimEnd(' | ')
                    }
                    $currentLine = $diskText + " | "
                }
            }
            
            if ($currentLine) {
                $diskLines += $currentLine.TrimEnd(' | ')
            }
            
            foreach ($line in $diskLines) {
                Write-Padded $line -Color Gray
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
        [int]$IndentLevel = 1
    )
    
    $indent = $global:WK_PADDING * $IndentLevel
    Write-Host "$indent$Text" -ForegroundColor $Color
}

# Export functions
Export-ModuleMember -Function Initialize-UI, Show-SystemInfoBar, Write-Padded
