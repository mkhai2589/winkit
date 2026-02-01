Write-Host "FULL REMOVE WINDOWS AI" -ForegroundColor Red
Write-Host "This will remove AI deeply from Windows." -ForegroundColor Red
Write-Host "Continue? (Y/N): " -NoNewline -ForegroundColor Yellow

if ((Read-Host).ToUpper() -ne "Y") {
    return
}

$steps = @(
    "01-Disable-Copilot.ps1",
    "02-Disable-Recall.ps1",
    "03-Remove-AppxAI.ps1",
    "04-Remove-AITasks.ps1",
    "05-Remove-AI-Capabilities.ps1",
    "06-Remove-AI-OptionalFeatures.ps1",
    "07-Block-AI-Reinstall.ps1",
    "08-Hide-AI-Settings.ps1"
)

foreach ($s in $steps) {
    Write-Host ">> Running $s" -ForegroundColor Cyan
    . (Join-Path $PSScriptRoot $s)
}

Write-Host "FULL AI REMOVAL COMPLETE." -ForegroundColor Green
Pause
