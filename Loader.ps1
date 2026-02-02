# Loader.ps1 - WinKit Local Loader
# Chỉ load file từ thư mục hiện tại ($PSScriptRoot)

function Start-WinKit {
    [CmdletBinding()]
    param()
    
    # Ghi log bắt đầu (KHÔNG in ra console)
    Write-Log -Level INFO -Message "=== WinKit Local Loader Started ===" -Silent $true
    
    # Lấy thư mục hiện tại
    $currentDir = Get-Location | Select-Object -ExpandProperty Path
    Write-Log -Level INFO -Message "Current directory: $currentDir" -Silent $true
    
    # PHASE 1: Load Core Modules (local)
    Write-Log -Level INFO -Message "Phase 1: Loading local core modules..." -Silent $true
    
    $coreModules = @(
        "core\Logger.ps1",
        "core\Utils.ps1", 
        "core\Security.ps1",
        "core\FeatureRegistry.ps1",
        "core\Interface.ps1"
    )
    
    foreach ($module in $coreModules) {
        try {
            if (Test-Path $module) {
                . $module
                Write-Log -Level DEBUG -Message "Loaded: $module" -Silent $true
            }
            else {
                Write-Log -Level ERROR -Message "Core module not found: $module" -Silent $true
                throw "Core module missing: $module"
            }
        }
        catch {
            Write-Log -Level ERROR -Message "Failed to load $module : $_" -Silent $true
            throw
        }
    }
    
    # PHASE 2: Initialize Logger (KHÔNG in ra console)
    Write-Log -Level INFO -Message "Phase 2: Initializing logger..." -Silent $true
    try {
        Initialize-Log | Out-Null
        Write-Log -Level INFO -Message "Logger initialized" -Silent $true
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to initialize logger: $_" -Silent $true
        throw "Logger initialization failed"
    }
    
    # PHASE 3: Load Configuration
    Write-Log -Level INFO -Message "Phase 3: Loading configuration..." -Silent $true
    try {
        $Global:WinKitConfig = Load-Configuration -Path "config.json"
        Write-Log -Level INFO -Message "Configuration loaded" -Silent $true
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to load configuration: $_" -Silent $true
        throw
    }
    
    # PHASE 4: Initialize Window (local)
    Write-Log -Level INFO -Message "Phase 4: Initializing window..." -Silent $true
    try {
        $windowResult = Initialize-Window -Width $Global:WinKitConfig.Window.Width -Height $Global:WinKitConfig.Window.Height
        if ($windowResult) {
            $host.UI.RawUI.WindowTitle = $Global:WinKitConfig.Window.Title
            Write-Log -Level INFO -Message "Window initialized" -Silent $true
        }
    }
    catch {
        Write-Log -Level WARN -Message "Window initialization warning: $_" -Silent $true
        # Non-critical
    }
    
    # PHASE 5: Load UI Modules (local)
    Write-Log -Level INFO -Message "Phase 5: Loading UI modules..." -Silent $true
    
    $uiModules = @(
        "ui\Theme.ps1",
        "ui\Logo.ps1",
        "ui\UI.ps1"
    )
    
    foreach ($module in $uiModules) {
        try {
            if (Test-Path $module) {
                . $module
                Write-Log -Level DEBUG -Message "Loaded UI: $module" -Silent $true
            }
            else {
                Write-Log -Level ERROR -Message "UI module not found: $module" -Silent $true
                throw "UI module missing: $module"
            }
        }
        catch {
            Write-Log -Level ERROR -Message "Failed to load UI module $module : $_" -Silent $true
            throw
        }
    }
    
    # PHASE 6: Initialize UI Components
    Write-Log -Level INFO -Message "Phase 6: Initializing UI components..." -Silent $true
    try {
        # Initialize Theme
        $themeResult = Initialize-Theme -ColorScheme $Global:WinKitConfig.UI.ColorScheme
        if ($themeResult) {
            Write-Log -Level INFO -Message "Theme initialized" -Silent $true
        }
        
        Write-Log -Level INFO -Message "UI components initialized" -Silent $true
    }
    catch {
        Write-Log -Level ERROR -Message "UI initialization failed: $_" -Silent $true
        throw
    }
    
    # PHASE 7: Load Features (local)
    Write-Log -Level INFO -Message "Phase 7: Loading local features..." -Silent $true
    try {
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
    }
    catch {
        Write-Log -Level ERROR -Message "Feature loading failed: $_" -Silent $true
        throw
    }
    
    # PHASE 8: Validate Registry
    Write-Log -Level INFO -Message "Phase 8: Validating feature registry..." -Silent $true
    try {
        $featureCount = (Get-AllFeatures).Count
        if ($featureCount -eq 0) {
            Write-Log -Level WARN -Message "Feature registry is empty" -Silent $true
        }
        else {
            Write-Log -Level INFO -Message "Registry validated: $featureCount features" -Silent $true
        }
    }
    catch {
        Write-Log -Level ERROR -Message "Registry validation failed: $_" -Silent $true
        throw
    }
    
    # PHASE 9: Load Menu
    Write-Log -Level INFO -Message "Phase 9: Loading menu..." -Silent $true
    try {
        if (Test-Path "Menu.ps1") {
            . "Menu.ps1"
            Write-Log -Level INFO -Message "Menu loaded" -Silent $true
        }
        else {
            throw "Menu.ps1 not found"
        }
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to load menu: $_" -Silent $true
        throw
    }
    
    # PHASE 10: Complete - Clear screen và vào Main UI
    Write-Log -Level INFO -Message "=== WinKit Ready ===" -Silent $true
    
    # Clear screen trước khi show main UI
    Clear-Host
    
    # Start main menu
    Start-Menu
}

# Export
Export-ModuleMember -Function Start-WinKit
