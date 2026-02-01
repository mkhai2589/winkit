function Initialize-UI {
    Clear-Host
    Show-Header
    Show-SystemInfoBar
}

function Show-Header {
    $asciiPath = Join-Path $global:WK_ROOT "assets\ascii.txt"
    if (Test-Path $asciiPath) {
        $asciiLines = Get-Content $asciiPath
        foreach ($line in $asciiLines) {
            Write-Host $line -ForegroundColor Cyan
        }
        Write-Host ""
    }
    else {
        Write-Host "------------------------------------------" -ForegroundColor Cyan
        Write-Host "              W I N K I T                 " -ForegroundColor White
        WriteHost "    Windows Optimization Toolkit          " -ForegroundColor Gray
        Write-Host "------------------------------------------" -ForegroundColor Cyan
        Write-Host ""
    }
}

function Show-SystemInfoBar {
    try {
        $sysInfo = Get-WKSystemInfo
        
        # Line 1: OS + PS + Admin + Network
        Write-Host "OS: $($sysInfo.OS) Build $($sysInfo.Build) ($($sysInfo.Arch)) | " -NoNewline -ForegroundColor Cyan
        Write-Host "PS: $($sysInfo.PSVersion) | " -NoNewline -ForegroundColor Gray
        Write-Host "Admin: $($sysInfo.Admin) | " -NoNewline -ForegroundColor $(if ($sysInfo.Admin -eq "YES") { "Green" } else { "Red" })
        Write-Host "Mode: $($sysInfo.Mode)" -ForegroundColor $(if ($sysInfo.Mode -eq "Online") { "Green" } else { "Yellow" })
        
        # Line 2: User + Computer + TPM
        Write-Host "USER: $($sysInfo.User) | " -NoNewline -ForegroundColor Cyan
        Write-Host "COMPUTER: $($sysInfo.Computer) | " -NoNewline -ForegroundColor Gray
        Write-Host "TPM: $($sysInfo.TPM)" -ForegroundColor $(if ($sysInfo.TPM -eq "YES") { "Green" } else { "Gray" })
        
        # Line 3: Time Zone with UTC offset
        Write-Host "TIME ZONE: $($sysInfo.TimeZone)" -ForegroundColor Cyan
        
        # Line 4-?: Disks with detailed info (each disk on separate line)
        Write-Host "DISKS:" -ForegroundColor Cyan
        if ($sysInfo.Disks.Count -gt 0) {
            foreach ($disk in $sysInfo.Disks) {
                $color = if ($disk.Percentage -gt 90) { "Red" } elseif ($disk.Percentage -gt 75) { "Yellow" } else { "Green" }
                Write-Host "  $($disk.Name): " -NoNewline -ForegroundColor Gray
                Write-Host "$($disk.FreeGB) GB free" -NoNewline -ForegroundColor White
                Write-Host " / " -NoNewline -ForegroundColor DarkGray
                Write-Host "$($disk.UsedGB) GB used" -NoNewline -ForegroundColor White
                Write-Host " / " -NoNewline -ForegroundColor DarkGray
                Write-Host "$($disk.TotalGB) GB total" -NoNewline -ForegroundColor White
                Write-Host " ($($disk.Percentage)% used)" -ForegroundColor $color
            }
        } else {
            Write-Host "  No disk information available" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
    }
    catch {
        Write-Host "System information unavailable" -ForegroundColor Red
        Write-Host ""
    }
}

function Show-MainMenuTitle {
    Write-Host "[ MAIN MENU ]" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Footer {
    param([string]$Status = "Ready")
    
    try {
        $versionPath = Join-Path $global:WK_ROOT "version.json"
        if (Test-Path $versionPath) {
            $version = Get-Content $versionPath -Raw | ConvertFrom-Json
            $versionInfo = "v$($version.version) ($($version.channel))"
        } else {
            $versionInfo = "v1.0.0"
        }
        
        $sysInfo = Get-WKSystemInfo
        
        Write-Host ""
        Write-Host "------------------------------------------" -ForegroundColor DarkGray
        Write-Host "[INFO] $Status | " -NoNewline -ForegroundColor Cyan
        Write-Host "Version: $versionInfo | " -NoNewline -ForegroundColor Gray
        Write-Host "Mode: $($sysInfo.Mode) | " -NoNewline -ForegroundColor $(if ($sysInfo.Mode -eq "Online") { "Green" } else { "Yellow" })
        Write-Host "Log: $global:WK_LOG" -ForegroundColor Gray
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host "------------------------------------------" -ForegroundColor DarkGray
        Write-Host "[INFO] $Status | Log: $global:WK_LOG" -ForegroundColor Cyan
        Write-Host ""
    }
}
