Write-Host "Removing AI Optional Features..." -ForegroundColor Yellow

$features = Get-WindowsOptionalFeature -Online |
    Where-Object {
        $_.FeatureName -match "Recall|AI|Copilot"
    }

foreach ($f in $features) {
    if ($f.State -ne "Disabled") {
        Write-Host "Disabling feature: $($f.FeatureName)" -ForegroundColor DarkGray
        try {
            Disable-WindowsOptionalFeature `
                -Online `
                -FeatureName $f.FeatureName `
                -NoRestart `
                -ErrorAction Stop
        } catch {
            Write-Host "Failed: $($f.FeatureName)" -ForegroundColor Red
        }
    }
}

Write-Host "Optional feature cleanup done." -ForegroundColor Green
Pause
