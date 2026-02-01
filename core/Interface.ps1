# ==========================================
# WinKit Core Interface - OPTIMIZED
# ==========================================

#region LOGGING INTERFACE
function Write-WKLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO',
        
        [string]$Feature = 'System'
    )
    
    try {
        $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "$time [$Level] [$Feature] - $Message"
        
        # Ensure log file exists
        $logDir = Split-Path $global:WK_LOG -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        $logMessage | Out-File -Append -FilePath $global:WK_LOG -Encoding UTF8
    }
    catch {
        # Silent fail for logging errors
    }
}
#endregion

#region USER INTERACTION
function Get-WKConfirm {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [switch]$Dangerous,
        [switch]$DefaultYes
    )
    
    Write-Host ""
    
    if ($Dangerous) {
        Write-Host "⚠️  WARNING: CRITICAL OPERATION" -ForegroundColor Red
        Write-Host "----------------------------------------" -ForegroundColor DarkRed
        Write-Host "$Message" -ForegroundColor White
        Write-Host "Type 'YES' to confirm: " -ForegroundColor Red -NoNewline
        $confirm = Read-Host
        return ($confirm -eq "YES")
    }
    else {
        if ($DefaultYes) {
            Write-Host "$Message [Y/n]: " -ForegroundColor Yellow -NoNewline
        }
        else {
            Write-Host "$Message [y/N]: " -ForegroundColor Yellow -NoNewline
        }
        
        $confirm = Read-Host
        $confirm = $confirm.Trim().ToLower()
        
        if ([string]::IsNullOrEmpty($confirm)) {
            return $DefaultYes
        }
        
        return ($confirm -eq "y" -or $confirm -eq "yes")
    }
}

function Pause-WK {
    param(
        [string]$Message = "Press Enter to continue..."
    )
    
    Write-Host ""
    Write-Host $Message -ForegroundColor DarkGray
    [Console]::ReadKey($true) | Out-Null
}
#endregion

#region FEATURE HELPERS
function Test-WKFeatureAvailable {
    param([string]$FeatureId)
    
    try {
        $configPath = Join-Path $global:WK_ROOT "config.json"
        if (-not (Test-Path $configPath)) {
            return $false
        }
        
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
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
        [string]$Status = "Processing...",
        [int]$PercentComplete = -1
    )
    
    if ($PercentComplete -ge 0) {
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    }
    else {
        Write-Progress -Activity $Activity -Status $Status
    }
}

function Complete-WKProgress {
    Write-Progress -Completed
}
#endregion
