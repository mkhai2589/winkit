# ==========================================
# WinKit Core Interface
# Abstraction layer for features to interact with core system
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
    
    # Get timestamp
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Format message
    $logMessage = "$time [$Level] [$Feature] - $Message"
    
    # Write to log file
    $logMessage | Out-File -Append -FilePath $global:WK_LOG
    
    # Also show in console for DEBUG level (if needed)
    if ($Level -eq 'DEBUG' -and $global:WK_DEBUG) {
        Write-Host "[DEBUG] $Message" -ForegroundColor DarkGray
    }
}

function Clear-WKLog {
    param()
    
    if (Test-Path $global:WK_LOG) {
        Remove-Item $global:WK_LOG -Force
        Write-WKLog -Message "Log file cleared" -Level INFO -Feature "Interface"
    }
}
#endregion

#region CONFIRMATION INTERFACE
function Get-WKConfirm {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [string]$Title = "Confirmation Required",
        
        [switch]$Dangerous
    )
    
    # Show proper UI for confirmation
    Write-Host "`n" + ("=" * 60) -ForegroundColor DarkGray
    
    if ($Dangerous) {
        Write-Host "⚠️  WARNING: POTENTIALLY DANGEROUS ACTION" -ForegroundColor Red
        Write-Host ("=" * 60) -ForegroundColor DarkGray
    }
    
    Write-Host "$Title" -ForegroundColor Yellow
    Write-Host ("-" * 60) -ForegroundColor DarkGray
    Write-Host "$Message" -ForegroundColor White
    
    if ($Dangerous) {
        Write-Host "`nType 'YES' (uppercase) to confirm: " -ForegroundColor Red -NoNewline
        $confirm = Read-Host
        return ($confirm -eq "YES")
    }
    else {
        Write-Host "`nContinue? [Y/N]: " -ForegroundColor Yellow -NoNewline
        $confirm = Read-Host
        return ($confirm -eq "y" -or $confirm -eq "Y")
    }
}

function Get-WKChoice {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [string[]]$Options,
        
        [int]$Default = 0
    )
    
    Write-Host "`n$Message" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        if ($i -eq $Default) {
            Write-Host "[$i] $($Options[$i]) <DEFAULT>" -ForegroundColor Green
        }
        else {
            Write-Host "[$i] $($Options[$i])" -ForegroundColor White
        }
    }
    
    Write-Host "`nYour choice [$Default]: " -ForegroundColor Yellow -NoNewline
    $input = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($input)) {
        return $Default
    }
    
    if ($input -match '^\d+$' -and [int]$input -lt $Options.Count) {
        return [int]$input
    }
    
    Write-Host "Invalid selection, using default." -ForegroundColor Red
    return $Default
}
#endregion

#region FEATURE METADATA INTERFACE
function Get-WKFeatureMetadata {
    param(
        [string]$FeatureId
    )
    
    # Read config.json
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

function Test-WKFeatureRequirements {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Feature
    )
    
    # Check admin requirement
    if ($Feature.requireAdmin) {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object Security.Principal.WindowsPrincipal($id)
        
        if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw "This feature requires Administrator privileges."
        }
    }
    
    # Check OS requirement (if specified)
    if ($Feature.supportedOS) {
        $currentOS = [System.Environment]::OSVersion.Version.Major
        if ($currentOS -notin $Feature.supportedOS) {
            Write-WKLog -Message "Unsupported OS for feature: $($Feature.id)" -Level WARN
            Write-Host "Warning: This feature is designed for different Windows versions." -ForegroundColor Yellow
            if (-not (Get-WKConfirm -Message "Continue anyway?")) {
                throw "Feature cancelled by user"
            }
        }
    }
    
    return $true
}
#endregion

#region UTILITY INTERFACE
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

function Invoke-WKSafeCommand {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Command,
        
        [string]$ErrorMessage = "Command failed",
        
        [switch]$SuppressErrors
    )
    
    try {
        $output = & $Command
        Write-WKLog -Message "Command executed successfully: $($Command.ToString())" -Level INFO
        return $output
    }
    catch {
        Write-WKLog -Message "$ErrorMessage: $_" -Level ERROR
        
        if (-not $SuppressErrors) {
            Write-Host "ERROR: $ErrorMessage" -ForegroundColor Red
            Write-Host "Details: $_" -ForegroundColor DarkRed
        }
        
        return $null
    }
}

function Format-WKTime {
    param(
        [int]$Seconds
    )
    
    if ($Seconds -lt 60) {
        return "${Seconds}s"
    }
    elseif ($Seconds -lt 3600) {
        $minutes = [math]::Floor($Seconds / 60)
        $remaining = $Seconds % 60
        return "${minutes}m ${remaining}s"
    }
    else {
        $hours = [math]::Floor($Seconds / 3600)
        $minutes = [math]::Floor(($Seconds % 3600) / 60)
        return "${hours}h ${minutes}m"
    }
}
#endregion

#region SYSTEM INFO INTERFACE
function Get-WKSystemInfo {
    $info = @{
        PSVersion = $PSVersionTable.PSVersion.ToString()
        OSVersion = [System.Environment]::OSVersion.Version.ToString()
        MachineName = [System.Environment]::MachineName
        UserName = [System.Environment]::UserName
        Is64Bit = [System.Environment]::Is64BitOperatingSystem
        CurrentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        WKRoot = $global:WK_ROOT
    }
    
    return $info
}

function Test-WKFeatureAvailable {
    param(
        [string]$FeatureId
    )
    
    $features = Get-WKFeatureMetadata
    
    foreach ($feature in $features) {
        if ($feature.id -eq $FeatureId) {
            $featurePath = Join-Path $global:WK_FEATURES $feature.file
            return Test-Path $featurePath
        }
    }
    
    return $false
}
#endregion

#region BACKUP INTERFACE (for future rollback features)
function New-WKBackupPoint {
    param(
        [string]$Description,
        [string]$FeatureId
    )
    
    $backupDir = Join-Path $global:WK_ROOT "backups"
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = Join-Path $backupDir "${timestamp}_${FeatureId}.json"
    
    $backupData = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Description = $Description
        FeatureId = $FeatureId
        SystemInfo = Get-WKSystemInfo
    }
    
    $backupData | ConvertTo-Json | Out-File -FilePath $backupFile
    
    Write-WKLog -Message "Backup point created: $backupFile" -Level INFO -Feature $FeatureId
    return $backupFile
}
#endregion

# Initialize global variables if they don't exist
if (-not $global:WK_LOG) {
    $global:WK_LOG = Join-Path $env:TEMP "winkit.log"
}

if (-not $global:WK_DEBUG) {
    $global:WK_DEBUG = $false
}

# Log interface initialization
Write-WKLog -Message "Interface module initialized" -Level INFO -Feature "Interface"
