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
# PHASE 0: EXECUTION POLICY AUTO FIX
# ============================================

function Set-ExecutionPolicyBootstrap {
    # Set ExecutionPolicy với quyền cao nhất, không hỏi user
    # Chạy TRƯỚC khi download bất kỳ file nào
    
    Write-Host "Setting Execution Policy..." -ForegroundColor Yellow
    
    # Thử từng scope với quyền ưu tiên cao nhất
    $scopes = @("Process", "CurrentUser", "LocalMachine")
    $success = $false
    
    foreach ($scope in $scopes) {
        try {
            # Dùng Unrestricted - quyền cao nhất
            Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope $scope -Force -ErrorAction Stop
            
            # Verify
            $currentPolicy = Get-ExecutionPolicy -Scope $scope
            if ($currentPolicy -eq "Unrestricted") {
                Write-Host "  [✓] ExecutionPolicy set to Unrestricted (Scope: $scope)" -ForegroundColor Green
                $success = $true
                break
            }
        }
        catch {
            Write-Host "  [✗] Failed for scope $scope" -ForegroundColor DarkGray
            # Continue với scope tiếp theo
        }
    }
    
    # Nếu không thành công với standard scopes, thử registry method
    if (-not $success) {
        try {
            $regPath = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell"
            if (Test-Path $regPath) {
                Set-ItemProperty -Path $regPath -Name "ExecutionPolicy" -Value "Unrestricted" -Force -ErrorAction Stop
                Write-Host "  [✓] ExecutionPolicy set via registry" -ForegroundColor Green
                $success = $true
            }
        }
        catch {
            Write-Host "  [✗] Registry method failed" -ForegroundColor DarkGray
        }
    }
    
    return $success
}

# ============================================
# PHASE 0.5: CLEAN OLD LOGS - CHẠY ĐẦU TIÊN
# ============================================

function Clear-OldLogs {
    [CmdletBinding()]
    param()
    
    try {
        $logPath = "$env:TEMP\winkit"
        if (Test-Path $logPath) {
            Get-ChildItem -Path $logPath -Filter "*.log" -File | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Silent fail
    }
}

# ============================================
# PHASE 1: LOAD SCREEN - HIỆN LOGO TỪ Logo.ps1
# ============================================

function Show-LoadScreen {
    Clear-Host
    
    # Logo chính xác từ Logo.ps1 (đã được download)
    $logo = @"
              W I N K I T
      __        ___      _  ___ _ _
      \ \      / (_)_ __| |/ (_) | |
       \ \ /\ / /| | '__| ' /| | | |
        \ V  V / | | |  | . \| | | |
         \_/\_/  |_|_|  |_|\_\_|_|_|

        Windows Optimization Toolkit
        Author: Minh Khai Contact: 0333090930
"@
    
    # Canh giữa
    $consoleWidth = if ($host.UI.RawUI.WindowSize.Width -gt 0) { $host.UI.RawUI.WindowSize.Width } else { 120 }
    
    $logoLines = $logo -split "`n"
    foreach ($line in $logoLines) {
        $padding = [math]::Max(0, [math]::Floor(($consoleWidth - $line.Length) / 2))
        Write-Host (" " * $padding + $line) -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host (" " * [math]::Floor(($consoleWidth - 15) / 2) + "Starting WinKit...") -ForegroundColor Yellow
}

# ============================================
# PHASE 2: DOWNLOAD HELPER - KHÔNG EXPORT
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
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $Destination)
            return $true
        }
        catch {
            if ($i -eq $MaxRetries) {
                return $false
            }
            Start-Sleep -Milliseconds 500
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
        $runId = [guid]::NewGuid().ToString().Substring(0, 8)
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
    
    Write-Host "`n"  # Xuống dòng dưới logo
    
    foreach ($file in $Script:RequiredFiles) {
        $url = "$Script:GitHubBase/$file"
        $destPath = Join-Path $TempDir $file.Replace("/", "\")
        
        # Tạo thư mục cha nếu chưa tồn tại
        $parentDir = Split-Path $destPath -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        
        if (Get-WebFile -Url $url -Destination $destPath) {
            $successCount++
        }
        else {
            Write-Host "`n[✗] Failed to download: $file" -ForegroundColor Red
            return $false
        }
        
        # Hiển thị process chạy không che logo
        $percent = [math]::Round(($successCount / $totalCount) * 100)
        Write-Host "`rDownloading... $percent%" -NoNewline -ForegroundColor Yellow
    }
    
    Write-Host "`r" + (" " * 40) -NoNewline
    Write-Host "`r" -NoNewline
    
    return $true
}

# ============================================
# PHASE 4: START WINKIT LOCALLY - FIX EXPORT
# ============================================

function Start-LocalWinKit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TempDir
    )
    
    try {
        Set-Location $TempDir
        
        # Load Loader.ps1 bằng cách đọc nội dung và thực thi
        $loaderPath = Join-Path $TempDir "Loader.ps1"
        if (Test-Path $loaderPath) {
            $loaderContent = Get-Content $loaderPath -Raw
            
            # Thực thi Loader.ps1 trong scope hiện tại
            $scriptBlock = [scriptblock]::Create($loaderContent)
            . $scriptBlock
            
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
    catch {
        # Silent fail
    }
}

# ============================================
# PHASE 6: ERROR HANDLING GLOBAL
# ============================================

function Show-ErrorScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorMsg
    )
    
    Write-Host "`n" + ("=" * 60) -ForegroundColor Red
    Write-Host "WINKIT BOOTSTRAP ERROR" -ForegroundColor Red
    Write-Host ("=" * 60) -ForegroundColor Red
    Write-Host "Error: $ErrorMsg" -ForegroundColor Yellow
    
    Write-Host "`nTroubleshooting:" -ForegroundColor Cyan
    Write-Host "1. Check internet connection" -ForegroundColor Gray
    Write-Host "2. Run PowerShell as Administrator" -ForegroundColor Gray
    Write-Host "3. Try: Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force" -ForegroundColor White
    Write-Host "4. Check firewall/antivirus settings" -ForegroundColor Gray
    Write-Host "5. Visit: https://github.com/mkhai2589/winkit" -ForegroundColor Gray
    
    Write-Host "`nType 'exit' and press Enter to close..." -ForegroundColor Gray
    while ($true) {
        $input = Read-Host
        if ($input -eq 'exit') { break }
    }
    
    exit 1
}

