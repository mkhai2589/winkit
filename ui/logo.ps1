function Show-Logo {
    $width = 76  # Fixed width for header
    $padding = $global:WK_PADDING
    
    # Calculate centering
    $title = "W I N K I T"
    $subtitle = "Windows Optimization Toolkit"
    $author = "Author: Minh Khai | 0333 090 930"
    
    # Top border
    $borderTop = "╔" + ("═" * ($width - 2)) + "╗"
    $borderBottom = "╚" + ("═" * ($width - 2)) + "╝"
    $emptyLine = "║" + (" " * ($width - 2)) + "║"
    
    # Title with padding
    $titlePadding = [math]::Max(0, ($width - 2 - $title.Length)) / 2
    $leftTitlePad = [math]::Floor($titlePadding)
    $rightTitlePad = [math]::Ceiling($titlePadding)
    $titleLine = "║" + (" " * $leftTitlePad) + $title + (" " * $rightTitlePad) + "║"
    
    # Subtitle with padding
    $subPadding = [math]::Max(0, ($width - 2 - $subtitle.Length)) / 2
    $leftSubPad = [math]::Floor($subPadding)
    $rightSubPad = [math]::Ceiling($subPadding)
    $subtitleLine = "║" + (" " * $leftSubPad) + $subtitle + (" " * $rightSubPad) + "║"
    
    # Author with padding
    $authPadding = [math]::Max(0, ($width - 2 - $author.Length)) / 2
    $leftAuthPad = [math]::Floor($authPadding)
    $rightAuthPad = [math]::Ceiling($authPadding)
    $authorLine = "║" + (" " * $leftAuthPad) + $author + (" " * $rightAuthPad) + "║"
    
    Write-Host "$padding$borderTop" -ForegroundColor Cyan
    Write-Host "$padding$titleLine" -ForegroundColor White
    Write-Host "$padding$subtitleLine" -ForegroundColor Gray
    Write-Host "$padding$emptyLine" -ForegroundColor Cyan
    Write-Host "$padding$authorLine" -ForegroundColor Gray
    Write-Host "$padding$borderBottom" -ForegroundColor Cyan
    Write-Host ""
}
