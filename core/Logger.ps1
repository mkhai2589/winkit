$global:WK_LOG = Join-Path $env:TEMP "winkit.log"

function Write-Log {
    param($Message)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time - $Message" | Out-File -Append $WK_LOG
}
