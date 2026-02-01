$actionRoot = Join-Path $PSScriptRoot "actions"

function Run($file) {
    . (Join-Path $actionRoot $file)
}

while ($true) {
    Clear-Host
    Write-Host "=== Remove Windows AI (ADVANCED) ===" -ForegroundColor Cyan
    Write-Host "[1] Disable Copilot (Registry + Policy)"
    Write-Host "[2] Disable Recall"
    Write-Host "[3] Remove AI Appx Packages"
    Write-Host "[4] Remove AI Scheduled Tasks"
    Write-Host "[5] Remove AI Capabilities (CBS)"
    Write-Host "[6] Remove AI Optional Features"
    Write-Host "[7] Block AI Reinstall (Windows Update)"
    Write-Host "[8] Hide AI Settings Pages"
    Write-Host "[9] FULL REMOVE (ALL ABOVE)"
    Write-Host "[0] Back"
    Write-Host ""
    Write-Host "Select option: " -NoNewline -ForegroundColor Green

    switch (Read-Host) {
        '1' { Run "01-Disable-Copilot.ps1" }
        '2' { Run "02-Disable-Recall.ps1" }
        '3' { Run "03-Remove-AppxAI.ps1" }
        '4' { Run "04-Remove-AITasks.ps1" }
        '5' { Run "05-Remove-AI-Capabilities.ps1" }
        '6' { Run "06-Remove-AI-OptionalFeatures.ps1" }
        '7' { Run "07-Block-AI-Reinstall.ps1" }
        '8' { Run "08-Hide-AI-Settings.ps1" }
        '9' { Run "99-Full-Remove.ps1" }
        '0' { break }
    }
}
