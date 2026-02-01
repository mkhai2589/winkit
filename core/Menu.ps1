# ================================
# WinKit Menu
# ================================

function Show-WinKitMenu {

    foreach ($m in $Global:WinKitModules) {
        Write-Host ("[{0}] {1}" -f $m.Id, $m.Name) -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "Type option: " -NoNewline -ForegroundColor Green
}

function Invoke-WinKitSelection {

    $choice = Read-Host

    if (-not ($choice -match '^\d+$')) {
        Write-Host "Invalid input!" -ForegroundColor Red
        Start-Sleep 1
        return
    }

    $module = $Global:WinKitModules | Where-Object { $_.Id -eq [int]$choice }

    if (-not $module) {
        Write-Host "Option not found!" -ForegroundColor Red
        Start-Sleep 1
        return
    }

    # Admin check
    if ($module.RequireAdmin) {
        $isAdmin = ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        if (-not $isAdmin) {
            Write-Host "This module requires Administrator!" -ForegroundColor Red
            Pause
            return
        }
    }

    # OS check
    if ($module.Support) {
        $os = (Get-CimInstance Win32_OperatingSystem).Caption
        $supported = $false

        foreach ($s in $module.Support) {
            if ($os -match $s) {
                $supported = $true
                break
            }
        }

        if (-not $supported) {
            Write-Host "This module does not support your OS!" -ForegroundColor Red
            Pause
            return
        }
    }

    # Execute
    Clear-Host
    Write-Host "Running: $($module.Name)" -ForegroundColor Yellow
    Write-Host "--------------------------------------" -ForegroundColor DarkGray

    . $module.Entry

    Write-Host ""
    Write-Host "Done." -ForegroundColor Green
    Pause
}
