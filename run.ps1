# =========================================================
# run.ps1 - WinKit Bootstrap (FINAL)
# Single Entry Point: irm https://raw.githubusercontent.com/mkhai2589/winkit/main/run.ps1 | iex
# =========================================================

$Script:GitHubBase = "https://raw.githubusercontent.com/mkhai2589/winkit/main"
$Script:TempDir = "$env:TEMP\WinKit_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

function Write-BootstrapStatus {
    param([string]$Message, [string]$Type = "info")
    
    $color = switch ($Type) {
        "success" { "Green" }
        "error"   { "Red" }
        "warn"    { "Yellow" }
        default   { "Gray" }
    }
    
    Write-Host "$Message" -ForegroundColor $color
}

function Initialize-Environment {
    if (Test-Path $Script:TempDir) {
        Remove-Item $Script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $Script:TempDir -Force | Out-Null
    
    @("core", "ui", "features", "assets") | ForEach-Object {
        New-Item -ItemType Directory -Path "$Script:TempDir\$_" -Force | Out-Null
    }
    
    Write-BootstrapStatus "[OK] Bootstrap directory created" -Type "success"
}

function Download-File {
    param([string]$Url, [string]$Destination)
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "WinKit-Bootstrap/1.0")
        $webClient.DownloadFile($Url, $Destination)
        return $true
    }
    catch {
        return $false
    }
}

function Download-RequiredFiles {
    $requiredFiles = @(
        "Loader.ps1", "App.ps1", "Menu.ps1",
        "config.json", "manifest.json", "version.json",
        "core/Context.ps1", "core/Logger.ps1", "core/Utils.ps1",
        "core/Security.ps1", "core/FeatureRegistry.ps1", "core/Interface.ps1",
        "ui/Logo.ps1", "ui/Theme.ps1", "ui/UI.ps1",
        "features/01_CleanSystem.ps1", "features/02_ActivationTool.ps1"
    )
    
    $successCount = 0
    $totalFiles = $requiredFiles.Count
    
    Write-BootstrapStatus "[INFO] Downloading $totalFiles files..." -Type "info"
    
    foreach ($file in $requiredFiles) {
        $url = "$Script:GitHubBase/$file"
        $destination = Join-Path $Script:TempDir $file.Replace("/", "\")
        
        $parentDir = Split-Path $destination -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        
        if (Download-File -Url $url -Destination $destination) {
            $successCount++
        }
        else {
            Write-BootstrapStatus "[WARN] Failed: $file" -Type "warn"
        }
    }
    
    return @{ Success = $successCount; Total = $totalFiles }
}

function Validate-CriticalFiles {
    $criticalFiles = @(
        "Loader.ps1", "App.ps1", "Menu.ps1",
        "config.json", "core/Logger.ps1",
        "core/Context.ps1", "core/FeatureRegistry.ps1"
    )
    
    foreach ($file in $criticalFiles) {
        $path = Join-Path $Script:TempDir $file.Replace("/", "\")
        if (-not (Test-Path $path)) {
            return $false, "Missing critical file: $file"
        }
    }
    
    return $true, "All critical files present"
}

function Main {
    # Set console title
    $host.UI.RawUI.WindowTitle = "WinKit - Windows Optimization Toolkit"
    
    # Show loading screen
    Clear-Host
    Write-Host ""
    Write-Host " " * 30 + "W I N K I T" -ForegroundColor Cyan
    Write-Host " " * 25 + "Windows Optimization Toolkit" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " " * 28 + "Loading..." -ForegroundColor Gray
    Write-Host ""
    
    # Step 1: Initialize environment
    Write-BootstrapStatus "[INFO] Initializing environment..." -Type "info"
    Initialize-Environment
    
    # Step 2: Download files
    $downloadResult = Download-RequiredFiles
    if ($downloadResult.Success -lt ($downloadResult.Total * 0.8)) {
        Write-BootstrapStatus "[ERR] Download failed: $($downloadResult.Success)/$($downloadResult.Total)" -Type "error"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Step 3: Validate critical files
    $validation = Validate-CriticalFiles
    if (-not $validation[0]) {
        Write-BootstrapStatus "[ERR] $($validation[1])" -Type "error"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Step 4: Change to temp directory
    Set-Location $Script:TempDir
    
    # ✅ BẮT BUỘC: Loader phải được gọi
    Write-BootstrapStatus "[INFO] Loading core modules..." -Type "info"
    
    try {
        # Load Loader.ps1
        . "$Script:TempDir\Loader.ps1"
        
        # Initialize modules
        Initialize-Modules
        
        Write-BootstrapStatus "[OK] Modules loaded successfully" -Type "success"
    }
    catch {
        Write-BootstrapStatus "[ERR] Failed to load modules: $_" -Type "error"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Step 5: Start the application
    Write-BootstrapStatus "[OK] Starting WinKit..." -Type "success"
    Start-Sleep -Seconds 1
    
    try {
        # Load and execute App.ps1
        . "$Script:TempDir\App.ps1"
        Start-WinKit
    }
    catch {
        Write-BootstrapStatus "[ERR] Application error: $_" -Type "error"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # ✅ KHÔNG cleanup ở đây - App đã tự cleanup khi exit
}

# Entry point
Main
