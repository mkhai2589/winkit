# ==========================================
# WinKit Feature: Clean System
# ==========================================

function Start-CleanSystem {
    Clear-Host
    Initialize-UI
    
    Write-Host "CLEAN SYSTEM" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════" -ForegroundColor DarkGray
    
    $options = @(
        "Clean Temporary Files",
        "Clean Windows Update Cache",
        "Clean Prefetch",
        "Clean Event Logs",
        "Run All Cleanups",
        "Back to Main Menu"
    )
    
    Write-Host "`nSelect cleaning option:" -ForegroundColor White
    
    for ($i = 0; $i -lt $options.Count; $i++) {
        Write-Host "[$($i+1)] $($options[$i])" -ForegroundColor Gray
    }
    
    Write-Host ""
    $choice = Read-Host "Your choice [1-6]"
    
    switch ($choice) {
        "1" { Invoke-CleanTemp }
        "2" { Invoke-CleanWindowsUpdate }
        "3" { Invoke-CleanPrefetch }
        "4" { Invoke-CleanEventLogs }
        "5" { Invoke-CleanAll }
        "6" { return }
        default {
            Write-Host "Invalid selection!" -ForegroundColor Red
            Pause
            return
        }
    }
}

# Internal functions with safe logging
function Invoke-CleanTemp {
    if (-not (Ask-WKConfirm "Clean temporary files from all locations?")) { return }
    
    Write-Host "`nCleaning temporary files..." -ForegroundColor Cyan
    
    $paths = @(
        "$env:TEMP\*",
        "$env:WINDIR\Temp\*",
        "$env:LOCALAPPDATA\Temp\*",
        "$env:ProgramData\Temp\*"
    )
    
    $totalCleaned = 0
    foreach ($path in $paths) {
        if (Test-Path $path) {
            try {
                Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  ✓ Cleaned: $path" -ForegroundColor Green
                $totalCleaned++
            }
            catch {
                Write-Host "  ✗ Failed: $path" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "`nCleaned $totalCleaned temporary locations." -ForegroundColor Green
    try { Write-Log -Message "Cleaned temporary files" -Level "INFO" } catch {}
}

function Invoke-CleanWindowsUpdate {
    if (-not (Ask-WKConfirm "Clean Windows Update cache? This will restart Windows Update services.")) { return }
    
    Write-Host "`nCleaning Windows Update cache..." -ForegroundColor Cyan
    
    try {
        # Stop services
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Stop-Service bits -Force -ErrorAction SilentlyContinue
        
        # Clean download folder
        $downloadPath = "$env:WINDIR\SoftwareDistribution\Download"
        if (Test-Path $downloadPath) {
            Remove-Item "$downloadPath\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Cleaned download cache" -ForegroundColor Green
        }
        
        # Restart services
        Start-Service wuauserv -ErrorAction SilentlyContinue
        Start-Service bits -ErrorAction SilentlyContinue
        Write-Host "  ✓ Restarted Windows Update services" -ForegroundColor Green
        
        Write-Host "`nWindows Update cache cleaned successfully." -ForegroundColor Green
        try { Write-Log -Message "Cleaned Windows Update cache" -Level "INFO" } catch {}
    }
    catch {
        Write-Host "`n✗ Error cleaning Windows Update cache: $_" -ForegroundColor Red
        try { Write-Log -Message "Error cleaning Windows Update cache: $_" -Level "ERROR" } catch {}
    }
}

function Invoke-CleanPrefetch {
    if (-not (Ask-WKConfirm "Clean Prefetch files? This may affect boot optimization.")) { return }
    
    Write-Host "`nCleaning Prefetch..." -ForegroundColor Cyan
    
    $prefetchPath = "$env:WINDIR\Prefetch"
    if (Test-Path $prefetchPath) {
        try {
            Remove-Item "$prefetchPath\*" -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Cleaned Prefetch files" -ForegroundColor Green
            try { Write-Log -Message "Cleaned Prefetch" -Level "INFO" } catch {}
        }
        catch {
            Write-Host "  ✗ Failed to clean Prefetch" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  ✗ Prefetch directory not found" -ForegroundColor Yellow
    }
}

function Invoke-CleanEventLogs {
    if (-not (Ask-WKConfirm "Clear ALL Event Logs? This action cannot be undone." -Dangerous)) { return }
    
    Write-Host "`nClearing Event Logs..." -ForegroundColor Cyan
    
    try {
        wevtutil el | ForEach-Object {
            try {
                wevtutil cl $_ 2>$null
            }
            catch {}
        }
        
        Write-Host "  ✓ Event Logs cleared" -ForegroundColor Green
        try { Write-Log -Message "Cleared Event Logs" -Level "INFO" } catch {}
    }
    catch {
        Write-Host "  ✗ Failed to clear Event Logs" -ForegroundColor Red
        try { Write-Log -Message "Error clearing Event Logs: $_" -Level "ERROR" } catch {}
    }
}

function Invoke-CleanAll {
    if (-not (Ask-WKConfirm "Run ALL system cleanups? This includes temporary files, update cache, prefetch, and event logs." -Dangerous)) { return }
    
    Write-Host "`nStarting comprehensive system cleanup..." -ForegroundColor Cyan
    try { Show-WKProgress -Activity "System Cleanup" -Status "Initializing..." } catch {}
    
    try { Show-WKProgress -Activity "System Cleanup" -Status "Cleaning temporary files..." -Percent 20 } catch {}
    Invoke-CleanTemp
    
    try { Show-WKProgress -Activity "System Cleanup" -Status "Cleaning Windows Update cache..." -Percent 40 } catch {}
    Invoke-CleanWindowsUpdate
    
    try { Show-WKProgress -Activity "System Cleanup" -Status "Cleaning Prefetch..." -Percent 60 } catch {}
    Invoke-CleanPrefetch
    
    try { Show-WKProgress -Activity "System Cleanup" -Status "Cleaning Event Logs..." -Percent 80 } catch {}
    Invoke-CleanEventLogs
    
    try { Complete-WKProgress } catch {}
    Write-Host "`n✓ All system cleanups completed successfully!" -ForegroundColor Green
    try { Write-Log -Message "Completed full system cleanup" -Level "INFO" } catch {}
}
