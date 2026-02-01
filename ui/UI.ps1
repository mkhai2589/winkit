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
        Write-Host ""
    }
    else {
        Write-Host "------------------------------------------" -ForegroundColor Cyan
        Write-Host "              W I N K I T                 " -ForegroundColor White
        Write-Host "    Windows Optimization Toolkit          " -ForegroundColor Gray
        Write-Host "------------------------------------------" -ForegroundColor Cyan
        Write-Host ""
    }
}

function Show-SystemInfoBar {
    try {
        $sysInfo = Get-WKSystemInfo
        
        Write-Host "OS: $($sysInfo.OS) Build $($sysInfo.Build) | " -NoNewline -ForegroundColor Cyan
        Write-Host "PS: $($sysInfo.PSVersion) | " -NoNewline -ForegroundColor Gray
        Write-Host "Admin: $($sysInfo.Admin) | " -NoNewline -ForegroundColor $(if ($sysInfo.Admin -eq "YES") { "Green" } else { "Red" })
        Write-Host "Mode: $($sysInfo.Mode)" -ForegroundColor $(if ($sysInfo.Mode -eq "Online") { "Green" } else { "Yellow" })
        
        Write-Host "USER: $($sysInfo.User) | " -NoNewline -ForegroundColor Cyan
        Write-Host "COMPUTER: $($sysInfo.Computer) | " -NoNewline -ForegroundColor Gray
        Write-Host "TPM: $($sysInfo.TPM)" -ForegroundColor $(if ($sysInfo.TPM -eq "YES") { "Green" } else { "Gray" })
        
        Write-Host "TIME ZONE: $($sysInfo.TimeZone)" -ForegroundColor Cyan
        Write-Host "DISKS: $($sysInfo.Disks)" -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
    }
    catch {
        Write-Host "System info unavailable" -ForegroundColor Red
    }
}

function Show-MainMenuTitle {
    Write-Host "[ MAIN MENU ]" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Footer {
    param([string]$Status = "Ready")
    
    Write-Host ""
    Write-Host "------------------------------------------" -ForegroundColor DarkGray
    Write-Host "[INFO] $Status | " -NoNewline -ForegroundColor Cyan
    Write-Host "Log: $global:WK_LOG" -ForegroundColor Gray
    Write-Host ""
}
