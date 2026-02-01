$global:WK_LOG = Join-Path $env:TEMP "winkit.log"

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    
    try {
        $logEntry | Out-File -FilePath $WK_LOG -Append -Encoding UTF8
    }
    catch {}
}
