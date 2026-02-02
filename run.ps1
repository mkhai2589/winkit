# run.ps1 - WinKit Bootstrap Downloader
# Single Entry Point: irm https://raw.githubusercontent.com/mkhai2589/winkit/main/run.ps1 | iex

# ============================================
# PHASE 1: LOAD SCREEN (SPLASH) - CHỈ TRÌNH DIỄN
# ============================================

function Show-LoadScreen {
    [CmdletBinding()]
    param()
    
    Clear-Host
    
    # Logo đề xuất (ASCII only, canh giữa tuyệt đối)
    $logo = @"
---------------------------------------------------------------------------------------------------
              W I N K I T
      __        ___      _  ___ _ _
      \ \      / (_)_ __| |/ (_) | |
       \ \ /\ / /| | '__| ' /| | | |
        \ V  V / | | |  | . \| | | |
         \_/\_/  |_|_|  |_|\_\_|_|_|

        Windows Optimization Toolkit
        Author: Minh Khai Contact: 0333090930
---------------------------------------------------------------------------------------------------
"@
    
    # Canh giữa từng dòng
    $consoleWidth = $host.UI.RawUI.WindowSize.Width
    if ($consoleWidth -le 0) { $consoleWidth = 120 }
    
    $logoLines = $logo -split "`n"
    foreach ($line in $logoLines) {
        $padding = [math]::Max(0, [math]::Floor(($consoleWidth - $line.Length) / 2))
        Write-Host (" " * $padding + $line) -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host (" " * [math]::Floor(($consoleWidth - 20) / 2) + "Initializing...") -ForegroundColor Yellow
}

# ============================================
# PHASE 2: BOOTSTRAP DOWNLOADER
# ============================================

function Initialize-Bootstrap {
    [CmdletBinding()]
    param()
    
    # Tạo thư mục tạm cho WinKit
    $tempBase = "$env:TEMP\WinKit"
    $tempDir = "$tempBase\$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
    try {
        # Tạo thư mục
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            New-Item -ItemType Directory -Path "$tempDir\core" -Force | Out-Null
            New-Item -ItemType Directory -Path "$tempDir\ui" -Force | Out-Null
            New-Item -ItemType Directory -Path "$tempDir\features" -Force | Out-Null
            New-Item -ItemType Directory -Path "$tempDir\assets" -Force | Out-Null
        }
        
        return $tempDir
    }
    catch {
        Write-Host "Failed to create temp directory: $_" -ForegroundColor Red
        return $null
    }
}

function Download-RepoFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$RelativePath,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath,
        
        [Parameter(Mandatory=$false)]
        [int]$RetryCount = 3
    )
    
    $baseUrl = "https://raw.githubusercontent.com/mkhai2589/winkit/main"
    $url = "$baseUrl/$RelativePath"
    
    for ($i = 0; $i -lt $RetryCount; $i++) {
        try {
            # Tải file từ GitHub Raw
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
            
            # Đảm bảo thư mục đích tồn tại
            $destDir = Split-Path $DestinationPath -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            
            # Lưu file
            [System.IO.File]::WriteAllText($DestinationPath, $response.Content)
            
            return $true
        }
        catch {
            if ($i -eq $RetryCount - 1) {
                Write-Host "Failed to download $RelativePath after $RetryCount attempts: $_" -ForegroundColor Red
                return $false
            }
            Start-Sleep -Milliseconds 500
        }
    }
    
    return $false
}

