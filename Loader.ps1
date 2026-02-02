# Loader.ps1 - WinKit Local Loader
# KHÔNG DÙNG Export-ModuleMember

function Start-WinKit {
    [CmdletBinding()]
    param()
    
    try {
        $startTime = Get-Date
        $currentDir = Get-Location | Select-Object -ExpandProperty Path
        
        # PHASE 1: Load Core Modules - KHÔNG EXPORT
        $coreModules = @(
            "core\Logger.ps1",
            "core\Utils.ps1", 
            "core\Security.ps1",
            "core\FeatureRegistry.ps1",
            "core\Interface.ps1"
        )
        
        foreach ($module in $coreModules) {
            if (Test-Path $module) {
                . $module
            }
            else {
                throw "Core module not found: $module"
            }
        }
        
        # PHASE 2: Initialize Logger
        Initialize-Log | Out-Null
        
        # Ghi log đầu tiên
        Write-Log -Level INFO -Message "=== WinKit Local Loader Started ===" -Silent $true
        Write-Log -Level INFO -Message "Start time: $startTime" -Silent $true
        Write-Log -Level INFO -Message "Current directory: $currentDir" -Silent $true
        
        # PHASE 3: Load Configuration
        $Global:WinKitConfig = Load-Configuration -Path "config.json"
        Write-Log -Level INFO -Message "Configuration loaded" -Silent $true
        
        # PHASE 4: Validate System
        $psCheck = Test-PowerShellVersion -MinimumVersion 5
        if (-not $psCheck.IsValid) {
            throw "PowerShell $($psCheck.MinimumVersion)+ required. Current: $($psCheck.CurrentVersion)"
        }
        
        if ($PSVersionTable.Platform -ne "Win32NT") {
            throw "WinKit requires Windows OS"
        }
        
        Write-Log -Level INFO -Message "System validation passed" -Silent $true
        
        # PHASE 5: Initialize Window
        $windowResult = Initialize-Window -Width $Global:WinKitConfig.Window.Width -Height $Global:WinKitConfig.Window.Height
        if ($windowResult) {
            $host.UI.RawUI.WindowTitle = $Global:WinKitConfig.Window.Title
            Write-Log -Level INFO -Message "Window initialized" -Silent $true
        }
        
        # PHASE 6: Load UI Modules - KHÔNG EXPORT
        $uiModules = @(
            "ui\Theme.ps1",
            "ui\Logo.ps1",
            "ui\UI.ps1"
        )
        
        foreach ($module in $uiModules) {
            if (Test-Path $module) {
                . $module
                Write-Log -Level DEBUG -Message "Loaded UI: $module" -Silent $true
            }
            else {
                throw "UI module not found: $module"
            }
        }
        
        # PHASE 7: Initialize Theme
        $themeResult = Initialize-Theme -ColorScheme $Global:WinKitConfig.UI.ColorScheme
        if ($themeResult) {
            Write-Log -Level INFO -Message "Theme initialized" -Silent $true
        }
        
        # PHASE 8: Load Features
        $featureFiles = Get-ChildItem -Path "features" -Filter "*.ps1" -File -ErrorAction SilentlyContinue | Sort-Object Name
        
        if ($featureFiles.Count -eq 0) {
            Write-Log -Level WARN -Message "No feature files found" -Silent $true
        }
        else {
            foreach ($file in $featureFiles) {
                try {
                    . $file.FullName
                    Write-Log -Level DEBUG -Message "Loaded feature: $($file.Name)" -Silent $true
                }
                catch {
                    Write-Log -Level ERROR -Message "Failed to load feature $($file.Name): $_" -Silent $true
                }
            }
            
            Write-Log -Level INFO -Message "Loaded $($featureFiles.Count) feature files" -Silent $true
        }
        
        # PHASE 9: Validate Registry
        $featureCount = (Get-AllFeatures).Count
        if ($featureCount -eq 0) {
            Write-Log -Level WARN -Message "Feature registry is empty" -Silent $true
        }
        else {
            Write-Log -Level INFO -Message "Registry validated: $featureCount features" -Silent $true
        }
        
        # PHASE 10: Load Menu
        if (Test-Path "Menu.ps1") {
            . "Menu.ps1"
            Write-Log -Level INFO -Message "Menu loaded" -Silent $true
        }
        else {
            throw "Menu.ps1 not found"
        }
        
        # PHASE 11: Complete
        Write-Log -Level INFO -Message "=== WinKit Ready ===" -Silent $true
        
        # Clear và vào Main UI
        Clear-Host
        
        # Start main menu
        Start-Menu
        
    }
    catch {
        # Log error
        try {
            Write-Log -Level ERROR -Message "Loader failed: $_" -Silent $true
        }
        catch {}
        
        # Show error
        Clear-Host
        Write-Host "`n" + ("=" * 60) -ForegroundColor Red
        Write-Host "LOADER ERROR" -ForegroundColor Red
        Write-Host ("=" * 60) -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Yellow
        
        try {
            $logPath = Get-LogPath
            if ($logPath) {
                Write-Host "`nLog file: $logPath" -ForegroundColor Gray
            }
        }
        catch {}
        
        Write-Host "`nType 'exit' and press Enter to close..." -ForegroundColor Gray
        while ($true) {
            $input = Read-Host
            if ($input -eq 'exit') { break }
        }
        
        exit 1
    }
}

# KHÔNG DÙNG Export-ModuleMember
# Functions are available when dot-sourced
