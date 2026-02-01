Write-Host "Removing AI Appx packages..." -ForegroundColor Yellow

$packages = Get-AppxPackage -AllUsers |
    Where-Object {
        $_.Name -match "Copilot|WindowsAI|AIHub|Recall"
    }

foreach ($pkg in $packages) {
    Write-Host "Removing $($pkg.Name)" -ForegroundColor DarkGray
    try {
        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
    } catch {
        Write-Host "Failed: $($pkg.Name)" -ForegroundColor Red
    }
}

Write-Host "Appx cleanup done." -ForegroundColor Green
Pause
