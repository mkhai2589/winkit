# ==========================================
# WinKit Core Interface
# Abstraction layer for features
# ==========================================

#region LOGGING INTERFACE
function Write-WKLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO',
        
        [string]$Feature = 'System'
    )
    
    try {
        $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "$time [$Level] [$Feature] - $Message"
        $logMessage | Out-File -Append -FilePath $global:WK_LOG
    }
    catch {
        # Silent fail for logging errors
    }
}

function Clear-WKLog {
    try {
        if (Test-Path $global:WK_LOG) {
            Remove-Item $global:WK_LOG -Force
        }
    }
    catch {}
}
#endregion

#region USER INTERACTION
function Get-WKConfirm {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [switch]$Dangerous
    )
    
    Write-Host ""
    
    if ($Dangerous) {
        Write-Host "⚠️  WARNING: CRITICAL OPERATION" -ForegroundColor Red
        Write-Host "----------------------------------------" -ForegroundColor DarkRed
        Write-Host "$Message" -ForegroundColor White
        Write-Host "Type 'YES' (uppercase) to confirm: " -ForegroundColor Red -NoNewline
        $confirm = Read-Host
        return ($confirm -eq "YES")
    }
    else {
        Write-Host "$Message [y/N]: " -ForegroundColor Yellow -NoNewline
        $confirm = Read-Host
        return ($confirm -eq "y" -or $confirm -eq "Y")
    }
}

function Pause-WK {
    param(
        [string]$Message = "Press Enter to continue..."
    )
    
    Write-Host ""
    Write-Host $Message -ForegroundColor DarkGray
    [Console]::ReadKey($true)
}
#endregion

#region FEATURE METADATA
function Get-WKFeatureMetadata {
    param([string]$FeatureId)
    
    $configPath = Join-Path $global:WK_ROOT "config.json"
    if (-not (Test-Path $configPath)) {
        throw "Configuration file not found"
    }
    
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    
    if ($FeatureId) {
        return $config.features | Where-Object { $_.id -eq $FeatureId }
    }
    
    return $config.features
}

function Test-WKFeatureAvailable {
    param([string]$FeatureId)
    
    $feature = Get-WKFeatureMetadata -FeatureId $FeatureId
    if (-not $feature) { return $false }
    
    $featurePath = Join-Path $global:WK_FEATURES $feature.file
    return Test-Path $featurePath
}
#endregion

#region UTILITIES
function Show-WKProgress {
    param(
        [string]$Activity,
        [string]$Status,
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

function Get-WKChoice {
    param(
        [string]$Prompt,
        [array]$Options
    )
    
    Write-Host "`n$Prompt" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  [$($i+1)] $($Options[$i])" -ForegroundColor Gray
    }
    
    while ($true) {
        Write-Host "`nSelect option [1-$($Options.Count)]: " -ForegroundColor Yellow -NoNewline
        $choice = Read-Host
        
        if ($choice -match '^\d+$') {
            $num = [int]$choice
            if ($num -ge 1 -and $num -le $Options.Count) {
                return $num
            }
        }
        
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
    }
}
#endregion

# Initialize if needed
if (-not $global:WK_LOG) {
    $global:WK_LOG = Join-Path $env:TEMP "winkit.log"
}
