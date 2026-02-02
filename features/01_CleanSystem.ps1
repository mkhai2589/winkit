Register-Feature `
    -Id "CleanSystem" `
    -Title "Clean System" `
    -Description "Remove temp files and caches" `
    -Category "Essential" `
    -Order 1 `
    -FileName "01_CleanSystem.ps1" `
    -Execute { Start-CleanSystem }

function Start-CleanSystem {
    Write-Host "Clean System feature loaded successfully."
    Write-Host "Logic will be implemented later."
}
