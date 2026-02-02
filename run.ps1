# run.ps1 - WinKit Bootstrap Downloader (Improved)
# Single Entry Point: irm https://raw.githubusercontent.com/mkhai2589/winkit/main/run.ps1 | iex

# ============================================
# CONFIGURATION
# ============================================

$Script:GitHubBase = "https://raw.githubusercontent.com/mkhai2589/winkit/main"
$Script:TempBase = "$env:TEMP\WinKit"
$Script:BootstrapStartTime = Get-Date

# ============================================
# PHASE 1: LOAD SCREEN - CỰC NHANH, CỰC GỌN
# ============================================

function Show-LoadScreen {
    Clear-Host
    
    # Logo tối giản, hiển thị NGAY
    $logo = @"
              W I N K I T
---------------------------------------------------------------------------------------------------
        Windows Optimization Toolkit  
        Author: Minh Khai Contact: 0333090930  
"@
    
    # Canh giữa nhanh
    $consoleWidth = if ($host.UI.RawUI.WindowSize.Width -gt 0) { $host.UI.RawUI.WindowSize.Width } else { 120 }
    
    $logoLines = $logo -split "`n"
    foreach ($line in $logoLines) {
        $padding = [math]::Max(0, [math]::Floor(($consoleWidth - $line.Length) / 2))
        Write-Host (" " * $padding + $line) -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host (" " * [math]::Floor(($consoleWidth - 15) / 2) + "Initializing...") -ForegroundColor Yellow
}

# ============================================
# PHASE 2: DOWNLOAD HELPER - CÓ TIMEOUT
# ============================================

function Invoke-FastDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$Destination,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 10
    )
    
    try {
        # Tạo thư mục đích nếu chưa có
        $destDir = Split-Path $Destination -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        # Dùng WebClient để nhanh hơn Invoke-WebRequest
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $Destination)
        
        return $true
    }
    catch {
        # Fallback to Invoke-WebRequest với timeout
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $TimeoutSeconds -ErrorAction Stop
            [System.IO.File]::WriteAllText($Destination, $response.Content)
            return $true
        }
        catch {
            return $false
        }
    }
}

# ============================================
# PHASE 3: BOOTSTRAP CORE - TẢI MANIFEST TRƯỚC
# ============================================

function Initialize-Bootstrap {
    [CmdletBinding()]
    param()
    
    # Tạo thư mục với timestamp cho lần chạy này
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $runId = [guid]::NewGuid().ToString().Substring(0, 8)
    $tempDir = "$Script:TempBase\$timestamp`_$runId"
    
    try {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        return $tempDir
    }
    catch {
        return $null
    }
}

function Get-FileManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TempDir
    )
    
    # Thử tải manifest.json trước
    $manifestUrl = "$Script:GitHubBase/manifest.json"
    $manifestPath = Join-Path $tempDir "manifest.json"
    
    if (Invoke-FastDownload -Url $manifestUrl -Destination $manifestPath) {
        try {
            $manifestContent = Get-Content $manifestPath -Raw -ErrorAction Stop
            $manifest = $manifestContent | ConvertFrom-Json -ErrorAction Stop
            
            # Chuyển đổi thành array của hashtable
            $fileList = @()
            foreach ($file in $manifest.files) {
                $fileList += @{
                    Path = $file
                    Dest = $file.Replace("/", "\")
                }
            }
            
            return $fileList
        }
        catch {
            Write-Host "  [!] Manifest parsing failed, using fallback list" -ForegroundColor Yellow
        }
    }
    
    # Fallback: hard-coded list (giữ nguyên case-sensitive)
    return @(
        @{ Path = "core/Logger.ps1"; Dest = "core\Logger.ps1" },
        @{ Path = "core/Utils.ps1"; Dest = "core\Utils.ps1" },
        @{ Path = "core/Security.ps1"; Dest = "core\Security.ps1" },
        @{ Path = "core/FeatureRegistry.ps1"; Dest = "core\FeatureRegistry.ps1" },
        @{ Path = "core/Interface.ps1"; Dest = "core\Interface.ps1" },
        @{ Path = "ui/Theme.ps1"; Dest = "ui\Theme.ps1" },
        @{ Path = "ui/Logo.ps1"; Dest = "ui\Logo.ps1" },
        @{ Path = "ui/UI.ps1"; Dest = "ui\UI.ps1" },
        @{ Path = "config.json"; Dest = "config.json" },
        @{ Path = "version.json"; Dest = "version.json" },
        @{ Path = "Loader.ps1"; Dest = "Loader.ps1" },
        @{ Path = "Menu.ps1"; Dest = "Menu.ps1" },
        @{ Path = "assets/ascii.txt"; Dest = "assets\ascii.txt" },
        @{ Path = "features/01_CleanSystem.ps1"; Dest = "features\01_CleanSystem.ps1" }
    )
}

