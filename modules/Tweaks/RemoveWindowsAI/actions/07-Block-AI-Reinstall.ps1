Write-Host "Blocking AI reinstall via Windows Update..." -ForegroundColor Yellow

$wu = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

if (-not (Test-Path $wu)) {
    New-Item -Path $wu -Force | Out-Null
}

# Disable feature updates auto install
Set-ItemProperty -Path $wu -Name "DisableOSUpgrade" -Type DWord -Value 1

# Block cloud content
$cloud = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
if (-not (Test-Path $cloud)) {
    New-Item -Path $cloud -Force | Out-Null
}

Set-ItemProperty -Path $cloud -Name "DisableCloudOptimizedContent" -Type DWord -Value 1
Set-ItemProperty -Path $cloud -Name "DisableWindowsConsumerFeatures" -Type DWord -Value 1

Write-Host "AI reinstall blocked (policy-based)." -ForegroundColor Green
Pause