# ============================================
# MAIN EXECUTION FLOW - ĐƠN GIẢN HÓA
# ============================================

function Main {
    # PHASE 0: AUTO SET EXECUTION POLICY
    $policySet = Set-ExecutionPolicyBootstrap
    if (-not $policySet) {
        Write-Host "  [⚠] ExecutionPolicy may be restrictive" -ForegroundColor Yellow
        Write-Host "  [⚠] Some features may not work correctly" -ForegroundColor Yellow
    }
    
    # PHASE 0.5: Xóa log cũ trước khi bắt đầu
    Clear-OldLogs
    
    # PHASE 1: Hiển thị load screen NGAY
    Show-LoadScreen
    
    # PHASE 2: Khởi tạo bootstrap
    Write-Host "`nInitializing bootstrap..." -ForegroundColor Gray
    $tempDir = Initialize-Bootstrap
    if (-not $tempDir) {
        Show-ErrorScreen "Failed to create temp directory"
        return
    }
    
    Write-Host "  [✓] Temp directory: $tempDir" -ForegroundColor Green
    
    # PHASE 3: Tải file
    Write-Host "`nDownloading WinKit files..." -ForegroundColor Gray
    if (-not (Download-RequiredFiles -TempDir $tempDir)) {
        Show-ErrorScreen "Failed to download required files"
        return
    }
    
    Write-Host "  [✓] All files downloaded successfully" -ForegroundColor Green
    
    # PHASE 4: Dọn dẹp phiên bản cũ
    Write-Host "`nCleaning up old versions..." -ForegroundColor Gray
    Cleanup-OldVersions
    Write-Host "  [✓] Cleanup completed" -ForegroundColor Green
    
    # PHASE 5: Chạy WinKit
    Write-Host "`nStarting WinKit..." -ForegroundColor Gray
    Start-Sleep -Milliseconds 500
    Clear-Host
    
    try {
        Start-LocalWinKit -TempDir $tempDir
    }
    catch {
        Show-ErrorScreen $_
    }
}

# ============================================
# GLOBAL PREPARATION
# ============================================

# Kiểm tra PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "WinKit requires PowerShell 5.1 or later" -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    Write-Host "Please update PowerShell and try again." -ForegroundColor Yellow
    exit 1
}

# Set window size và title
try {
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120, 40)
    $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(120, 1000)
}
catch {
    # Nếu không thể resize, continue
    Write-Host "Note: Could not resize console window" -ForegroundColor DarkYellow
}

# Window title
$host.UI.RawUI.WindowTitle = "WinKit - Windows Optimization Toolkit"

# ============================================
# ENTRY POINT
# ============================================

# Chạy main function
try {
    Main
}
catch {
    Show-ErrorScreen $_
}

exit 0
