# Loader.ps1 - WinKit Local Loader
# Chỉ load file từ thư mục hiện tại

function Start-WinKit {
    [CmdletBinding()]
    param()
    
    try {
        # Ghi log bắt đầu (KHÔNG in ra console)
        $startTime = Get-Date
        $currentDir = Get-Location | Select-Object -ExpandProperty Path
        
        # PHASE 1: Load Core Modules (local) - ĐÚNG THỨ TỰ
        Write-Host "`nLoading core modules..." -ForegroundColor Yellow
        
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
        
        # PHASE 2: Initialize Logger (KHÔNG in ra console)
        Initialize-Log | Out-Null
        
        # Ghi log đầu tiên
        Write-Log -Level INFO -Message "=== WinKit Local Loader Started ===" -Silent $true
        Write-Log -Level INFO -Message "Start time: $startTime" -Silent $true
        Write-Log -Level INFO -Message "Current directory: $currentDir" -Silent $true
        Write-Log -Level INFO -Message "PowerShell version: $($PSVersionTable.PSVersion)" -Silent $true
        
        # PHASE 3: Load Configuration
        Write-Log -Level INFO -Message "Phase 3: Loading configuration..." -Silent $true
        $Global:WinKitConfig = Load-Configuration -Path "config.json"
        Write-Log -Level INFO -Message "Configuration loaded" -Silent $true
        
        # PHASE 4: Validate System Requirements
        Write-Log -Level INFO -Message "Phase 4: Validating system requirements..." -Silent $true
        $psCheck = Test-PowerShellVersion -MinimumVersion 5
        if (-not $psCheck.IsValid) {
            throw "PowerShell $($psCheck.MinimumVersion)+ required. Current: $($psCheck.CurrentVersion)"
        }
        
        # Windows only check
        if ($PSVersionTable.Platform -ne "Win32NT") {
            throw "WinKit requires Windows OS"
        }
        
        Write-Log -Level INFO -Message "System validation passed" -Silent $true
        
        # PHASE 5: Initialize Window
        Write-Log -Level INFO -Message "Phase 5: Initializing window..." -Silent $true
        $windowResult = Initialize-Window -Width $Global:WinKitConfig.Window.Width -Height $Global:WinKitConfig.Window.Height
        if ($windowResult) {
            $host.UI.RawUI.WindowTitle = $Global:WinKitConfig.Window.Title
            Write-Log -Level INFO -Message "Window initialized" -Silent $true
        }
        
        # PHASE 6: Load UI Modules
        Write-Log -Level INFO -Message "Phase 6: Loading UI modules..." -Silent $true
        
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
        
        # PHASE 7: Initialize UI Components
        Write-Log -Level INFO -Message "Phase 7: Initializing UI components..." -Silent $true
        $themeResult = Initialize-Theme -ColorScheme $Global:WinKitConfig.UI.ColorScheme
        if ($themeResult) {
            Write-Log -Level INFO -Message "Theme initialized" -Silent $true
        }
        
        # PHASE 8: Load Features (local)
        Write-Log -Level INFO -Message "Phase 8: Loading features..." -Silent $true
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
                    # Continue
                }
            }
            
            Write-Log -Level INFO -Message "Loaded $($featureFiles.Count) feature files" -Silent $true
        }
        
        # PHASE 9: Validate Registry
        Write-Log -Level INFO -Message "Phase 9: Validating feature registry..." -Silent $true
        $featureCount = (Get-AllFeatures).Count
        if ($featureCount -eq 0) {
            Write-Log -Level WARN -Message "Feature registry is empty" -Silent $true
        }
        else {
            Write-Log -Level INFO -Message "Registry validated: $featureCount features" -Silent $true
            
            # Log registered features for debugging
            $features = Get-AllFeatures
            foreach ($feature in $features) {
                Write-Log -Level DEBUG -Message "Registered: [$($feature.Category)] $($feature.Id) - $($feature.Title)" -Silent $true
            }
        }
        
        # PHASE 10: Load Menu
        Write-Log -Level INFO -Message "Phase 10: Loading menu..." -Silent $true
        if (Test-Path "Menu.ps1") {
            . "Menu.ps1"
            Write-Log -Level INFO -Message "Menu loaded" -Silent $true
        }
        else {
            throw "Menu.ps1 not found"
        }
        
        # PHASE 11: Complete - Clear screen và vào Main UI
        Write-Log -Level INFO -Message "=== WinKit Ready ===" -Silent $true
        
        # Clear screen trước khi show main UI
        Clear-Host
        
        # Start main menu
        Start-Menu
        
    }
    catch {
        # Log error
        try {
            Write-Log -Level ERROR -Message "Loader failed: $_" -Silent $true
            Write-Log -Level ERROR -Message "Stack trace: $($_.ScriptStackTrace)" -Silent $true
        }
        catch {
            # If logger fails, write to console
        }
        
        # Show error to user
        Clear-Host
        Write-Host "`n" + ("=" * 50) -ForegroundColor Red
        Write-Host "LOADER ERROR" -ForegroundColor Red
        Write-Host ("=" * 50) -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Yellow
        
        # Try to show log path if available
        try {
            $logPath = Get-LogPath
            if ($logPath) {
                Write-Host "`nCheck log file for details:" -ForegroundColor Cyan
                Write-Host "$logPath" -ForegroundColor Gray
            }
        }
        catch {
            # Ignore
        }
        
        Write-Host "`nPress any key to exit..." -ForegroundColor Gray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        exit 1
    }
}

# Export
Export-ModuleMember -Function Start-WinKit
