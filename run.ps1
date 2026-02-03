# run.ps1 - WinKit Bootstrap Downloader
# Single Entry Point: irm https://raw.githubusercontent.com/mkhai2589/winkit/main/run.ps1 | iex

# ============================================
# CONFIGURATION
# ============================================

$Script:GitHubBase = "https://raw.githubusercontent.com/mkhai2589/winkit/main"
$Script:TempBase = "$env:TEMP\WinKit"
$Script:RequiredFiles = @(
    "core/Logger.ps1",
    "core/Utils.ps1", 
    "core/Security.ps1",
    "core/FeatureRegistry.ps1",
    "core/Interface.ps1",
    "ui/Theme.ps1",
    "ui/Logo.ps1", 
    "ui/UI.ps1",
    "Loader.ps1",
    "Menu.ps1",
    "config.json",
    "manifest.json",
    "version.json",
    "assets/ascii.txt",
    "features/01_CleanSystem.ps1"
)

# ============================================
# UTILITY FUNCTIONS
# ============================================

function Write-BootstrapStatus {
    param([string]$Message, [string]$Type = "info")
    
    $prefix = switch ($Type) {
        "success" { "[OK]" }
        "error"   { "[ERR]" }
        "warn"    { "[WARN]" }
        default   { "[INFO]" }
    }
    
    $color = switch ($Type) {
        "success" { "Green" }
        "error"   { "Red" }
        "warn"    { "Yellow" }
        default   { "Gray" }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Test-InternetConnection {
    try {
        $testUrls = @("https://raw.githubusercontent.com", "https://github.com", "https://google.com")
        foreach ($url in $testUrls) {
            try {
                $request = [System.Net.WebRequest]::Create($url)
                $request.Timeout = 5000
                $response = $request.GetResponse()
                $response.Close()
                return $true
            }
            catch {
                continue
            }
        }
        return $false
    }
    catch {
        return $false
    }
}

# ============================================
# PHASE 0: EXECUTION POLICY - FORCE UNLOCK
# ============================================

function Set-ExecutionPolicyForce {
    Write-BootstrapStatus "Setting Execution Policy (Unrestricted)..." -Type "info"
    
    # Thử tất cả các scope với quyền cao nhất
    $scopes = @("Process", "CurrentUser", "LocalMachine")
    $success = $false
    
    foreach ($scope in $scopes) {
        try {
            # Set policy với force
            Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope $scope -Force -ErrorAction Stop
            
            # Verify
            $currentPolicy = Get-ExecutionPolicy -Scope $scope
            if ($currentPolicy -eq "Unrestricted" -or $currentPolicy -eq "Bypass") {
                Write-BootstrapStatus "ExecutionPolicy set to $currentPolicy ($scope)" -Type "success"
                $success = $true
                break
            }
        }
        catch {
            Write-BootstrapStatus "Failed for scope $scope" -Type "warn"
            continue
        }
    }
    
    # Phương pháp cuối cùng: Direct Registry
    if (-not $success) {
        try {
            $registryPaths = @(
                "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell",
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell",
                "HKCU:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell"
            )
            
            foreach ($regPath in $registryPaths) {
                if (Test-Path $regPath) {
                    Set-ItemProperty -Path $regPath -Name "ExecutionPolicy" -Value "Unrestricted" -Force -ErrorAction Stop
                    Write-BootstrapStatus "ExecutionPolicy set via registry: $regPath" -Type "success"
                    $success = $true
                    break
                }
            }
        }
        catch {
            Write-BootstrapStatus "Registry method also failed" -Type "warn"
        }
    }
    
    return $success
}

# ============================================
# PHASE 1: LOAD SCREEN
# ============================================

function Show-LoadScreen {
    Clear-Host
    
    # Logo ASCII cố định
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
    Write-Host (" " * [math]::Floor(($consoleWidth - 20) / 2) + "Initializing WinKit...") -ForegroundColor Yellow
}

# ============================================
# PHASE 2: DOWNLOAD ENGINE
# ============================================

function Get-WebFileRobust {
    param(
        [string]$Url,
        [string]$Destination,
        [int]$MaxRetries = 3
    )
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            # Sử dụng WebClient với timeout
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "WinKit-Bootstrap/1.0")
            $webClient.DownloadFile($Url, $Destination)
            
            # Verify file downloaded
            if (Test-Path $Destination -PathType Leaf) {
                $fileSize = (Get-Item $Destination).Length
                if ($fileSize -gt 0) {
                    return $true
                }
            }
            
            Remove-Item $Destination -Force -ErrorAction SilentlyContinue
        }
        catch {
            if ($i -eq $MaxRetries) {
                Write-BootstrapStatus "Download failed: $Url" -Type "warn"
                return $false
            }
            Start-Sleep -Milliseconds (500 * $i)
        }
    }
    
    return $false
}

