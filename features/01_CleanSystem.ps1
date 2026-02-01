# ==========================================
# WinKit Feature: Clean System - SIMPLIFIED
# ==========================================

function Start-CleanSystem {
    Write-Host ""
    Write-Host "CLEAN SYSTEM" -ForegroundColor Cyan
    Write-Host "-------------------------------------"

    $options = @(
        "Clean TEMP Folders",
        "Clean Windows Update Cache",
        "Clean Prefetch",
        "Clean Event Logs",
        "Run All Cleanups",
        "Back to Main Menu"
    )
    
    for ($i = 0; $i -lt $options.Count; $i++) {
        Write-Host "[$($i+1)] $($options[$i])" -ForegroundColor Gray
    }
    
    Write-Host ""
    $choice = Read-Host "Select option [1-6]"
    
    switch ($choice) {
        "1" { Invoke-CleanTemp }
        "2" { Invoke-CleanWindowsUpdate }
        "3" { Invoke-CleanPrefetch }
        "4" { Invoke-CleanEventLogs }
        "5" { Invoke-CleanAll }
        "6" { return }
        default {
            Write-Host "Invalid selection" -ForegroundColor Red
            Pause-WK
            return
        }
    }
    
    Pause-WK
}

function Invoke-CleanTemp {
    if (-not (Get-WKConfirm -Message "Clean temporary files?")) { return }
    
    Write-Host "`nCleaning TEMP folders..." -ForegroundColor Cyan
    
    $paths = @(
        "$env:TEMP\*",
        "$env:WINDIR\Temp\*",
        "$env:LOCALAPPDATA\Temp\*"
    )
    
    foreach ($path in $paths) {
        try {
            if (Test-Path $path) {
                Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Host "  Warning: Could not clean $path" -ForegroundColor Yellow
        }
    }
    
    Write-Host "TEMP folders cleaned." -ForegroundColor Green
    Write-WKLog -Message "TEMP folders cleaned" -Level INFO -Feature "CleanSystem"
}

function Invoke-CleanWindowsUpdate {
    if (-not (Get-WKConfirm -Message "Clean Windows Update cache?")) { return }
    
    Write-Host "`nCleaning Windows Update cache..." -ForegroundColor Cyan
    
    try {
        # Stop services
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Stop-Service bits -Force -ErrorAction SilentlyContinue
        
        # Clean download folder
        $downloadPath = "$env:WINDIR\SoftwareDistribution\Download"
        if (Test-Path $downloadPath) {
            Remove-Item "$downloadPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Restart services
        Start-Service wuauserv -ErrorAction SilentlyContinue
        Start-Service bits -ErrorAction SilentlyContinue
        
        Write-Host "Windows Update cache cleaned." -ForegroundColor Green
        Write-WKLog -Message "Windows Update cache cleaned" -Level INFO -Feature "CleanSystem"
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
        Write-WKLog -Message "Error cleaning Windows Update: $_" -Level ERROR -Feature "CleanSystem"
    }
}

function Invoke-CleanPrefetch {
    if (-not (Get-WKConfirm -Message "Clean Prefetch?")) { return }
    
    Write-Host "`nCleaning Prefetch..." -ForegroundColor Cyan
    
    try {
        $prefetchPath = "$env:WINDIR\Prefetch"
        if (Test-Path $prefetchPath) {
            Remove-Item "$prefetchPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "Prefetch cleaned." -ForegroundColor Green
        Write-WKLog -Message "Prefetch cleaned" -Level INFO -Feature "CleanSystem"
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
        Write-WKLog -Message "Error cleaning Prefetch: $_" -Level ERROR -Feature "CleanSystem"
    }
}

function Invoke-CleanEventLogs {
    if (-not (Get-WKConfirm -Message "Clear Event Logs?" -Dangerous)) { return }
    
    Write-Host "`nCleaning Event Logs..." -ForegroundColor Cyan
    
    try {
        Get-WinEvent -ListLog * | ForEach-Object {
            try {
                Clear-EventLog -LogName $_.LogName -ErrorAction SilentlyContinue
            }
            catch {}
        }
        
        Write-Host "Event Logs cleared." -ForegroundColor Green
        Write-WKLog -Message "Event Logs cleared" -Level INFO -Feature "CleanSystem"
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
        Write-WKLog -Message "Error clearing Event Logs: $_" -Level ERROR -Feature "CleanSystem"
    }
}

function Invoke-CleanAll {
    if (-not (Get-WKConfirm -Message "Run ALL system cleanups?" -Dangerous)) { return }
    
    Write-Host "`nStarting full system cleanup..." -ForegroundColor Cyan
    Show-WKProgress -Activity "System Cleanup" -Status "Starting..."
    
    Invoke-CleanTemp
    Show-WKProgress -Activity "System Cleanup" -Status "Cleaning TEMP..." -PercentComplete 25
    
    Invoke-CleanWindowsUpdate
    Show-WKProgress -Activity "System Cleanup" -Status "Cleaning Windows Update..." -PercentComplete 50
    
    Invoke-CleanPrefetch
    Show-WKProgress -Activity "System Cleanup" -Status "Cleaning Prefetch..." -PercentComplete 75
    
    Invoke-CleanEventLogs
    Show-WKProgress -Activity "System Cleanup" -Status "Cleaning Event Logs..." -PercentComplete 90
    
    Complete-WKProgress
    Write-Host "`nAll cleanups completed successfully!" -ForegroundColor Green
    Write-WKLog -Message "Full system cleanup completed" -Level INFO -Feature "CleanSystem"
}