function Download-EntireRepo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TempDir
    )
    
    # Danh sách file CẦN THIẾT để chạy
    $fileManifest = @(
        # Core modules
        @{ Path = "core/Logger.ps1"; Dest = "core\Logger.ps1" },
        @{ Path = "core/Utils.ps1"; Dest = "core\Utils.ps1" },
        @{ Path = "core/Security.ps1"; Dest = "core\Security.ps1" },
        @{ Path = "core/FeatureRegistry.ps1"; Dest = "core\FeatureRegistry.ps1" },
        @{ Path = "core/Interface.ps1"; Dest = "core\Interface.ps1" },
        
        # UI modules
        @{ Path = "ui/Theme.ps1"; Dest = "ui\Theme.ps1" },
        @{ Path = "ui/Logo.ps1"; Dest = "ui\Logo.ps1" },
        @{ Path = "ui/UI.ps1"; Dest = "ui\UI.ps1" },
        
        # Config files
        @{ Path = "config.json"; Dest = "config.json" },
        @{ Path = "version.json"; Dest = "version.json" },
        
        # Main scripts
        @{ Path = "Loader.ps1"; Dest = "Loader.ps1" },
        @{ Path = "Menu.ps1"; Dest = "Menu.ps1" },
        
        # Assets
        @{ Path = "assets/ascii.txt"; Dest = "assets\ascii.txt" },
        
        # Features (mẫu - ít nhất 1 feature để test)
        @{ Path = "features/01_CleanSystem.ps1"; Dest = "features\01_CleanSystem.ps1" }
    )
    
    $successCount = 0
    $totalCount = $fileManifest.Count
    
    foreach ($file in $fileManifest) {
        $destPath = Join-Path $TempDir $file.Dest
        
        # Hiển thị progress không phá logo
        $percent = [math]::Round(($successCount / $totalCount) * 100)
        Write-Host "`r" + (" " * 50) -NoNewline
        Write-Host "`rDownloading: $percent%" -ForegroundColor Yellow -NoNewline
        
        if (Download-RepoFile -RelativePath $file.Path -DestinationPath $destPath) {
            $successCount++
        }
    }
    
    Write-Host "`r" + (" " * 50) -NoNewline
    Write-Host "`rDownloaded: $successCount/$totalCount files" -ForegroundColor Green
    
    return ($successCount -eq $totalCount)
}

function Cleanup-OldTempDirs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$KeepLast = 3
    )
    
    $tempBase = "$env:TEMP\WinKit"
    if (Test-Path $tempBase) {
        $oldDirs = Get-ChildItem -Path $tempBase -Directory | Sort-Object CreationTime -Descending
        
        if ($oldDirs.Count -gt $KeepLast) {
            $toDelete = $oldDirs | Select-Object -Skip $KeepLast
            
            foreach ($dir in $toDelete) {
                try {
                    Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
                }
                catch {
                    # Ignore cleanup errors
                }
            }
        }
    }
}

# ============================================
# PHASE 3: MAIN EXECUTION FLOW
# ============================================

function Main {
    [CmdletBinding()]
    param()
    
    try {
        # PHASE 1: Hiển thị Load Screen
        Show-LoadScreen
        
        # Delay nhẹ cho cảm giác chắc chắn
        Start-Sleep -Milliseconds 300
        
        # PHASE 2: Khởi tạo Bootstrap
        $tempDir = Initialize-Bootstrap
        if (-not $tempDir) {
            throw "Failed to initialize bootstrap directory"
        }
        
        # PHASE 3: Tải toàn bộ repo
        Write-Host "`nPreparing WinKit environment..." -ForegroundColor Yellow
        
        if (-not (Download-EntireRepo -TempDir $tempDir)) {
            throw "Failed to download required files"
        }
        
        # PHASE 4: Dọn dẹp temp cũ
        Cleanup-OldTempDirs -KeepLast 3
        
        # PHASE 5: Chuyển sang thư mục tạm và chạy Loader
        Set-Location $tempDir
        
        # PHASE 6: Load và chạy Loader.ps1
        Write-Host "`nStarting WinKit..." -ForegroundColor Green
        
        # Clear screen trước khi vào main UI
        Clear-Host
        
        # Dot-source Loader.ps1
        . ".\Loader.ps1"
        
        # Start WinKit
        Start-WinKit
        
    }
    catch {
        Write-Host "`n=== BOOTSTRAP ERROR ===" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host "`nPlease check your internet connection and try again." -ForegroundColor Yellow
        
        # Giữ màn hình cho người dùng đọc lỗi
        Write-Host "`nPress any key to exit..." -ForegroundColor Gray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        exit 1
    }
}

# ============================================
# ENTRY POINT
# ============================================

# Kiểm tra PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "WinKit requires PowerShell 5.1 or later." -ForegroundColor Red
    exit 1
}

# Set window size cơ bản
try {
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120, 40)
    $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(120, 40)
}
catch {
    # Non-critical error, continue
}

# Set window title
$host.UI.RawUI.WindowTitle = "WinKit - Windows Optimization Toolkit"

# Chạy main
Main

# Exit clean
exit 0
