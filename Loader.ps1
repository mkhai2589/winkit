# Loader.ps1 - WinKit Loader (không phải module)
# Chỉ là script thông thường, không Export-ModuleMember

# GLOBAL VARIABLES
$Global:WinKitConfig = $null
$Global:WinKitTheme = $null
$Global:WinKitFeatureRegistry = @()

# ============================================
# INTERNAL HELPERS - KHÔNG PHỤ THUỘC LOGGER
# ============================================

function Write-Status {
    param([string]$Message, [string]$Color = "Gray")
    Write-Host "  [$Message]" -ForegroundColor $Color
}

function Write-Success { 
    param($Message) 
    Write-Status "OK" -Color Green
    Write-Host $Message -ForegroundColor Green 
}

function Write-Error { 
    param($Message) 
    Write-Status "ERR" -Color Red
    Write-Host $Message -ForegroundColor Red 
}

function Write-Info { 
    param($Message) 
    Write-Status "INFO" -Color Gray
    Write-Host $Message -ForegroundColor Gray 
}

# ============================================
# VALIDATION FUNCTIONS - KHÔNG PHỤ THUỘC LOGGER
# ============================================

function Test-IsAdminInternal {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PowerShellVersionInternal {
    return $PSVersionTable.PSVersion.Major -ge 5
}

function Initialize-TempLog {
    # Tạo temp log file cho đến khi Logger chính thức được khởi tạo
    $tempLogPath = "$env:TEMP\winkit-bootstrap.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $logEntry = "[$timestamp] [BOOTSTRAP] WinKit started loading"
    Add-Content -Path $tempLogPath -Value $logEntry -Force
    
    return $tempLogPath
}

function Write-TempLog {
    param([string]$Message, [string]$Level = "INFO")
    
    $tempLogPath = "$env:TEMP\winkit-bootstrap.log"
    if (Test-Path $tempLogPath) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        Add-Content -Path $tempLogPath -Value $logEntry -Force
    }
}

# ============================================
# CORE LOADER FUNCTIONS
# ============================================

function Load-CoreModule {
    param([string]$ModuleName)
    
    $path = "core\$ModuleName.ps1"
    if (Test-Path $path) {
        try {
            . $path
            Write-TempLog -Message "Loaded core module: $ModuleName" -Level "DEBUG"
            return $true
        }
        catch {
            Write-TempLog -Message "Failed to load $ModuleName : $_" -Level "ERROR"
            return $false
        }
    }
    else {
        Write-TempLog -Message "Core file not found: $ModuleName.ps1" -Level "ERROR"
        return $false
    }
}

function Initialize-Loader {
    # Khởi tạo cơ bản trước khi load Logger
    Clear-Host
    Write-Host ""
    Write-Host "  [INFO] Initializing WinKit Loader..." -ForegroundColor Gray
    Write-Host ""
    
    # Tạo temp log
    $tempLog = Initialize-TempLog
    
    # Kiểm tra phiên bản PowerShell
    if (-not (Test-PowerShellVersionInternal)) {
        Write-Error "PowerShell 5.1 or higher required"
        return $false
    }
    
    return $true
}

# ============================================
# MAIN LOADER FUNCTION - PHASED APPROACH
# ============================================