function Download-ManifestFirst {
    param([string]$TempDir)
    
    # Download manifest.json đầu tiên để biết file list
    $manifestUrl = "$Script:GitHubBase/manifest.json"
    $manifestPath = Join-Path $TempDir "manifest.json"
    
    if (Get-WebFileRobust -Url $manifestUrl -Destination $manifestPath) {
        if (Test-Path $manifestPath) {
            try {
                $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
                if ($manifest.files -and $manifest.files.Count -gt 0) {
                    return $manifest.files
                }
            }
            catch {
                Write-BootstrapStatus "Invalid manifest, using default files" -Type "warn"
            }
        }
    }
    
    return $Script:RequiredFiles
}

function Download-FileList {
    param(
        [string]$TempDir,
        [array]$FileList
    )
    
    $totalFiles = $FileList.Count
    $successCount = 0
    $failedFiles = @()
    
    Write-Host ""
    Write-BootstrapStatus "Downloading $totalFiles files..." -Type "info"
    
    for ($i = 0; $i -lt $totalFiles; $i++) {
        $file = $FileList[$i]
        $url = "$Script:GitHubBase/$file"
        $destPath = Join-Path $TempDir $file.Replace("/", "\")
        
        # Tạo thư mục nếu chưa có
        $parentDir = Split-Path $destPath -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        
        # Hiển thị progress
        $percent = [math]::Round((($i + 1) / $totalFiles) * 100)
        Write-Host "`r  Progress: $percent% ($($i + 1)/$totalFiles)" -NoNewline -ForegroundColor Yellow
        
        if (Get-WebFileRobust -Url $url -Destination $destPath) {
            $successCount++
        }
        else {
            $failedFiles += $file
        }
    }
    
    Write-Host "`r" + (" " * 50) -NoNewline
    Write-Host "`r"
    
    return @{
        SuccessCount = $successCount
        TotalFiles = $totalFiles
        FailedFiles = $failedFiles
    }
}

# ============================================
# PHASE 3: BOOTSTRAP SETUP
# ============================================

function Initialize-Bootstrap {
    Write-BootstrapStatus "Creating bootstrap environment..." -Type "info"
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $runId = Get-Random -Minimum 1000 -Maximum 9999
        $tempDir = "$Script:TempBase\$timestamp`_$runId"
        
        # Xóa thư mục cũ nếu tồn tại
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Tạo cấu trúc thư mục
        $dirs = @("core", "ui", "features", "assets")
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        foreach ($dir in $dirs) {
            New-Item -ItemType Directory -Path "$tempDir\$dir" -Force | Out-Null
        }
        
        Write-BootstrapStatus "Bootstrap directory: $tempDir" -Type "success"
        return $tempDir
    }
    catch {
        Write-BootstrapStatus "Failed to create temp directory: $_" -Type "error"
        return $null
    }
}

# ============================================
# PHASE 4: VALIDATION
# ============================================

