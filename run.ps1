# run.ps1 - WinKit Bootstrap Downloader
# Single Entry Point: irm https://raw.githubusercontent.com/mkhai2589/winkit/main/run.ps1 | iex

# ============================================
# CONFIGURATION
# ============================================

$Script:GitHubBase = "https://raw.githubusercontent.com/mkhai2589/winkit/main"
$Script:TempBase = "$env:TEMP\WinKit"
$Script:RequiredFiles = @(
    "core/Logger.ps1", "core/Utils.ps1", "core/Security.ps1",
    "core/FeatureRegistry.ps1", "core/Interface.ps1",
    "ui/Theme.ps1", "ui/Logo.ps1", "ui/UI.ps1",
    "Loader.ps1", "Menu.ps1",
    "config.json", "version.json",
    "assets/ascii.txt",
    "features/01_CleanSystem.ps1"
)

# ============================================
# PHASE 0: EXECUTION POLICY - FIX TRIỆT ĐỂ
# ============================================

function Fix-ExecutionPolicy {
    [CmdletBinding()]
    param()
    
    Write-Host "  [•] Checking Execution Policy..." -ForegroundColor Gray
    
    try {
        # Kiểm tra policy hiện tại
        $currentProcessPolicy = Get-ExecutionPolicy -Scope Process -ErrorAction SilentlyContinue
        $currentUserPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
        
        # Policy cho phép
        $allowedPolicies = @('RemoteSigned', 'Unrestricted', 'Bypass')
        
        # Nếu Process policy không hợp lệ, set Bypass
        if ($currentProcessPolicy -notin $allowedPolicies) {
            Write-Host "  [•] Setting Process ExecutionPolicy to Bypass..." -ForegroundColor Yellow
            try {
                Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
                Write-Host "  [✓] Process ExecutionPolicy set to Bypass" -ForegroundColor Green
            }
            catch {
                Write-Host "  [✗] Cannot set Process policy: $_" -ForegroundColor Red
            }
        }
        
        # Nếu CurrentUser policy không hợp lệ, thử set RemoteSigned
        if ($currentUserPolicy -notin $allowedPolicies) {
            Write-Host "  [•] Setting CurrentUser ExecutionPolicy to RemoteSigned..." -ForegroundColor Yellow
            
            # Cố gắng set mà không cần admin trước
            try {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
                Write-Host "  [✓] CurrentUser ExecutionPolicy set to RemoteSigned" -ForegroundColor Green
            }
            catch {
                Write-Host "  [!] Note: Some features may require administrator rights" -ForegroundColor Yellow
                Write-Host "  [!] If errors occur, run PowerShell as Administrator and set:" -ForegroundColor Gray
                Write-Host "      Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" -ForegroundColor Cyan
            }
        }
        
        # Kiểm tra lại
        $finalPolicy = Get-ExecutionPolicy -Scope Process
        if ($finalPolicy -notin $allowedPolicies) {
            throw "ExecutionPolicy is still restricted: $finalPolicy"
        }
        
        return $true
    }
    catch {
        Write-Host "  [✗] ExecutionPolicy check failed: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================
# PHASE 1: LOAD SCREEN - HIỆN LOGO ĐƠN GIẢN
# ============================================

function Show-LoadScreen {
    Clear-Host
    
    # Logo đơn giản, không cần quá phức tạp
    Write-Host ""
    Write-Host "              W I N K I T" -ForegroundColor Cyan
    Write-Host "      ----------------------------------" -ForegroundColor Cyan
    Write-Host "        Windows Optimization Toolkit" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "        Starting..." -ForegroundColor Yellow
    Write-Host ""
}

# ============================================
# PHASE 2: DOWNLOAD HELPER
# ============================================

function Get-WebFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$Destination,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 2
    )
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            # WebClient nhanh hơn
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $Destination)
            return $true
        }
        catch {
            if ($i -eq $MaxRetries) {
                return $false
            }
            Start-Sleep -Milliseconds 300
        }
    }
    
    return $false
}

# ============================================
# PHASE 3: BOOTSTRAP CORE
# ============================================

function Initialize-Bootstrap {
    [CmdletBinding()]
    param()
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $runId = [guid]::NewGuid().ToString().Substring(0, 6)
        $tempDir = "$Script:TempBase\$timestamp`_$runId"
        
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        New-Item -ItemType Directory -Path "$tempDir\core" -Force | Out-Null
        New-Item -ItemType Directory -Path "$tempDir\ui" -Force | Out-Null
        New-Item -ItemType Directory -Path "$tempDir\features" -Force | Out-Null
        New-Item -ItemType Directory -Path "$tempDir\assets" -Force | Out-Null
        
        return $tempDir
    }
    catch {
        return $null
    }
}