function Start-WinKit {
    # PHASE 0: BASIC INITIALIZATION
    if (-not (Initialize-Loader)) {
        Write-Host ""
        Write-Host "  Bootstrap failed. Check TEMP\winkit-bootstrap.log" -ForegroundColor Red
        Read-Host "`n  Press Enter to exit..."
        exit 1
    }
    
    try {
        # PHASE 1: LOAD CORE MODULES IN ORDER
        Write-Info "Loading core modules..."
        
        # Thứ tự CỐ ĐỊNH - Logger phải đầu tiên
        $coreModules = @("Logger", "Utils", "Security", "FeatureRegistry", "Interface")
        $loadedCount = 0
        
        foreach ($module in $coreModules) {
            if (Load-CoreModule -ModuleName $module) {
                $loadedCount++
                Write-Host "  [OK] $module" -ForegroundColor Green
            }
            else {
                throw "Failed to load core module: $module"
            }
        }
        
        Write-Success "$loadedCount core modules loaded"
        
        # PHASE 2: INITIALIZE LOGGER (bây giờ đã có Write-Log)
        Write-Info "Initializing logger..."
        if (Initialize-Log) {
            Write-Success "Logger initialized"
            
            # Di chuyển temp log vào log chính
            $tempLogPath = "$env:TEMP\winkit-bootstrap.log"
            if (Test-Path $tempLogPath) {
                $tempContent = Get-Content $tempLogPath
                foreach ($line in $tempContent) {
                    Write-Log -Level INFO -Message "Bootstrap: $line" -Silent $true
                }
                Remove-Item $tempLogPath -Force
            }
        }
        else {
            Write-Error "Failed to initialize logger"
            throw "Logger initialization failed"
        }
        
        # PHASE 3: LOAD CONFIGURATION
        Write-Info "Loading configuration..."
        if (Test-Path "config.json") {
            $configContent = Get-Content "config.json" -Raw
            $Global:WinKitConfig = $configContent | ConvertFrom-Json -AsHashtable
            Write-Log -Level INFO -Message "Configuration loaded" -Silent $true
            Write-Success "Configuration loaded"
        }
        else {
            Write-Log -Level ERROR -Message "config.json not found" -Silent $true
            throw "Configuration file not found: config.json"
        }
        
        # PHASE 4: LOAD UI MODULES
        Write-Info "Loading UI modules..."
        $uiModules = @("Theme", "Logo", "UI")
        foreach ($uiModule in $uiModules) {
            $path = "ui\$uiModule.ps1"
            if (Test-Path $path) {
                . $path
                Write-Log -Level DEBUG -Message "Loaded UI: $uiModule" -Silent $true
            }
            else {
                Write-Log -Level ERROR -Message "UI file missing: $uiModule.ps1" -Silent $true
                throw "UI file missing: $uiModule.ps1"
            }
        }
        Write-Success "UI modules loaded"
        
        # PHASE 5: INITIALIZE THEME
        if ($Global:WinKitConfig.UI.ColorScheme) {
            $theme = Initialize-Theme -ColorScheme $Global:WinKitConfig.UI.ColorScheme
            Write-Log -Level INFO -Message "Theme initialized: $($Global:WinKitConfig.UI.ColorScheme)" -Silent $true
            Write-Success "Theme initialized"
        }
        
        # PHASE 6: LOAD FEATURES
        Write-Info "Loading features..."
        $featureFiles = Get-ChildItem "features" -Filter "*.ps1" -ErrorAction SilentlyContinue | Sort-Object Name
        
        if ($featureFiles.Count -gt 0) {
            $loadedFeatures = 0
            foreach ($file in $featureFiles) {
                try {
                    . $file.FullName
                    $loadedFeatures++
                    Write-Log -Level DEBUG -Message "Loaded feature: $($file.Name)" -Silent $true
                }
                catch {
                    Write-Log -Level ERROR -Message "Failed to load feature $($file.Name): $_" -Silent $true
                }
            }
            Write-Success "Loaded $loadedFeatures/$($featureFiles.Count) features"
        }
        else {
            Write-Log -Level WARN -Message "No feature files found" -Silent $true
            Write-Host "  [WARN] No features found" -ForegroundColor Yellow
        }
        
        # PHASE 7: LOAD MENU
        Write-Info "Loading menu system..."
        if (Test-Path "Menu.ps1") {
            . "Menu.ps1"
            Write-Log -Level INFO -Message "Menu loaded" -Silent $true
            Write-Success "Menu system loaded"
        }
        else {
            Write-Log -Level ERROR -Message "Menu.ps1 not found" -Silent $true
            throw "Menu file not found: Menu.ps1"
        }
        
        # PHASE 8: VALIDATE REGISTRY
        $featureCount = (Get-AllFeatures).Count
        if ($featureCount -gt 0) {
            Write-Success "Registry contains $featureCount features"
            Write-Log -Level INFO -Message "Feature registry validated: $featureCount features" -Silent $true
        }
        else {
            Write-Host "  [WARN] No features registered" -ForegroundColor Yellow
            Write-Log -Level WARN -Message "Feature registry is empty" -Silent $true
        }
        
        # PHASE 9: FINAL CLEANUP AND START
        Write-Host ""
        Write-Host "  [INFO] Starting WinKit..." -ForegroundColor Gray
        Write-Log -Level INFO -Message "WinKit fully initialized and ready" -Silent $true
        
        Start-Sleep -Milliseconds 500
        Clear-Host
        
        # Bắt đầu menu chính
        Start-Menu
    }
    catch {
        # Ghi lỗi vào temp log nếu Logger chưa sẵn sàng
        Write-TempLog -Message "Loader failed: $_" -Level "ERROR"
        
        # Hiển thị lỗi user-friendly
        Clear-Host
        Write-Host ""
        Write-Host "  " + ("=" * 60) -ForegroundColor Red
        Write-Host "  WINKIT LOADER ERROR" -ForegroundColor Red
        Write-Host "  " + ("=" * 60) -ForegroundColor Red
        Write-Host ""
        Write-Host "  Error: $_" -ForegroundColor Yellow
        Write-Host ""
        
        $tempLogPath = "$env:TEMP\winkit-bootstrap.log"
        if (Test-Path $tempLogPath) {
            Write-Host "  Check log file: $tempLogPath" -ForegroundColor Gray
        }
        
        Write-Host ""
        Read-Host "  Press Enter to exit..."
        
        exit 1
    }
}

# ============================================
# ENTRY POINT
# ============================================

Start-WinKit
