function Start-CleanSystem {
    Write-WKInfo "Cleaning temporary files and system caches"
    Write-Host ""
    
    $operations = @(
        "Temporary files",
        "Windows Update cache", 
        "Prefetch files",
        "System logs (optional)"
    )
    
    Write-Host "This will clean:" -ForegroundColor Yellow
    foreach ($op in $operations) {
        Write-Host "  - $op" -ForegroundColor Gray
    }
    Write-Host ""
    
    if (-not (Ask-WKConfirm "Do you want to proceed?")) {
        Write-WKWarn "Operation cancelled"
        return
    }
    
    Write-Host ""
    Write-WKInfo "Cleaning temporary files..."
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-WKInfo "Cleaning Windows Update cache..."
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
    
    Write-WKInfo "Cleaning prefetch files..."
    Remove-Item "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
    
    if (Ask-WKConfirm "Clean system logs?" -Dangerous) {
        Write-WKInfo "Cleaning system logs..."
        wevtutil clear-log Application /quiet
        wevtutil clear-log System /quiet
    }
    
    Write-Host ""
    Write-WKSuccess "System cleanup completed!")
    Write-WKInfo "Some changes may require restart to take effect."
}
