function Start-CleanSystem {
    Write-Host "=== Clean System ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This feature will clean temporary files and system caches." -ForegroundColor Gray
    Write-Host ""
    
    if (-not (Ask-WKConfirm "Do you want to proceed?")) {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-WKInfo "Cleaning temporary files..."
    try {
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-WKSuccess "Temporary files cleaned"
    }
    catch {
        Write-WKWarn "Some temp files could not be removed"
    }
    
    Write-Host ""
    Write-WKInfo "Cleaning Windows Update cache..."
    try {
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service wuauserv -ErrorAction SilentlyContinue
        Write-WKSuccess "Windows Update cache cleaned"
    }
    catch {
        Write-WKWarn "Windows Update cache cleaning failed"
    }
    
    Write-Host ""
    Write-WKInfo "Cleaning prefetch files..."
    try {
        Remove-Item "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
        Write-WKSuccess "Prefetch files cleaned"
    }
    catch {
        Write-WKWarn "Prefetch cleaning failed"
    }
    
    Write-Host ""
    Write-WKSuccess "System cleanup completed successfully!"
    Write-Host "Note: Some changes may require restart to take full effect." -ForegroundColor Gray
    
    Write-Log -Message "CleanSystem feature executed" -Level "INFO"
}
