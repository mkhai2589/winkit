# Feature tự đăng ký khi file được load
# KHÔNG CẦN SỬA MENU.PS1 khi thêm feature mới

# ========== FEATURE REGISTRATION ==========
# Feature sẽ tự đăng ký với hệ thống khi file được load
Register-Feature `
    -Id "CleanSystem" `
    -Title "Clean System" `
    -Description "Clean temporary files and system caches" `
    -Category "Essential" `
    -Order 1 `
    -FileName "01_CleanSystem.ps1" `
    -ExecuteAction { Start-CleanSystem } `
    -RequireAdmin $true
# ==========================================

function Start-CleanSystem {
    Write-Padded "=== System Cleanup ===" -Color Cyan
    Write-Padded ""  # Empty line
    
    # Ask for confirmation
    if (-not (Ask-WKConfirm "Clean temporary files and caches?")) {
        Write-Padded "Operation cancelled" -Color Yellow
        return
    }
    
    # Clean temp files
    Write-Padded "Cleaning temporary files..." -Color Yellow
    
    $tempPaths = @(
        "$env:TEMP\*",
        "$env:WINDIR\Temp\*",
        "$env:LOCALAPPDATA\Temp\*"
    )
    
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            try {
                Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                Write-Padded "  Cleaned: $path" -Color Green
            }
            catch {
                Write-Padded "  Failed to clean: $path" -Color Red
            }
        }
    }
    
    # Clear recycle bin
    try {
        Write-Padded "Clearing Recycle Bin..." -Color Yellow
        $shell = New-Object -ComObject Shell.Application
        $shell.NameSpace(0xA).Items() | ForEach-Object { 
            $shell.Namespace(0xA).ParseName($_.Name).InvokeVerb("Delete") 
        }
        Write-Padded "  Recycle Bin cleared" -Color Green
    }
    catch {
        Write-Padded "  Failed to clear Recycle Bin" -Color Red
    }
    
    # Clear DNS cache
    try {
        Write-Padded "Clearing DNS cache..." -Color Yellow
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        Write-Padded "  DNS cache cleared" -Color Green
    }
    catch {
        Write-Padded "  Failed to clear DNS cache" -Color Red
    }
    
    Write-Padded ""  # Empty line
    Write-Padded "System cleanup completed!" -Color Green
    Write-Log -Message "System cleanup performed" -Level "INFO"
}
