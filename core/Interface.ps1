function Write-Separator {
    Write-Host ("-" * $WK_CONFIG.ui.menuWidth) -ForegroundColor DarkGray
}

function Write-CategoryHeader($Text) {
    Write-Host "[$Text]" -ForegroundColor Cyan
}

function Write-MenuItem($Index, $Text) {
    Write-Host ("[{0}] {1}" -f $Index, $Text)
}

function Write-ErrorBox($Text) {
    Write-Host $Text -ForegroundColor Red
}
