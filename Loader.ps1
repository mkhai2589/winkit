# Loader.ps1 - WinKit Loader (không phải module)
# Chỉ là script thông thường, không Export-ModuleMember

# GLOBAL VARIABLES
$Global:WinKitConfig = $null
$Global:WinKitTheme = $null

# ============================================
# MAIN LOADER FUNCTION - SILENT VERSION
# ============================================

function Start-WinKit {
    try {
        # KHÔNG Write-Host - chỉ ghi log (UX SILENT)
        Write-Log -Level INFO -Message "Starting WinKit loader" -Silent $true
        
        # PHASE 1: Initialize Logger (tạo file log mới) - phải làm đầu tiên
        Initialize-Log | Out-Null
        
        # PHASE 2: Load Configuration
        if (Test-Path "config.json") {
            $configContent = Get-Content "config.json" -Raw
            $Global:WinKitConfig = $configContent | ConvertFrom-Json -AsHashtable
            Write-Log -Level INFO -Message "Configuration loaded" -Silent $true
        }
        else {
            throw "config.json not found"
        }
        
        # PHASE 3: Load Core files (dot-source từng file) - SILENT
        # Đọc từ manifest.json nếu có, không thì fallback
        $coreFiles = @()
        
        if (Test-Path "manifest.json") {
            $manifest = Get-Content "manifest.json" -Raw | ConvertFrom-Json
            $coreFiles = $manifest.files | Where-Object { $_ -like "core/*.ps1" } | 
                         ForEach-Object { 
                             $_.Replace("core/", "").Replace(".ps1", "")
                         }
        }
        
        # Fallback nếu manifest không có hoặc không đọc được
        if ($coreFiles.Count -eq 0) {
            $coreFiles = @("Logger", "Utils", "Security", "FeatureRegistry", "Interface")
            Write-Log -Level WARN -Message "Using fallback core files list (manifest not found/empty)" -Silent $true
        }
        
        foreach ($file in $coreFiles) {
            $path = "core\$file.ps1"
            if (Test-Path $path) {
                . $path
                Write-Log -Level DEBUG -Message "Loaded core: $file" -Silent $true
            }
            else {
                Write-Log -Level ERROR -Message "Core file missing: $file.ps1" -Silent $true
                throw "Core file missing: $file.ps1"
            }
        }
        
        # PHASE 4: System Validation (sau khi có Logger và Security)
        $systemChecks = Get-SystemChecks
        
        # Log system check results
        foreach ($check in $systemChecks.Keys) {
            $value = $systemChecks[$check]
            if ($value -is [System.Collections.Hashtable]) {
                Write-Log -Level INFO -Message "System check - $check : $($value | ConvertTo-Json -Compress)" -Silent $true
            } else {
                Write-Log -Level INFO -Message "System check - $check : $value" -Silent $true
            }
        }
        
        # PHASE 5: Load UI files - SILENT
        $uiFiles = @("Theme", "Logo", "UI")
        foreach ($file in $uiFiles) {
            $path = "ui\$file.ps1"
            if (Test-Path $path) {
                . $path
                Write-Log -Level DEBUG -Message "Loaded UI: $file" -Silent $true
            }
            else {
                Write-Log -Level ERROR -Message "UI file missing: $file.ps1" -Silent $true
                throw "UI file missing: $file.ps1"
            }
        }
        
        # PHASE 6: Initialize Theme
        $theme = Initialize-Theme -ColorScheme $Global:WinKitConfig.UI.ColorScheme
        Write-Log -Level INFO -Message "Theme initialized: $($Global:WinKitConfig.UI.ColorScheme)" -Silent $true
        
        # PHASE 7: Load features - SILENT
        $featureFiles = Get-ChildItem "features" -Filter "*.ps1" -ErrorAction SilentlyContinue | 
                        Sort-Object Name
        
        if ($featureFiles.Count -gt 0) {
            foreach ($file in $featureFiles) {
                try {
                    . $file.FullName
                    Write-Log -Level DEBUG -Message "Loaded feature: $($file.Name)" -Silent $true
                }
                catch {
                    Write-Log -Level ERROR -Message "Failed to load feature $($file.Name): $_" -Silent $true
                    # KHÔNG throw - tiếp tục load feature khác
                }
            }
            Write-Log -Level INFO -Message "Loaded $($featureFiles.Count) feature files" -Silent $true
        } else {
            Write-Log -Level WARN -Message "No feature files found in features/" -Silent $true
        }
        
        # PHASE 8: Load Menu
        if (Test-Path "Menu.ps1") {
            . "Menu.ps1"
            Write-Log -Level INFO -Message "Menu loaded" -Silent $true
        }
        else {
            Write-Log -Level ERROR -Message "Menu.ps1 not found" -Silent $true
            throw "Menu.ps1 not found"
        }
        
        # PHASE 9: Validate feature registry
        $featureCount = (Get-AllFeatures).Count
        if ($featureCount -eq 0) {
            Write-Log -Level WARN -Message "Feature registry is empty" -Silent $true
        } else {
            Write-Log -Level INFO -Message "Feature registry contains $featureCount features" -Silent $true
        }
        
        # PHASE 10: Clear và chạy
        Clear-Host
        Write-Log -Level INFO -Message "WinKit fully loaded and ready" -Silent $true
        
        # Bắt đầu menu chính
        Start-Menu
        
    }
    catch {
        # Ghi log lỗi
        Write-Log -Level ERROR -Message "Loader failed: $_" -Silent $true
        
        # Hiển thị lỗi user-friendly (đây là ngoại lệ duy nhất được phép Write-Host)
        Write-Host "`n" + ("=" * 60) -ForegroundColor Red
        Write-Host "WINKIT LOADER ERROR" -ForegroundColor Red
        Write-Host ("=" * 60) -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Yellow
        
        $logPath = try { Get-LogPath } catch { "Unknown" }
        Write-Host "`nCheck log file for details: $logPath" -ForegroundColor Gray
        
        Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
        $null = Read-Host
        
        exit 1
    }
}

# ============================================
# KHÔNG CÓ EXPORT-MODULEMEMBER
# Chỉ gọi Start-WinKit
# ============================================

Start-WinKit