function Validate-Downloads {
    param([string]$TempDir, [array]$FileList)
    
    Write-BootstrapStatus "Validating downloaded files..." -Type "info"
    
    $missingFiles = @()
    foreach ($file in $FileList) {
        $localPath = Join-Path $TempDir $file.Replace("/", "\")
        if (-not (Test-Path $localPath)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -eq 0) {
        Write-BootstrapStatus "All files validated successfully" -Type "success"
        return $true
    }
    else {
        Write-BootstrapStatus "Missing files: $($missingFiles.Count)" -Type "error"
        foreach ($missing in $missingFiles) {
            Write-BootstrapStatus "  - $missing" -Type "warn"
        }
        return $false
    }
}

# ============================================
# PHASE 5: LAUNCH
# ============================================

function Launch-WinKit {
    param([string]$TempDir)
    
    try {
        # Lưu thư mục hiện tại
        $originalLocation = Get-Location
        
        # Chuyển đến thư mục temp
        Set-Location $TempDir
        
        Write-BootstrapStatus "Launching WinKit..." -Type "info"
        Start-Sleep -Milliseconds 500
        Clear-Host
        
        # Thực thi Loader.ps1 trực tiếp
        & "$TempDir\Loader.ps1"
        
        # Restore location
        Set-Location $originalLocation
    }
    catch {
        throw "Launch failed: $_"
    }
}

# ============================================
# PHASE 6: CLEANUP
# ============================================

function Cleanup-OldVersions {
    try {
        if (Test-Path $Script:TempBase) {
            $oldDirs = Get-ChildItem -Path $Script:TempBase -Directory -ErrorAction SilentlyContinue | 
                       Sort-Object CreationTime -Descending | 
                       Select-Object -Skip 3
            
            foreach ($dir in $oldDirs) {
                Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            # Clean temp logs
            Get-ChildItem -Path "$env:TEMP" -Filter "winkit*.log" -ErrorAction SilentlyContinue | 
                Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-1) } |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Silent cleanup failure
    }
}

# ============================================
# ERROR HANDLER
# ============================================

function Show-ErrorHandler {
    param([string]$ErrorMessage)
    
    Clear-Host
    Write-Host ""
    Write-Host "  " + ("=" * 60) -ForegroundColor Red
    Write-Host "  WINKIT BOOTSTRAP FAILURE" -ForegroundColor Red
    Write-Host "  " + ("=" * 60) -ForegroundColor Red
    Write-Host ""
    Write-Host "  Error: $ErrorMessage" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "  Common Solutions:" -ForegroundColor Cyan
    Write-Host "  1. Internet Connection: Ensure you're online" -ForegroundColor Gray
    Write-Host "  2. Administrator: Right-click PowerShell -> Run as Administrator" -ForegroundColor Gray
    Write-Host "  3. Execution Policy: Run this command then retry:" -ForegroundColor Gray
    Write-Host "     Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force" -ForegroundColor White
    Write-Host "  4. Firewall/Antivirus: Temporarily disable to test" -ForegroundColor Gray
    Write-Host "  5. Manual Download: Visit https://github.com/mkhai2589/winkit" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Diagnostic Info:" -ForegroundColor Cyan
    Write-Host "  PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
    Write-Host "  OS: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor Gray
    Write-Host "  Admin: $(if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {'Yes'} else {'No'})" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "  " + ("=" * 60) -ForegroundColor Red
    Write-Host ""
    Read-Host "  Press Enter to exit"
    
    exit 1
}

# ============================================
# MAIN EXECUTION FLOW
# ============================================

function Main {
    try {
        # STEP 0: Basic checks
        if ($PSVersionTable.PSVersion.Major -lt 5) {
            Show-ErrorHandler "PowerShell 5.1+ required. Current: $($PSVersionTable.PSVersion)"
        }
        
        # STEP 1: Force Execution Policy
        Set-ExecutionPolicyForce | Out-Null
        
        # STEP 2: Show loading screen
        Show-LoadScreen
        Start-Sleep -Milliseconds 300
        
        # STEP 3: Check internet
        Write-BootstrapStatus "Checking internet connection..." -Type "info"
        if (-not (Test-InternetConnection)) {
            Show-ErrorHandler "No internet connection detected"
        }
        
        # STEP 4: Create bootstrap environment
        $tempDir = Initialize-Bootstrap
        if (-not $tempDir) {
            Show-ErrorHandler "Failed to create bootstrap directory"
        }
        
        # STEP 5: Get file list from manifest
        $fileList = Download-ManifestFirst -TempDir $tempDir
        
        # STEP 6: Download all files
        $downloadResult = Download-FileList -TempDir $tempDir -FileList $fileList
        
        if ($downloadResult.SuccessCount -eq 0) {
            Show-ErrorHandler "Failed to download all files"
        }
        elseif ($downloadResult.FailedFiles.Count -gt 0) {
            Write-BootstrapStatus "Partial download: $($downloadResult.SuccessCount)/$($downloadResult.TotalFiles)" -Type "warn"
        }
        else {
            Write-BootstrapStatus "All files downloaded successfully" -Type "success"
        }
        
        # STEP 7: Validate critical files
        $criticalFiles = @("Loader.ps1", "Menu.ps1", "config.json", "core/Logger.ps1")
        foreach ($file in $criticalFiles) {
            $path = Join-Path $tempDir $file.Replace("/", "\")
            if (-not (Test-Path $path)) {
                Show-ErrorHandler "Critical file missing: $file"
            }
        }
        
        # STEP 8: Cleanup old versions
        Cleanup-OldVersions
        
        # STEP 9: Launch WinKit
        Write-Host ""
        Write-BootstrapStatus "Starting WinKit in 2 seconds..." -Type "info"
        Start-Sleep -Seconds 2
        
        Launch-WinKit -TempDir $tempDir
    }
    catch {
        Show-ErrorHandler $_
    }
}

# ============================================
# PREPARATION
# ============================================

try {
    # Set window size
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120, 40)
    $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(120, 1000)
}
catch {
    # Ignore if cannot resize
}

$host.UI.RawUI.WindowTitle = "WinKit - Windows Optimization Toolkit v1.0"

# ============================================
# ENTRY POINT
# ============================================

Main
