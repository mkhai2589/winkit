# Loader.ps1 - WinKit Loader (không phải module)
# Chỉ là script thông thường, không Export-ModuleMember

# GLOBAL VARIABLES
$Global:WinKitConfig = $null
$Global:WinKitTheme = $null

# ============================================
# MAIN LOADER FUNCTION
# ============================================

function Start-WinKit {
    try {
        Write-Host "`n  [•] Loading WinKit..." -ForegroundColor Gray
        
        # PHASE 1: Load Core files (dot-source từng file)
        $coreFiles = @("Logger", "Utils", "Security", "FeatureRegistry", "Interface")
        foreach ($file in $coreFiles) {
            $path = "core\$file.ps1"
            if (Test-Path $path) {
                . $path
                Write-Host "  [✓] Loaded: $file" -ForegroundColor Green
            }
            else {
                throw "Core file missing: $file.ps1"
            }
        }
        
        # PHASE 2: Initialize Logger (tạo file log mới)
        Initialize-Log | Out-Null
        
        # PHASE 3: Load Configuration
        if (Test-Path "config.json") {
            $configContent = Get-Content "config.json" -Raw
            $Global:WinKitConfig = $configContent | ConvertFrom-Json -AsHashtable
            Write-Log -Level INFO -Message "Configuration loaded" -Silent $true
        }
        else {
            throw "config.json not found"
        }
        
        # PHASE 4: Load UI files
        $uiFiles = @("Theme", "Logo", "UI")
        foreach ($file in $uiFiles) {
            $path = "ui\$file.ps1"
            if (Test-Path $path) {
                . $path
                Write-Log -Level DEBUG -Message "Loaded UI: $file" -Silent $true
            }
            else {
                throw "UI file missing: $file.ps1"
            }
        }
        
        # PHASE 5: Initialize Theme
        Initialize-Theme -ColorScheme $Global:WinKitConfig.UI.ColorScheme | Out-Null
        
        # PHASE 6: Load features
        $featureFiles = Get-ChildItem "features" -Filter "*.ps1" -ErrorAction SilentlyContinue
        if ($featureFiles.Count -gt 0) {
            foreach ($file in $featureFiles) {
                try {
                    . $file.FullName
                    Write-Log -Level DEBUG -Message "Loaded feature: $($file.Name)" -Silent $true
                }
                catch {
                    Write-Log -Level ERROR -Message "Failed to load $($file.Name): $_" -Silent $true
                }
            }
            Write-Host "  [✓] Loaded $($featureFiles.Count) features" -ForegroundColor Green
        }
        
        # PHASE 7: Load Menu
        if (Test-Path "Menu.ps1") {
            . "Menu.ps1"
            Write-Log -Level INFO -Message "Menu loaded" -Silent $true
        }
        else {
            throw "Menu.ps1 not found"
        }
        
        # PHASE 8: Clear và chạy
        Clear-Host
        Write-Log -Level INFO -Message "WinKit fully loaded" -Silent $true
        
        # Bắt đầu menu chính
        Start-Menu
        
    }
    catch {
        Write-Host "`n  [✗] Loader Error: $_" -ForegroundColor Red
        
        # Ghi log nếu có thể
        try {
            Write-Log -Level ERROR -Message "Loader failed: $_" -Silent $true
        }
        catch {}
        
        Write-Host ""
        Write-Host "Press Enter to exit..." -ForegroundColor Gray
        Read-Host
        
        exit 1
    }
}

# ============================================
# KHÔNG CÓ EXPORT-MODULEMEMBER
# Chỉ gọi Start-WinKit
# ============================================

Start-WinKit
