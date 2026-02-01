Write-Host "Disabling Windows Recall..." -ForegroundColor Yellow

$recallKey = "HKLM:\Software\Policies\Microsoft\Windows\Recall"

if (-not (Test-Path $recallKey)) {
    New-Item -Path $recallKey -Force | Out-Null
}

Set-ItemProperty -Path $recallKey -Name "DisableRecall" -Type DWord -Value 1

Write-Host "Recall disabled (policy set)." -ForegroundColor Green
Pause
