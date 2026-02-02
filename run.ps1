# run.ps1
# WinKit Entry Point - Single File Launcher

# Error handling for the entire application
trap {
    Write-Host "`n=== FATAL ERROR ===" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
    Write-Host "`nWinKit cannot continue. Please check system requirements." -ForegroundColor Cyan
    
    # Try to log the error if logger is available
    try {
        if (Get-Command -Name Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Level ERROR -Message "Fatal error in run.ps1: $_" -Silent $true
            Write-Log -Level ERROR -Message "Stack: $($_.ScriptStackTrace)" -Silent $true
        }
    }
    catch {
        # Ignore logging errors at this point
    }
    
    Write-Host "`nPress any key to exit..." -ForegroundColor Gray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Main entry point
function Main {
    [CmdletBinding()]
    param()
    
    Write-Host "`nInitializing WinKit..." -ForegroundColor Yellow
    
    try {
        # Load Loader.ps1
        if (Test-Path "Loader.ps1") {
            . "Loader.ps1"
        }
        else {
            throw "Loader.ps1 not found"
        }
        
        # Start WinKit
        $result = Start-WinKit
        
        if ($result) {
            # Start the main menu
            . "Menu.ps1"
            Start-Menu
        }
        else {
            throw "Failed to initialize WinKit"
        }
    }
    catch {
        Write-Host "`nError: $_" -ForegroundColor Red
        Write-Host "`nPlease ensure all files are in the correct directory structure." -ForegroundColor Yellow
        Write-Host "Expected structure:" -ForegroundColor Gray
        Write-Host "  WinKit/" -ForegroundColor Gray
        Write-Host "  ├── core/ (Logger.ps1, Utils.ps1, etc.)" -ForegroundColor Gray
        Write-Host "  ├── ui/ (Theme.ps1, Logo.ps1, UI.ps1)" -ForegroundColor Gray
        Write-Host "  ├── features/ (*.ps1 files)" -ForegroundColor Gray
        Write-Host "  └── config.json, version.json" -ForegroundColor Gray
        
        throw
    }
}

# Set window title
$host.UI.RawUI.WindowTitle = "WinKit - Windows Optimization Toolkit"

# Check if running in PowerShell console (not ISE)
if ($host.Name -ne "ConsoleHost") {
    Write-Warning "WinKit is optimized for PowerShell Console. Some features may not work in PowerShell ISE."
}

# Set execution policy for this session only (temporary)
try {
    $originalPolicy = Get-ExecutionPolicy -Scope Process
    if ($originalPolicy -notin @('RemoteSigned', 'Unrestricted', 'Bypass')) {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force -ErrorAction SilentlyContinue
    }
}
catch {
    # Non-critical, continue
}

# Start the application
Main

# Restore original execution policy if we changed it
try {
    if ($originalPolicy) {
        Set-ExecutionPolicy -ExecutionPolicy $originalPolicy -Scope Process -Force -ErrorAction SilentlyContinue
    }
}
catch {
    # Ignore
}

# Clean exit
exit 0
