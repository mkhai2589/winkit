function Start-WinKit {

    while ($true) {
        Show-Header

        foreach ($m in $Global:WinKitModules) {
            Write-Host ("[{0}] {1}" -f $m.Id, $m.Name) -ForegroundColor Cyan
        }

        Write-Host "[0] Exit" -ForegroundColor Red
        Show-Footer

        $input = Read-Host

        if ($input -eq "0") { break }
        if ($input -match '^\d+$') {
            Invoke-WinKitModule ([int]$input)
        }
    }
}
