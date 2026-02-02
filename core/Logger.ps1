function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "FATAL")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoConsole
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to file
    try {
        Add-Content -Path $global:WK_LOG -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # If log file write fails, try to create directory
        $logDir = Split-Path $global:WK_LOG -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            Add-Content -Path $global:WK_LOG -Value $logEntry -ErrorAction SilentlyContinue
        }
    }
    
    # Write to console if requested
    if (-not $NoConsole) {
        $color = switch ($Level) {
            "ERROR"   { "Red" }
            "WARN"    { "Yellow" }
            "INFO"    { "White" }
            "DEBUG"   { "Gray" }
            "FATAL"   { "Red" }
            default   { "White" }
        }
        
        $consoleMessage = "[$Level] $Message"
        Write-Host $consoleMessage -ForegroundColor $color
    }
}
