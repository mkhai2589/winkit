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
# PHASE 0: EXECUTION POLICY FIX - CHẠY NGAY ĐẦU
# ============================================

function Initialize-ExecutionPolicy {
    [CmdletBinding()]
    param()
    
    try {
        $currentPolicy = Get-ExecutionPolicy -Scope Process -ErrorAction Stop
        
        # Danh sách policies cho phép chạy script
        $allowedPolicies = @('RemoteSigned', 'Unrestricted', 'Bypass')
        
        if ($currentPolicy -notin $allowedPolicies) {
            Write-Host "  [!] Current ExecutionPolicy: $currentPolicy" -ForegroundColor Yellow
            Write-Host "  [!] Temporarily setting to Bypass for this session..." -ForegroundColor Yellow
            
            # Thử set policy cho process hiện tại (không cần admin)
            Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
            
            Write-Host "  [!] ExecutionPolicy set to: Bypass (Process scope)" -ForegroundColor Green
            return $true
        }
        
        return $true
    }
    catch {
        Write-Host "  [!] Failed to set ExecutionPolicy: $_" -ForegroundColor Red
        
        # Hướng dẫn người dùng
        Write-Host "`n=== REQUIRED ACTION ===" -ForegroundColor Red
        Write-Host "1. Run PowerShell AS ADMINISTRATOR" -ForegroundColor Yellow
        Write-Host "2. Run this command:" -ForegroundColor Cyan
        Write-Host "   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" -ForegroundColor White
        Write-Host "3. Then run WinKit again.`n" -ForegroundColor Yellow
        
        return $false
    }
}

# ============================================
# PHASE 1: LOAD SCREEN - CỰC NHANH
# ============================================

function Show-LoadScreen {
    Clear-Host
    
    $logo = @"
              W I N K I T
---------------------------------------------------------------------------------------------------
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
    Write-Host (" " * [math]::Floor(($consoleWidth - 15) / 2) + "Initializing...") -ForegroundColor Yellow
}

# ============================================
# PHASE 2: DOWNLOAD HELPER - RETRY 2 LẦN
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
            # WebClient nhanh hơn Invoke-WebRequest
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $Destination)
            return $true
        }
        catch {
            if ($i -eq $MaxRetries) {
                Write-Host "  [!] Failed to download: $Url" -ForegroundColor Red
                return $false
            }
            
            # Thử lại sau 0.5s
            Start-Sleep -Milliseconds 500
        }
    }
    
    return $false
}

# ============================================
# PHASE 3: BOOTSTRAP CORE - TẢI FILE
# ============================================

function Initialize-Bootstrap {
    [CmdletBinding()]
    param()
    
    try {
        # Tạo thư mục với timestamp
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
        Write-Host "  [!] Failed to create temp directory: $_" -ForegroundColor Red
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
    
    Write-Host "`nDownloading files..." -ForegroundColor Yellow
    
    foreach ($file in $Script:RequiredFiles) {
        $fileName = Split-Path $file -Leaf
        $url = "$Script:GitHubBase/$file"
        $destPath = Join-Path $TempDir $file.Replace("/", "\")
        
        # Hiển thị progress đơn giản
        $percent = [math]::Round(($successCount / $totalCount) * 100)
        Write-Host "`r[$percent%] $fileName" -NoNewline -ForegroundColor Gray
        
        if (Get-WebFile -Url $url -Destination $destPath) {
            $successCount++
        }
        else {
            return $false
        }
    }
    
    Write-Host "`r" + (" " * 50) -NoNewline
    Write-Host "`rDownloaded: $successCount/$totalCount files" -ForegroundColor Green
    
    return $true
}

# ============================================
# PHASE 4: START WINKIT LOCALLY
# ============================================

function Start-LocalWinKit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TempDir
    )
    
    try {
        # Chuyển đến thư mục tạm
        Set-Location $TempDir
        
        # Dot-source Loader.ps1 (KHÔNG dùng .\)
        $loaderPath = Join-Path $TempDir "Loader.ps1"
        if (Test-Path $loaderPath) {
            # Read file content và execute
            $loaderContent = Get-Content $loaderPath -Raw
            Invoke-Expression $loaderContent
            
            # Gọi Start-WinKit
            Start-WinKit
        }
        else {
            throw "Loader.ps1 not found in temp directory"
        }
    }
    catch {
        throw "Failed to start WinKit: $_"
    }
}

# ============================================
# PHASE 5: CLEANUP OLD VERSIONS
# ============================================

function Cleanup-OldVersions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$KeepLast = 2
    )
    
    try {
        if (Test-Path $Script:TempBase) {
            $oldDirs = Get-ChildItem -Path $Script:TempBase -Directory -ErrorAction SilentlyContinue | 
                       Sort-Object CreationTime -Descending | 
                       Select-Object -Skip $KeepLast
            
            foreach ($dir in $oldDirs) {
                Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        # Ignore cleanup errors
    }
}

# ============================================
# MAIN EXECUTION FLOW
# ============================================

function Main {
    # Hiển thị logo NGAY
    Show-LoadScreen
    
    # PHASE 0: Fix ExecutionPolicy
    Write-Host "`nChecking environment..." -ForegroundColor Yellow
    if (-not (Initialize-ExecutionPolicy)) {
        throw "ExecutionPolicy check failed"
    }
    
    # PHASE 1: Khởi tạo bootstrap
    $tempDir = Initialize-Bootstrap
    if (-not $tempDir) {
        throw "Failed to initialize bootstrap"
    }
    
    Write-Host "  Temp directory: $tempDir" -ForegroundColor Gray
    
    # PHASE 2: Tải file
    if (-not (Download-RequiredFiles -TempDir $tempDir)) {
        throw "Failed to download required files"
    }
    
    # PHASE 3: Dọn dẹp cũ
    Cleanup-OldVersions -KeepLast 2
    
    # PHASE 4: Chạy WinKit
    Write-Host "`nStarting WinKit..." -ForegroundColor Green
    Start-Sleep -Milliseconds 500
    Clear-Host
    
    Start-LocalWinKit -TempDir $tempDir
}

# ============================================
# ERROR HANDLING
# ============================================

trap {
    Write-Host "`n" + ("=" * 50) -ForegroundColor Red
    Write-Host "BOOTSTRAP ERROR" -ForegroundColor Red
    Write-Host ("=" * 50) -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Yellow
    
    Write-Host "`nTroubleshooting steps:" -ForegroundColor Cyan
    Write-Host "1. Run PowerShell AS ADMINISTRATOR" -ForegroundColor Gray
    Write-Host "2. Run this command:" -ForegroundColor Gray
    Write-Host "   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
    Write-Host "3. Then try again.`n" -ForegroundColor Gray
    
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
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

# Set window size
try {
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120, 40)
    $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(120, 1000)
}
catch {
    # Bỏ qua nếu không resize được
}

# Set window title
$host.UI.RawUI.WindowTitle = "WinKit - Windows Optimization Toolkit"

# Chạy
Main

# Exit clean
exit 0
