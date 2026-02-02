function Start-CleanSystem {
    Write-Host ""
    Write-Padded "=== Clean System ===" -Color Cyan -IndentLevel 0
    Write-Padded ""  # Empty line
    Write-Padded "This feature will clean temporary files and system caches." -Color Gray
    Write-Padded ""  # Empty line
    
    Write-Padded "Operations to be performed:" -Color Yellow
    Write-Padded "  - Temporary files" -Color Gray
    Write-Padded "  - Windows Update cache" -Color Gray
    Write-Padded "  - Prefetch files" -Color Gray
    Write-Padded "  - System logs (optional)" -Color Gray
    Write-Padded ""  # Empty line
    
    if (-not (Ask-WKConfirm "Do you want to proceed?")) {
        Write-Padded "Operation cancelled." -Color Yellow
        return
    }
    
    Write-Padded ""  # Empty line
    Write-WKInfo "Cleaning temporary files..."
    try {
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-WKSuccess "Temporary files cleaned"
    }
    catch {
        Write-WKWarn "Some temp files could not be removed"
    }
    
    Write-Padded ""  # Empty line
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
    
    Write-Padded ""  # Empty line
    Write-WKInfo "Cleaning prefetch files..."
    try {
        Remove-Item "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
        Write-WKSuccess "Prefetch files cleaned"
    }
    catch {
        Write-WKWarn "Prefetch cleaning failed"
    }
    
    Write-Padded ""  # Empty line
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
    
    Write-Padded ""  # Empty line
    Write-Padded "=== Summary ===" -Color Green -IndentLevel 0
    Write-Padded ""  # Empty line
    Write-WKSuccess "System cleanup completed successfully!"
    Write-WKInfo "Note: Some changes may require restart to take full effect."
    
    Write-Log -Message "CleanSystem feature executed" -Level "INFO"
}
