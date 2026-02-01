# ==========================================
# WinKit Feature: Clean System
# ==========================================

function Start-CleanSystem {

    Write-Host ""
    Write-Host "CLEAN SYSTEM" -ForegroundColor Cyan
    Write-Host "-------------------------------------"

    Write-Host "[1] Clean TEMP (User + Windows)"
    Write-Host "[2] Clean Windows Update Cache"
    Write-Host "[3] Clean Prefetch"
    Write-Host "[4] Clean Event Logs (Basic)"
    Write-Host "[5] Run ALL (Recommended)"
    Write-Host "[0] Back"
    Write-Host ""

    $choice = Read-Host "Select option"

    switch ($choice) {
        "1" { Clean-Temp }
        "2" { Clean-WindowsUpdate }
        "3" { Clean-Prefetch }
        "4" { Clean-EventLogs }
        "5" {
            if (-not (Confirm-Action "Run FULL Clean System")) { return }
            Clean-Temp
            Clean-WindowsUpdate
            Clean-Prefetch
            Clean-EventLogs
            Write-Host "Full system clean completed." -ForegroundColor Green
            Write-Log "CleanSystem: Full clean completed"
        }
        "0" { return }
        default {
            Write-Host "Invalid selection." -ForegroundColor Red
        }
    }
}

# -----------------------------
# CONFIRM
# -----------------------------
function Confirm-Action {
    param($Message)
    Write-Host ""
    $confirm = Read-Host "$Message ? (y/n)"
    return ($confirm -eq "y")
}

# -----------------------------
# CLEAN TEMP
# -----------------------------
function Clean-Temp {

    if (-not (Confirm-Action "Clean TEMP folders")) { return }

    Write-Host "Cleaning TEMP folders..." -ForegroundColor Cyan

    $paths = @(
        "$env:TEMP\*",
        "C:\Windows\Temp\*"
    )

    foreach ($path in $paths) {
        try {
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {}
    }

    Write-Host "TEMP cleaned." -ForegroundColor Green
    Write-Log "CleanSystem: TEMP cleaned"
}

# -----------------------------
# CLEAN WINDOWS UPDATE CACHE
# -----------------------------
function Clean-WindowsUpdate {

    if (-not (Confirm-Action "Clean Windows Update cache")) { return }

    Write-Host "Stopping Windows Update service..." -ForegroundColor Cyan
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service bits -Force -ErrorAction SilentlyContinue

    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue

    Start-Service wuauserv -ErrorAction SilentlyContinue
    Start-Service bits -ErrorAction SilentlyContinue

    Write-Host "Windows Update cache cleaned." -ForegroundColor Green
    Write-Log "CleanSystem: Windows Update cache cleaned"
}

# -----------------------------
# CLEAN PREFETCH
# -----------------------------
function Clean-Prefetch {

    if (-not (Confirm-Action "Clean Prefetch")) { return }

    Write-Host "Cleaning Prefetch..." -ForegroundColor Cyan
    Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Prefetch cleaned." -ForegroundColor Green
    Write-Log "CleanSystem: Prefetch cleaned"
}

# -----------------------------
# CLEAN EVENT LOGS (BASIC)
# -----------------------------
function Clean-EventLogs {

    if (-not (Confirm-Action "Clean basic Event Logs")) { return }

    Write-Host "Cleaning Event Logs..." -ForegroundColor Cyan

    wevtutil el | ForEach-Object {
        try {
            wevtutil cl $_
        }
        catch {}
    }

    Write-Host "Event Logs cleaned." -ForegroundColor Green
    Write-Log "CleanSystem: Event logs cleaned"
}
