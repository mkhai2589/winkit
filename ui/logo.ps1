function Show-Logo {
    $padding = $global:WK_PADDING
    
    Write-Host "$padding------------------------------------------" -ForegroundColor Cyan
    Write-Host "$padding              W I N K I T                 " -ForegroundColor White
    Write-Host "$padding" -ForegroundColor Cyan
    Write-Host "$padding      __        ___      _  ___ _ _" -ForegroundColor Cyan
    Write-Host "$padding      \ \      / (_)_ __| |/ (_) | |" -ForegroundColor Cyan
    Write-Host "$padding       \ \ /\ / /| | '__| ' /| | | |" -ForegroundColor Cyan
    Write-Host "$padding        \ V  V / | | |  | . \| | | |" -ForegroundColor Cyan
    Write-Host "$padding         \_/\_/  |_|_|  |_|\_\_|_|_|" -ForegroundColor Cyan
    Write-Host "$padding" -ForegroundColor Cyan
    Write-Host "$padding        Windows Optimization Toolkit" -ForegroundColor Gray
    Write-Host "$padding------------------------------------------" -ForegroundColor Cyan
}
