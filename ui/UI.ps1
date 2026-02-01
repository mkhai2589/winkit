function Initialize-UI {
    Clear-Host
    Show-Header
    Show-SystemInfoBar
}

function Show-Header {
    $asciiPath = Join-Path $global:WK_ROOT "assets\ascii.txt"
    if (Test-Path $asciiPath) {
        Get-Content $asciiPath | ForEach-Object {
            Write-Host $_ -ForegroundColor Cyan
        }
    }
    else {
        Write-Host "------------------------------------------" -ForegroundColor Cyan
        Write-Host "              W I N K I T                 " -ForegroundColor White
        Write-Host "    Windows Optimization Toolkit          " -ForegroundColor Gray
        Write-Host "------------------------------------------" -ForegroundColor Cyan
    }
}

function Show-SystemInfoBar {
    try {
        $sysInfo = Get-WKSystemInfo
        
        Write-Host ""
        Write-Host "SYSTEM STATUS" -ForegroundColor Cyan
        Write-Host "-------------" -ForegroundColor DarkGray
        
        # Line 1: OS + PS + Admin + Network
        Write-Host "OS: $($sysInfo.OS) Build $($sysInfo.Build) | " -NoNewline -ForegroundColor Gray
        Write-Host "PS: $($sysInfo.PSVersion) | " -NoNewline -ForegroundColor Gray
        Write-Host "Admin: $($sysInfo.Admin) | " -NoNewline -ForegroundColor $(if ($sysInfo.Admin -eq "YES") { "Green" } else { "Red" })
        Write-Host "Mode: $($sysInfo.Mode)" -ForegroundColor $(if ($sysInfo.Mode -eq "Online") { "Green" } else { "Yellow" })
        
        # Line 2: User + Computer + TPM
        Write-Host "USER: $($sysInfo.User) | " -NoNewline -ForegroundColor Gray
        Write-Host "COMPUTER: $($sysInfo.Computer) | " -NoNewline -ForegroundColor Gray
        Write-Host "TPM: $($sysInfo.TPM)" -ForegroundColor $(if ($sysInfo.TPM -eq "YES") { "Green" } else { "Gray" })
        
        # Line 3: Time Zone
        Write-Host "TIME ZONE: $($sysInfo.TimeZone)" -ForegroundColor Gray
        
        # Line 4+: Disks - compact display (max 2 per line)
        if ($sysInfo.Disks.Count -gt 0) {
            Write-Host "DISKS: " -NoNewline -ForegroundColor Gray
            $diskCount = 0
            foreach ($disk in $sysInfo.Disks) {
                if ($diskCount -gt 0) {
                    if ($diskCount % 2 -eq 0) {
                        Write-Host ""
                        Write-Host "      " -NoNewline
                    } else {
                        Write-Host " | " -NoNewline -ForegroundColor DarkGray
                    }
                }
                
                $color = if ($disk.Percentage -gt 90) { "Red" } elseif ($disk.Percentage -gt 75) { "Yellow" } else { "Green" }
                Write-Host "$($disk.Name): $($disk.FreeGB)GB free" -NoNewline -ForegroundColor $color
                $diskCount++
            }
            Write-Host ""
        }
        
        Write-Host ""
        Write-Host "------------------------------------------" -ForegroundColor DarkGray
        
    }
    catch {
        Write-Host "System information unavailable" -ForegroundColor Red
    }
}
