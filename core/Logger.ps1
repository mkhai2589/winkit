function Write-Log($Message, $Level="INFO") {
    $line = "[{0}] [{1}] {2}" -f (Get-Date), $Level, $Message
    Add-Content $WK_LOG $line
}