function Download-Repository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TempDir,
        
        [Parameter(Mandatory=$true)]
        [array]$FileManifest
    )
    
    $successCount = 0
    $totalCount = $FileManifest.Count
    
    Write-Host "`nDownloading repository ($totalCount files)..." -ForegroundColor Yellow
    
    foreach ($file in $FileManifest) {
        $url = "$Script:GitHubBase/$($file.Path)"
        $destPath = Join-Path $TempDir $file.Dest
        
        # Hiển thị progress đơn giản, không chiếm nhiều dòng
        $percent = [math]::Round(($successCount / $totalCount) * 100)
        Write-Host "`r[$percent%] $(Split-Path $file.Path -Leaf)" -NoNewline -ForegroundColor Gray
        
        if (Invoke-FastDownload -Url $url -Destination $destPath) {
            $successCount++
        }
        else {
            Write-Host "`r[FAIL] $($file.Path)" -ForegroundColor Red
            return $false
        }
    }
    
    Write-Host "`r" + (" " * 50) -NoNewline
    Write-Host "`rDownload complete: $successCount/$totalCount files" -ForegroundColor Green
    
    return $true
}

function Start-LocalWinKit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TempDir
    )
    
    try {
        # Chuyển đến thư mục tạm
        Set-Location $TempDir
        
        # Load và chạy Loader.ps1
        . ".\Loader.ps1"
        Start-WinKit
    }
    catch {
        throw "Failed to start WinKit: $_"
    }
}

# ============================================
# PHASE 4: MAIN EXECUTION FLOW - CÓ PROGRESS RÕ
# ============================================

function Main {
    # Hiển thị logo NGAY LẬP TỨC
    Show-LoadScreen
    
    # Khởi tạo bootstrap
    Write-Host "`nPreparing environment..." -ForegroundColor Yellow
    $tempDir = Initialize-Bootstrap
    if (-not $tempDir) {
        throw "Failed to create temp directory"
    }
    
    Write-Host "  Temp directory: $tempDir" -ForegroundColor Gray
    
    # Lấy manifest và tải file
    $fileManifest = Get-FileManifest -TempDir $tempDir
    if (-not $fileManifest) {
        throw "Failed to get file manifest"
    }
    
    if (-not (Download-Repository -TempDir $tempDir -FileManifest $fileManifest)) {
        throw "Failed to download repository files"
    }
    
    # Dọn dẹp các phiên bản cũ (giữ lại 2 phiên bản gần nhất)
    try {
        $oldDirs = Get-ChildItem -Path $Script:TempBase -Directory -ErrorAction SilentlyContinue | 
                   Sort-Object CreationTime -Descending | 
                   Select-Object -Skip 2
        
        foreach ($dir in $oldDirs) {
            Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Không quan trọng nếu dọn dẹp thất bại
    }
    
    # Chạy WinKit
    Write-Host "`nStarting WinKit..." -ForegroundColor Green
    Start-Sleep -Milliseconds 300
    Clear-Host
    
    Start-LocalWinKit -TempDir $tempDir
}

# ============================================
# EXCEPTION HANDLING - HIỂN THỊ ĐẸP
# ============================================

trap {
    # Hiển thị lỗi đẹp hơn
    Write-Host "`n" + ("=" * 50) -ForegroundColor Red
    Write-Host "BOOTSTRAP ERROR" -ForegroundColor Red
    Write-Host ("=" * 50) -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Yellow
    Write-Host "`nTroubleshooting:" -ForegroundColor Cyan
    Write-Host "1. Check internet connection" -ForegroundColor Gray
    Write-Host "2. Verify repository URL: $Script:GitHubBase" -ForegroundColor Gray
    Write-Host "3. Try running as Administrator" -ForegroundColor Gray
    
    Write-Host "`nPress any key to exit..." -ForegroundColor Gray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    exit 1
}

# ============================================
# ENTRY POINT
# ============================================

# Kiểm tra PowerShell version nhanh
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "WinKit requires PowerShell 5.1 or later" -ForegroundColor Red
    exit 1
}

# Set window title
$host.UI.RawUI.WindowTitle = "WinKit - Windows Optimization Toolkit"

# Resize window nếu có thể
try {
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120, 40)
}
catch {
    # Bỏ qua nếu không resize được
}

# Chạy
Main
