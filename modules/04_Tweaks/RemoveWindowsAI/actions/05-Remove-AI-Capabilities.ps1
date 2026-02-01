Write-Host "Removing AI Capabilities (CBS)..." -ForegroundColor Yellow

$capabilities = Get-WindowsCapability -Online |
    Where-Object {
        $_.Name -match "Copilot|Recall|AI|Insights"
    }

foreach ($cap in $capabilities) {
    if ($cap.State -ne "NotPresent") {
        Write-Host "Removing capability: $($cap.Name)" -ForegroundColor DarkGray
        try {
            Remove-WindowsCapability -Online -Name $cap.Name -ErrorAction Stop
        } catch {
            Write-Host "Failed: $($cap.Name)" -ForegroundColor Red
        }
    }
}

Write-Host "CBS capabilities removal done." -ForegroundColor Green
Pause
