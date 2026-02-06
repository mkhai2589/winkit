# ============================================================
# WinKit Bootstrap Loader
# Compatible: Windows PowerShell 5.1 + PowerShell 7+
# Entry: irm https://raw.githubusercontent.com/mkhai2589/winkit/main/run.ps1 | iex
# ============================================================

# -----------------------------
# ENV DETECTION
# -----------------------------
$Script:IsPS7 = $PSVersionTable.PSVersion.Major -ge 7

# -----------------------------
# CONFIG
# -----------------------------
$Script:GitHubBase = "https://raw.githubusercontent.com/mkhai2589/winkit/main"
$Script:TempBase   = Join-Path $env:TEMP "WinKit"

$Script:FallbackFiles = @(
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
    "version.json"
)

# -----------------------------
# BASIC UI
# -----------------------------
function Write-Bootstrap {
    param(
        [string]$Message,
        [ValidateSet("INFO","OK","WARN","ERR")]
        [string]$Level = "INFO"
    )

    $color = switch ($Level) {
        "OK"   { "Green" }
        "WARN" { "Yellow" }
        "ERR"  { "Red" }
        default { "Gray" }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $color
}

# -----------------------------
# EXECUTION POLICY (SAFE)
# -----------------------------
function Ensure-ExecutionPolicy {
    try {
        if ((Get-ExecutionPolicy -Scope Process) -ne "Bypass") {
            Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
        }
    } catch {}
}

# -----------------------------
# INTERNET CHECK
# -----------------------------
function Test-Internet {
    try {
        $req = [System.Net.WebRequest]::Create("https://raw.githubusercontent.com")
        $req.Timeout = 5000
        $res = $req.GetResponse()
        $res.Close()
        return $true
    } catch {
        return $false
    }
}

# -----------------------------
# DOWNLOAD FILE
# -----------------------------
function Download-File {
    param($Url, $Dest)

    try {
        $dir = Split-Path $Dest -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        $wc = New-Object System.Net.WebClient
        $wc.Headers["User-Agent"] = "WinKit-Bootstrap"
        $wc.DownloadFile($Url, $Dest)

        return (Test-Path $Dest)
    } catch {
        return $false
    }
}

# -----------------------------
# GET MANIFEST FILE LIST
# -----------------------------
function Get-FileList {
    param($TempDir)

    $manifestUrl  = "$Script:GitHubBase/manifest.json"
    $manifestPath = Join-Path $TempDir "manifest.json"

    if (Download-File $manifestUrl $manifestPath) {
        try {
            $json = Get-Content $manifestPath -Raw | ConvertFrom-Json
            if ($json.files -and $json.files.Count -gt 0) {
                return $json.files
            }
        } catch {}
    }

    return $Script:FallbackFiles
}

# -----------------------------
# CREATE TEMP ENV
# -----------------------------
function Create-TempEnv {
    $id = Get-Date -Format "yyyyMMdd_HHmmss"
    $path = Join-Path $Script:TempBase $id

    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
    }

    New-Item -ItemType Directory -Path $path -Force | Out-Null
    return $path
}

# -----------------------------
# SHOW SPLASH
# -----------------------------
function Show-Splash {
    Clear-Host
    Write-Host ""
    Write-Host "   W I N K I T" -ForegroundColor Cyan
    Write-Host "   Windows Optimization Toolkit" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "   PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
    Write-Host ""
}

# -----------------------------
# LAUNCH CORE
# -----------------------------
function Launch-WinKit {
    param($TempDir)

    Push-Location
    Set-Location $TempDir

    try {
        & "$TempDir\Loader.ps1"
    } finally {
        Pop-Location
    }
}

# -----------------------------
# MAIN
# -----------------------------
function Main {
    Ensure-ExecutionPolicy
    Show-Splash

    Write-Bootstrap "Checking internet..."
    if (-not (Test-Internet)) {
        Write-Bootstrap "No internet connection" "ERR"
        return
    }

    Write-Bootstrap "Preparing environment..."
    $tempDir = Create-TempEnv
    Write-Bootstrap "Temp: $tempDir" "OK"

    $files = Get-FileList $tempDir
    Write-Bootstrap "Downloading $($files.Count) files..."

    foreach ($file in $files) {
        $url  = "$Script:GitHubBase/$file"
        $dest = Join-Path $tempDir ($file -replace '/', '\')

        if (-not (Download-File $url $dest)) {
            Write-Bootstrap "Failed: $file" "WARN"
        }
    }

    if (-not (Test-Path (Join-Path $tempDir "Loader.ps1"))) {
        Write-Bootstrap "Loader.ps1 missing" "ERR"
        return
    }

    Write-Bootstrap "Launching WinKit..." "OK"
    Start-Sleep -Milliseconds 600
    Clear-Host

    Launch-WinKit $tempDir
}

# -----------------------------
# ENTRY
# -----------------------------
Main
