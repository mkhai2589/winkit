function Show-Logo {
    $width = 76  # Fixed width for header
    $padding = $global:WK_PADDING
    
    # Tính toán centering với ký tự ASCII
    $title = "W I N K I T"
    $subtitle = "Windows Optimization Toolkit"
    $author = "Author: Minh Khai | 0333 090 930"
    
    # Tạo border với ký tự ASCII
    $borderTop = "=" * $width
    $borderBottom = "=" * $width
    
    # Tạo các dòng nội dung
    $titleLine = "  " + $title.PadLeft(($width + $title.Length) / 2).PadRight($width)
    $subtitleLine = "  " + $subtitle.PadLeft(($width + $subtitle.Length) / 2).PadRight($width)
    $emptyLine = "  " + (" " * ($width - 4))
    $authorLine = "  " + $author.PadLeft(($width + $author.Length) / 2).PadRight($width)
    
    Write-Host "$padding$borderTop" -ForegroundColor Cyan
    Write-Host "$padding$titleLine" -ForegroundColor White
    Write-Host "$padding$subtitleLine" -ForegroundColor Gray
    Write-Host "$padding$emptyLine" -ForegroundColor Cyan
    Write-Host "$padding$authorLine" -ForegroundColor Gray
    Write-Host "$padding$borderBottom" -ForegroundColor Cyan
    Write-Host ""
}