function Download-RequiredFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TempDir
    )
    
    $successCount = 0
    $totalCount = $Script:RequiredFiles.Count
    
    Write-Host "  [•] Downloading files ($totalCount total)..." -ForegroundColor Gray
    
    foreach ($file in $Script:RequiredFiles) {
        $url = "$Script:GitHubBase/$file"
        $destPath = Join-Path $TempDir $file.Replace("/", "\")
        
        if (Get-WebFile -Url $url -Destination $destPath) {
            $successCount++
            
            # Hiển thị progress đơn giản
            if ($successCount -eq $totalCount) {
                Write-Host "`r  [✓] Downloaded: $successCount/$totalCount files" -ForegroundColor Green
            }
            else {
                Write-Host "`r  [•] Downloaded: $successCount/$totalCount files" -NoNewline -ForegroundColor Gray
            }
        }
        else {
            Write-Host "`r  [✗] Failed to download: $file" -ForegroundColor Red
            return $false
        }
    }
    
    return $true
}

# ============================================
# PHASE 4: START WINKIT LOCALLY - SỬA CÁCH LOAD
# ============================================

function Start-LocalWinKit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TempDir
    )
    
    try {
        # Chuyển thư mục
        Set-Location $TempDir
        
        # DOT-SOURCE Loader.ps1 - KHÔNG dùng Export-ModuleMember
        $loaderPath = "Loader.ps1"
        if (Test-Path $loaderPath) {
            # Đọc nội dung file
            $loaderContent = Get-Content $loaderPath -Raw
            
            # Thực thi trong script block
            $scriptBlock = [scriptblock]::Create($loaderContent)
            & $scriptBlock
            
            # Gọi Start-WinKit
            Start-WinKit
        }
        else {
            throw "Loader.ps1 not found"
        }
    }
    catch {
        throw "Failed to start WinKit: $_"
    }
}

# ============================================
# PHASE 5: CLEANUP
# ============================================

function Cleanup-OldVersions {
    [CmdletBinding()]
    param()
    
    try {
        if (Test-Path $Script:TempBase) {
            $oldDirs = Get-ChildItem -Path $Script:TempBase -Directory -ErrorAction SilentlyContinue | 
                       Sort-Object CreationTime -Descending | 
                       Select-Object -Skip 2
            
            foreach ($dir in $oldDirs) {
                Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {}
}

# ============================================
# MAIN EXECUTION FLOW
# ============================================

function Main {
    # Hiển thị load screen NGAY
    Show-LoadScreen
    
    # FIX ExecutionPolicy trước tiên
    if (-not (Fix-ExecutionPolicy)) {
        Write-Host "`n  [!] ExecutionPolicy issues detected" -ForegroundColor Red
        Write-Host "  [!] Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Khởi tạo bootstrap
    $tempDir = Initialize-Bootstrap
    if (-not $tempDir) {
        Write-Host "  [✗] Failed to create temp directory" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Tải file
    if (-not (Download-RequiredFiles -TempDir $tempDir)) {
        Write-Host "  [✗] Failed to download required files" -ForegroundColor Red
        Write-Host "  [•] Check internet connection and repository URL" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Dọn dẹp
    Cleanup-OldVersions
    
    # Chạy WinKit
    Write-Host "`n  [•] Starting WinKit..." -ForegroundColor Green
    Start-Sleep -Milliseconds 500
    
    Start-LocalWinKit -TempDir $tempDir
}

# ============================================
# ERROR HANDLING - ĐƠN GIẢN
# ============================================

trap {
    Write-Host "`n" + ("—" * 60) -ForegroundColor Red
    Write-Host "ERROR" -ForegroundColor Red
    Write-Host ("—" * 60) -ForegroundColor Red
    Write-Host "Message: $_" -ForegroundColor Yellow
    
    Write-Host "`nTroubleshooting:" -ForegroundColor Cyan
    Write-Host "1. Run PowerShell as Administrator" -ForegroundColor Gray
    Write-Host "2. Check internet connection" -ForegroundColor Gray
    Write-Host "3. Try: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" -ForegroundColor White
    
    Write-Host ""
    Write-Host "Press Enter to close..." -ForegroundColor Gray
    Read-Host
    
    exit 1
}

# ============================================
# ENTRY POINT
# ============================================

# Kiểm tra PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "WinKit requires PowerShell 5.1 or later" -ForegroundColor Red
    exit 1
}

# Set window size nếu có thể
try {
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120, 40)
}
catch {}

# Window title
$host.UI.RawUI.WindowTitle = "WinKit - Windows Optimization Toolkit"

# Chạy chính
Main

exit 0
