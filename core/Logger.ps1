# ==========================================
# WinKit Logger Module
# Simple file logging with timestamp
# ==========================================

# Initialize global log path if not already set
if (-not $global:WK_LOG) {
    $global:WK_LOG = Join-Path $env:TEMP "winkit.log"
}

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp [$Level] - $Message"
        
        # Ensure log directory exists
        $logDir = Split-Path $WK_LOG -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        # Write to log file
        $logEntry | Out-File -Append -FilePath $WK_LOG -Encoding UTF8
    }
    catch {
        # Silent fail for logging errors
    }
}
