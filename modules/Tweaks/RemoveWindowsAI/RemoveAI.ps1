$actionRoot = Join-Path $PSScriptRoot "actions"

function Show-RemoveAIMenu {
    Clear-Host
    Write-Host "=== Remove Windows AI ===" -ForegroundColor Cyan
    Write-Host "[1] Disable Copilot"
    Write-Host "[2] Disable Recall"
    Write-Host "[3] Remove AI Appx Packages"
    Write-Host "[4] Remove AI Scheduled Tasks"
    Write-Host "[9] Run ALL"
    Write-Host "[0] Back"
    Write-Host ""
    Write-Host "Select option: " -NoNewline -ForegroundColor Green
}

while ($true) {
    Show-RemoveAIMenu
    $c = Read-Host

    switch ($c) {
        '1' { . "$actionRoot\Disable-Copilot.ps1" }
        '2' { . "$actionRoot\Disable-Recall.ps1" }
        '3' { . "$actionRoot\Remove-AppxAI.ps1" }
        '4' { . "$actionRoot\Remove-AITasks.ps1" }
        '9' {
            . "$actionRoot\Disable-Copilot.ps1"
            . "$actionRoot\Disable-Recall.ps1"
            . "$actionRoot\Remove-AppxAI.ps1"
            . "$actionRoot\Remove-AITasks.ps1"
        }
        '0' { break }
        default {
            Write-Host "Invalid option!" -ForegroundColor Red
            Start-Sleep 1
        }
    }
}
