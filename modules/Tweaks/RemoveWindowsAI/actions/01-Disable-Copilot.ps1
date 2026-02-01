Write-Host "Disabling Windows Copilot..." -ForegroundColor Yellow

$paths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
    "HKLM:\Software\Policies\Microsoft\Windows\WindowsCopilot"
)

foreach ($p in $paths) {
    if (-not (Test-Path $p)) {
        New-Item -Path $p -Force | Out-Null
    }
}

Set-ItemProperty `
  -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
  -Name "ShowCopilotButton" -Type DWord -Value 0

Set-ItemProperty `
  -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsCopilot" `
  -Name "TurnOffWindowsCopilot" -Type DWord -Value 1

Write-Host "Copilot disabled." -ForegroundColor Green
Pause
