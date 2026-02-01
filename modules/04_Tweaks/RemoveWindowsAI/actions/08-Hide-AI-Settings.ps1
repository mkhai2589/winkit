Write-Host "Hiding AI related settings pages..." -ForegroundColor Yellow

$policy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingsPageVisibility"

if (-not (Test-Path $policy)) {
    New-Item -Path $policy -Force | Out-Null
}

Set-ItemProperty `
  -Path $policy `
  -Name "SettingsPageVisibility" `
  -Value "hide:ai;copilot;privacy-ai;recall"

Write-Host "AI settings hidden." -ForegroundColor Green
Pause
