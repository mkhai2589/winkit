# =========================================================
# core/Logger.ps1
# WinKit Logger
#
# PURPOSE:
# - Centralized logging
# - File + Console (optional)
#
# ❌ NO business logic
# ❌ NO feature logic
# ❌ NO UI dependency
#
# Logger = side-effect only (write log)
# =========================================================

# =========================================================
# GLOBAL LOGGER CONFIG
# =========================================================
if (-not $Global:WinKitLoggerConfig) {
    $Global:WinKitLoggerConfig = @{
        Enabled      = $true
        LogPath      = "$env:TEMP\winkit"
        FileName     = "winkit.log"
        MinLevel     = "INFO"
        WriteConsole = $false
    }
}

# =========================================================
# LOG LEVEL MAP
# =========================================================
$script:LogLevels = @{
    DEBUG = 1
    INFO  = 2
    WARN  = 3
    ERROR = 4
}

# =========================================================
# INITIALIZE LOGGER
# =========================================================
function Initialize-Logger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    # Merge config (override defaults)
    foreach ($key in $Config.Keys) {
        $Global:WinKitLoggerConfig[$key] = $Config[$key]
    }

    # Ensure log directory exists
    try {
        if (-not (Test-Path $Global:WinKitLoggerConfig.LogPath)) {
            New-Item -ItemType Directory -Path $Global:WinKitLoggerConfig.LogPath -Force | Out-Null
        }
    }
    catch {
        # Logger must NEVER crash app
        return $false
    }

    Write-Log -Level INFO -Message "Logger initialized" -Silent $true
    return $true
}

# =========================================================
# CORE WRITE LOG
# =========================================================
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [bool]$Silent = $false
    )

    # Logger disabled
    if (-not $Global:WinKitLoggerConfig.Enabled) {
        return
    }

    # Level filtering
    $minLevel = $Global:WinKitLoggerConfig.MinLevel
    if ($script:LogLevels[$Level] -lt $script:LogLevels[$minLevel]) {
        return
    }

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "[$timestamp][$Level] $Message"

    # Write to file
    try {
        $logFile = Join-Path `
            $Global:WinKitLoggerConfig.LogPath `
            $Global:WinKitLoggerConfig.FileName

        Add-Content -Path $logFile -Value $entry -Encoding UTF8
    }
    catch {
        # Never throw from logger
    }

    # Optional console output
    if (-not $Silent -and $Global:WinKitLoggerConfig.WriteConsole) {
        Write-Host $entry
    }
}

# =========================================================
# LOG PATH HELPER (READ-ONLY)
# =========================================================
function Get-LogPath {
    $path = Join-Path `
        $Global:WinKitLoggerConfig.LogPath `
        $Global:WinKitLoggerConfig.FileName

    return $path
}

# =========================================================
# MODULE EXPORT
# =========================================================
if ($MyInvocation.InvocationName -ne '.') {
    Export-ModuleMember -Function `
        Initialize-Logger, `
        Write-Log, `
        Get-LogPath
}
