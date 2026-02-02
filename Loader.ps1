# Loader.ps1
# WinKit Bootstrap Engine - Load Core → Features → Registry

function Start-WinKit {
    [CmdletBinding()]
    param()
    
    Write-Log -Level INFO -Message "=== WinKit Bootstrap Started ===" -Silent $true
    
    # PHASE 1: Load Core Modules
    Write-Log -Level INFO -Message "Phase 1: Loading core modules..." -Silent $true
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
    
    # PHASE 2: Initialize Logger (Silent)
    Write-Log -Level INFO -Message "Phase 2: Initializing logger..." -Silent $true
    try {
        Initialize-Log | Out-Null
        Write-Log -Level INFO -Message "Logger initialized successfully" -Silent $true
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to initialize logger: $_" -Silent $true
        throw "Logger initialization failed"
    }
    
    # PHASE 3: Validate System Requirements
    Write-Log -Level INFO -Message "Phase 3: Validating system requirements..." -Silent $true
    try {
        $psCheck = Test-PowerShellVersion -MinimumVersion 5
        if (-not $psCheck.IsValid) {
            throw "PowerShell $($psCheck.MinimumVersion)+ required. Current: $($psCheck.CurrentVersion)"
        }
        
        # Windows only check
        if ($PSVersionTable.Platform -ne "Win32NT") {
            throw "WinKit requires Windows OS"
        }
        
        Write-Log -Level INFO -Message "System validation passed" -Silent $true
    }
    catch {
        Write-Log -Level ERROR -Message "System validation failed: $_" -Silent $true
        throw
    }
    
    # PHASE 4: Load Configuration
    Write-Log -Level INFO -Message "Phase 4: Loading configuration..." -Silent $true
    try {
        $Global:WinKitConfig = Load-Configuration -Path "config.json"
        Write-Log -Level INFO -Message "Configuration loaded" -Silent $true
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to load configuration: $_" -Silent $true
        throw
    }
    
    # PHASE 5: Initialize Window
    Write-Log -Level INFO -Message "Phase 5: Initializing window..." -Silent $true
    try {
        $windowResult = Initialize-Window -Width $Global:WinKitConfig.Window.Width -Height $Global:WinKitConfig.Window.Height
        if ($windowResult) {
            $host.UI.RawUI.WindowTitle = $Global:WinKitConfig.Window.Title
            Write-Log -Level INFO -Message "Window initialized: $($Global:WinKitConfig.Window.Width)x$($Global:WinKitConfig.Window.Height)" -Silent $true
        }
    }
    catch {
        Write-Log -Level WARN -Message "Window initialization warning: $_" -Silent $true
        # Non-critical error, continue
    }
    
    # PHASE 6: Load UI Modules
    Write-Log -Level INFO -Message "Phase 6: Loading UI modules..." -Silent $true
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
    
    # PHASE 7: Initialize UI Components
    Write-Log -Level INFO -Message "Phase 7: Initializing UI components..." -Silent $true
    try {
        # Initialize Theme
        $themeResult = Initialize-Theme -ColorScheme $Global:WinKitConfig.UI.ColorScheme
        if ($themeResult) {
            Write-Log -Level INFO -Message "Theme initialized: $($Global:WinKitConfig.UI.ColorScheme)" -Silent $true
        }
        
        # Initialize Logo
        $Global:WinKitLogo = Get-Logo -Style $Global:WinKitConfig.UI.LogoStyle
        Write-Log -Level INFO -Message "Logo initialized" -Silent $true
    }
    catch {
        Write-Log -Level ERROR -Message "UI initialization failed: $_" -Silent $true
        throw
    }
    
    # PHASE 8: Load All Features
    Write-Log -Level INFO -Message "Phase 8: Loading features..." -Silent $true
    try {
        $featureFiles = Get-ChildItem -Path "features" -Filter "*.ps1" -File | Sort-Object Name
        
        if ($featureFiles.Count -eq 0) {
            Write-Log -Level WARN -Message "No feature files found in features directory" -Silent $true
        }
        else {
            foreach ($file in $featureFiles) {
                try {
                    . $file.FullName
                    Write-Log -Level DEBUG -Message "Loaded feature: $($file.Name)" -Silent $true
                }
                catch {
                    Write-Log -Level ERROR -Message "Failed to load feature $($file.Name): $_" -Silent $true
                    # Continue loading other features
                }
            }
            
            Write-Log -Level INFO -Message "Loaded $($featureFiles.Count) feature files" -Silent $true
        }
    }
    catch {
        Write-Log -Level ERROR -Message "Feature loading failed: $_" -Silent $true
        throw
    }
    
    # PHASE 9: Validate Registry
    Write-Log -Level INFO -Message "Phase 9: Validating feature registry..." -Silent $true
    try {
        $featureCount = (Get-AllFeatures).Count
        if ($featureCount -eq 0) {
            Write-Log -Level WARN -Message "Feature registry is empty" -Silent $true
        }
        else {
            Write-Log -Level INFO -Message "Registry validated: $featureCount features registered" -Silent $true
            
            # Log registered features for debugging
            $features = Get-AllFeatures
            foreach ($feature in $features) {
                Write-Log -Level DEBUG -Message "Registered: [$($feature.Category)] $($feature.Id) - $($feature.Title)" -Silent $true
            }
        }
    }
    catch {
        Write-Log -Level ERROR -Message "Registry validation failed: $_" -Silent $true
        throw
    }
    
    # PHASE 10: Complete Bootstrap
    Write-Log -Level INFO -Message "=== WinKit Bootstrap Completed ===" -Silent $true
    Write-Log -Level INFO -Message "All systems ready. Starting UI..." -Silent $true
    
    return $true
}

function Get-LoaderStatus {
    [CmdletBinding()]
    param()
    
    return @{
        CoreLoaded = $true
        LoggerInitialized = $Global:WinKitLoggerConfig.IsInitialized
        ConfigLoaded = [bool]$Global:WinKitConfig
        ThemeInitialized = [bool]$Global:WinKitTheme
        FeaturesLoaded = (Get-AllFeatures).Count
        WindowInitialized = $true
    }
}

# Export functions
Export-ModuleMember -Function Start-WinKit, Get-LoaderStatus
