function Start-CleanSystem {
    Write-Host "=== Clean System ===" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "This feature will clean:" -ForegroundColor Yellow
    Write-Host "  - Temporary files" -ForegroundColor Gray
    Write-Host "  - Windows Update cache" -ForegroundColor Gray
    Write-Host "  - Prefetch files" -ForegroundColor Gray
    Write-Host "  - System logs (optional)" -ForegroundColor Gray
    Write-Host ""
    
    if (-not (Ask-WKConfirm "Do you want to proceed?")) {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-WKInfo "Cleaning temporary files..."
    try {
        Get-ChildItem "$env:TEMP\*" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Get-ChildItem "C:\Windows\Temp\*" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-WKSuccess "Temporary files cleaned"
    }
    catch {
        Write-WKWarn "Some temp files could not be removed"
    }
    
    Write-Host ""
    Write-WKInfo "Cleaning Windows Update cache..."
    try {
        $wuauserv = Get-Service wuauserv -ErrorAction SilentlyContinue
        if ($wuauserv -and $wuauserv.Status -eq 'Running') {
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        }
        
        if (Test-Path "C:\Windows\SoftwareDistribution\Download") {
            Get-ChildItem "C:\Windows\SoftwareDistribution\Download\*" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        if ($wuauserv) {
            Start-Service wuauserv -ErrorAction SilentlyContinue
        }
        Write-WKSuccess "Windows Update cache cleaned")
    }
    catch {
        Write-WKWarn "Windows Update cache cleaning failed"
    }
    
    Write-Host ""
    Write-WKInfo "Cleaning prefetch files..."
    try {
        if (Test-Path "C:\Windows\Prefetch") {
            Get-ChildItem "C:\Windows\Prefetch\*" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        Write-WKSuccess "Prefetch files cleaned"
    }
    catch {
        Write-WKWarn "Prefetch cleaning failed"
    }
    
    Write-Host ""
    if (Ask-WKConfirm "Clean system logs? (This may require administrative privileges)" -Dangerous) {
        try {
            wevtutil clear-log Application /quiet
            wevtutil clear-log System /quiet
            Write-WKSuccess "System logs cleared"
        }
        catch {
            Write-WKWarn "Log clearing requires administrator privileges"
        }
    }
    
    Write-Host ""
    Write-Host "=== Summary ===" -ForegroundColor Green
    Write-WKSuccess "System cleanup completed successfully!"
    Write-WKInfo "Note: Some changes may require restart to take full effect."
    
    Write-Log -Message "CleanSystem feature executed" -Level "INFO"
}
