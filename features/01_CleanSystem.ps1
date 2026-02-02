Register-Feature `
    -Id "CleanSystem" `
    -Title "Clean System" `
    -Description "Clean temporary files and caches" `
    -Category "Essential" `
    -Order 1 `
    -FileName "01_CleanSystem.ps1" `
    -Execute { Start-CleanSystem }

function Start-CleanSystem {
    Write-Padded "Clean System - Not implemented yet" "Yellow"
}
