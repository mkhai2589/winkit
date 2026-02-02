function Start-WinKit {
    try {
        # SET GLOBAL PATHS AND SETTINGS FIRST
        $global:WK_ROOT = $PSScriptRoot
        $global:WK_FEATURES = Join-Path $WK_ROOT "features"
        $global:WK_LOG = Join-Path $env:TEMP "winkit.log"
        $global:WK_PADDING = "  "  # 2 spaces for left padding
        $global:WK_MENU_WIDTH = 76  # Fixed width for separators
        
        # SET CONSOLE WINDOW SIZE (120x40) - FIXED
        try {
            $Host.UI.RawUI.WindowTitle = "WinKit - Windows Optimization Toolkit"
            $bufferSize = New-Object System.Management.Automation.Host.Size(120, 3000)
            $windowSize = New-Object System.Management.Automation.Host.Size(120, 40)
            $Host.UI.RawUI.BufferSize = $bufferSize
            $Host.UI.RawUI.WindowSize = $windowSize
        }
        catch {
            # Silently continue if resize fails
        }
        
        # CLEAR OLD LOG ON NEW START
        if (Test-Path $global:WK_LOG) {
            Remove-Item $global:WK_LOG -Force -ErrorAction SilentlyContinue
        }
        
        # LOAD CORE MODULES IN CORRECT ORDER
        # 1. Utils first (contains Read-Json)
        $utilsPath = Join-Path $WK_ROOT "core\Utils.ps1"
        if (Test-Path $utilsPath) {
            . $utilsPath
        } else {
            throw "Core module not found: Utils.ps1"
        }
        
        # 2. Logger
        $loggerPath = Join-Path $WK_ROOT "core\Logger.ps1"
        if (Test-Path $loggerPath) {
            . $loggerPath
            Write-Log -Message "WinKit starting from: $WK_ROOT" -Level "INFO"
        } else {
            # Fallback minimal logger
            function Write-Log { param($Message, $Level) 
                Add-Content -Path $global:WK_LOG -Value "[$(Get-Date)] [$Level] $Message" 
            }
            Write-Log -Message "WinKit starting (fallback logger)" -Level "INFO"
        }
        
        # 3. Load remaining core modules
        $coreModules = @(
            "core\Security.ps1",
            "core\Interface.ps1"
        )
        
        foreach ($module in $coreModules) {
            $modulePath = Join-Path $WK_ROOT $module
            if (Test-Path $modulePath) {
                . $modulePath
                Write-Log -Message "Loaded module: $module" -Level "DEBUG"
            } else {
                Write-Log -Message "Module not found: $module" -Level "WARN"
            }
        }
        
        # 4. Load UI modules
        $uiModules = @(
            "ui\Theme.ps1",
            "ui\UI.ps1",
            "ui\Logo.ps1"
        )
        
        foreach ($module in $uiModules) {
            $modulePath = Join-Path $WK_ROOT $module
            if (Test-Path $modulePath) {
                . $modulePath
            } else {
                Write-Log -Message "UI module not found: $module" -Level "WARN"
            }
        }
        
        # 5. Load Menu module
        $menuPath = Join-Path $WK_ROOT "Menu.ps1"
        if (Test-Path $menuPath) {
            . $menuPath
            Write-Log -Message "Menu module loaded" -Level "INFO"
        } else {
            throw "Menu.ps1 not found at: $menuPath"
        }
        
        # 6. Load all feature files for self-registration
        Write-Log -Message "Loading feature files..." -Level "INFO"
        $featureFiles = Get-ChildItem -Path $global:WK_FEATURES -Filter "*.ps1" -ErrorAction SilentlyContinue
        
        foreach ($file in $featureFiles) {
            try {
                . $file.FullName
                Write-Log -Message "Loaded feature: $($file.Name)" -Level "DEBUG"
            }
            catch {
                Write-Log -Message "Failed to load feature $($file.Name): $_" -Level "ERROR"
            }
        }
        
        Write-Log -Message "Total features loaded: $($featureFiles.Count)" -Level "INFO"
        
        # VALIDATE ADMINISTRATOR PRIVILEGES
        if (Get-Command Test-WKAdmin -ErrorAction SilentlyContinue) {
            Test-WKAdmin
        }
        
        # START USER INTERFACE
        Initialize-UI
        Show-MainMenu
        
    }
    catch {
        try { 
            if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                Write-Log -Message "Fatal startup error: $_" -Level "ERROR" 
            }
        } 
        catch {}
        
        Write-Host ""
        Write-Host "  FATAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Press Enter to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}
