function Start-WinKit {
    try {
        # SET GLOBAL PATHS AND SETTINGS FIRST
        $global:WK_ROOT = $PSScriptRoot
        $global:WK_FEATURES = Join-Path $WK_ROOT "features"
        $global:WK_LOG = Join-Path $env:TEMP "winkit.log"
        $global:WK_PADDING = "  "  # 2 spaces for left padding
        
        # SET CONSOLE WINDOW SIZE (120x40)
        try {
            $Host.UI.RawUI.WindowTitle = "WinKit - Windows Optimization Toolkit"
            $size = New-Object System.Management.Automation.Host.Size(120, 40)
            $Host.UI.RawUI.WindowSize = $size
            $Host.UI.RawUI.BufferSize = $size
        }
        catch {
            # Silently continue if resize fails
        }
        
        # CLEAR OLD LOG ON NEW START
        if (Test-Path $global:WK_LOG) {
            Remove-Item $global:WK_LOG -Force -ErrorAction SilentlyContinue
        }
        
        # LOAD CORE MODULES IN CORRECT ORDER
        # 1. Logger first (so Write-Log is available immediately)
        $loggerPath = Join-Path $WK_ROOT "core\Logger.ps1"
        if (Test-Path $loggerPath) {
            . $loggerPath
            Write-Log -Message "WinKit starting from: $WK_ROOT" -Level "INFO"
            Write-Log -Message "Console size set to 120x40" -Level "DEBUG"
        } else {
            Write-Host "  WARNING: Logger.ps1 not found" -ForegroundColor Yellow
        }
        
        # 2. Load remaining core modules
        $coreModules = @(
            "core\Security.ps1",
            "core\Utils.ps1",
            "core\Interface.ps1"
        )
        
        foreach ($module in $coreModules) {
            $modulePath = Join-Path $WK_ROOT $module
            if (Test-Path $modulePath) {
                . $modulePath
            } else {
                Write-Host "  WARNING: $module not found" -ForegroundColor Yellow
            }
        }
        
        # 3. Load UI modules
        $uiModules = @(
            "ui\logo.ps1",
            "ui\Theme.ps1",
            "ui\UI.ps1"
        )
        
        foreach ($module in $uiModules) {
            $modulePath = Join-Path $WK_ROOT $module
            if (Test-Path $modulePath) {
                . $modulePath
            } else {
                Write-Host "  WARNING: $module not found" -ForegroundColor Yellow
            }
        }
        
        # 4. Load Menu module
        $menuPath = Join-Path $WK_ROOT "Menu.ps1"
        if (Test-Path $menuPath) {
            . $menuPath
        } else {
            throw "Menu.ps1 not found at: $menuPath"
        }
        
        # VALIDATE ADMINISTRATOR PRIVILEGES
        if (Get-Command Test-WKAdmin -ErrorAction SilentlyContinue) {
            Test-WKAdmin
        } else {
            Write-Host "  WARNING: Test-WKAdmin function not found" -ForegroundColor Yellow
        }
        
        # Log successful loading
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Message "All modules loaded successfully" -Level "INFO"
        }
        
        # START USER INTERFACE
        if (Get-Command Initialize-UI -ErrorAction SilentlyContinue) {
            Initialize-UI
        } else {
            Write-Host "  ERROR: Initialize-UI function not found" -ForegroundColor Red
            throw "UI initialization failed"
        }
        
        if (Get-Command Show-MainMenu -ErrorAction SilentlyContinue) {
            Show-MainMenu
        } else {
            Write-Host "  ERROR: Show-MainMenu function not found" -ForegroundColor Red
            throw "Main menu not available"
        }
        
    }
    catch {
        # Try to log the error if logger is available
        try { 
            if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                Write-Log -Message "Fatal startup error: $_" -Level "ERROR" 
            }
        } 
        catch {}
        
        # Show user-friendly error
        Write-Host ""
        Write-Host "  FATAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Press Enter to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}
