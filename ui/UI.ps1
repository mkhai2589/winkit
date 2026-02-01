function Initialize-UI {
    Clear-Host
    Show-Header
    Write-Host ""  # Thêm dòng trống
    Show-SystemInfoBar
}

function Show-Header {
    # Cố gắng load logo từ file trước
    $logoPath = Join-Path $PSScriptRoot "logo.ps1"
    
    if (Test-Path $logoPath) {
        try {
            . $logoPath
            Show-Logo
        }
        catch {
            Show-FallbackLogo
        }
    }
    else {
        # Fallback nếu không tìm thấy file
        Show-FallbackLogo
    }
}

function Show-SystemInfoBar {
    try {
        $sysInfo = Get-WKSystemInfo
        
        Write-Host ""
        Write-Host "SYSTEM STATUS" -ForegroundColor White
        Write-Host "-------------" -ForegroundColor DarkGray
        
        # Line 1: OS + PS + Admin + Network
        Write-Host "OS: $($sysInfo.OS) Build $($sysInfo.Build) | " -NoNewline -ForegroundColor Gray
        Write-Host "PS: $($sysInfo.PSVersion) | " -NoNewline -ForegroundColor Gray
        Write-Host "Admin: $($sysInfo.Admin) | " -NoNewline -ForegroundColor $(if ($sysInfo.Admin -eq "YES") { "Green" } else { "Red" })
        Write-Host "Mode: $($sysInfo.Mode)" -ForegroundColor $(if ($sysInfo.Mode -eq "Online") { "Green" } else { "Yellow" })
        
        Write-Host ""  # Thêm dòng trống
        
        # Line 2: User + Computer + TPM
        Write-Host "USER: $($sysInfo.User) | " -NoNewline -ForegroundColor Gray
        Write-Host "COMPUTER: $($sysInfo.Computer) | " -NoNewline -ForegroundColor Gray
        Write-Host "TPM: $($sysInfo.TPM)" -ForegroundColor $(if ($sysInfo.TPM -eq "YES") { "Green" } else { "Gray" })
        
        # Line 3: Time Zone
        Write-Host "TIME ZONE: $($sysInfo.TimeZone)" -ForegroundColor Gray
        
        Write-Host ""  # Thêm dòng trống
        
        # Line 4+: Disks - compact display (max 2 per line)
        if ($sysInfo.Disks.Count -gt 0) {
            Write-Host "DISKS: " -NoNewline -ForegroundColor Gray
            $diskCount = 0
            $lineBreaks = 0
            foreach ($disk in $sysInfo.Disks) {
                if ($diskCount -gt 0) {
                    if ($diskCount % 2 -eq 0) {
                        Write-Host ""
                        Write-Host "       " -NoNewline
                        $lineBreaks++
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
        Write-Host ""  # Thêm dòng trống
        
    }
    catch {
        Write-Host "System information unavailable" -ForegroundColor Red
        Write-Host ""
    }
}
