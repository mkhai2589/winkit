# ==========================================
# WinKit Interface Module
# Unified user interaction layer
# ==========================================

#region SYSTEM INFO
function Get-WKSystemInfo {
    try {
        $osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $tz = (Get-TimeZone).Id
        
        return @{
            User = [System.Environment]::UserName
            Computer = [System.Environment]::MachineName
            OS = "Windows $([System.Environment]::OSVersion.Version.Major)"
            Build = if ($osInfo) { $osInfo.BuildNumber } else { "Unknown" }
            Arch = if ([System.Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
            Mode = if ($PSVersionTable.PSVersion.Major -ge 7) { "Core" } else { "Desktop" }
            TimeZone = $tz
            Version = "v1.0.0"
        }
    }
    catch {
        return @{
            User = "Unknown"
            Computer = "Unknown"
            OS = "Windows"
            Build = "Unknown"
            Arch = "Unknown"
            Mode = "Unknown"
            TimeZone = "Unknown"
            Version = "v1.0.0"
        }
    }
}
#endregion

#region USER INTERACTION
function Write-WKInfo {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

function Write-WKSuccess {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-WKWarn {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-WKError {
    param([string]$Message)
    Write-Host "[X] $Message" -ForegroundColor Red
}

function Ask-WKConfirm {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [switch]$Dangerous
    )
    
    Write-Host ""
    
    if ($Dangerous) {
        Write-Host "⚠️  DANGEROUS OPERATION" -ForegroundColor Red
        Write-Host ("=" * 50) -ForegroundColor DarkRed
        Write-Host $Message -ForegroundColor White
        Write-Host ("=" * 50) -ForegroundColor DarkRed
        Write-Host "Type 'YES' (uppercase) to confirm: " -ForegroundColor Red -NoNewline
        return (Read-Host) -eq "YES"
    }
    else {
        Write-Host "$Message [y/N]: " -ForegroundColor Yellow -NoNewline
        $input = Read-Host
        return $input -in @('y', 'Y', 'yes', 'YES')
    }
}

function Ask-WKChoice {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [Parameter(Mandatory=$true)]
        [array]$Options
    )
    
    Write-Host "`n$Prompt" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  [$($i+1)] $($Options[$i])" -ForegroundColor Gray
    }
    
    while ($true) {
        Write-Host "`nSelect option [1-$($Options.Count)]: " -ForegroundColor Yellow -NoNewline
        $choice = Read-Host
        
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $Options.Count) {
            return [int]$choice
        }
        
        Write-WKWarn "Invalid selection. Please try again."
    }
}
#endregion

#region FEATURE HELPERS
function Test-WKFeatureAvailable {
    param([string]$FeatureId)
    
    try {
        $configPath = Join-Path $global:WK_ROOT "config.json"
        if (-not (Test-Path $configPath)) { return $false }
        
        $config = Read-Json -Path $configPath
        $feature = $config.features | Where-Object { $_.id -eq $FeatureId }
        
        if (-not $feature) { return $false }
        
        $featurePath = Join-Path $global:WK_FEATURES $feature.file
        return Test-Path $featurePath
    }
    catch {
        return $false
    }
}

function Show-WKProgress {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$Percent = -1
    )
    
    try {
        if ($Percent -ge 0) {
            Write-Progress -Activity $Activity -Status $Status -PercentComplete $Percent
        }
        else {
            Write-Progress -Activity $Activity -Status $Status
        }
    }
    catch {
        # Silent fail for progress display
    }
}

function Complete-WKProgress {
    try {
        Write-Progress -Completed
    }
    catch {
        # Silent fail
    }
}
#endregion
