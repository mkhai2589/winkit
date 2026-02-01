function Invoke-WinKitModule($Id) {

    $m = $Global:WinKitModules | Where-Object { $_.Id -eq $Id }

    if (-not $m) {
        Write-ErrorMsg "Invalid option"
        Pause
        return
    }

    if ($m.RequireAdmin -and -not (Test-Admin)) {
        Write-ErrorMsg "This module requires Administrator"
        Pause
        return
    }

    if ($m.SupportedOS -and ($Global:WinKitEnv.OS -notin $m.SupportedOS)) {
        Write-ErrorMsg "Module not supported on your OS"
        Pause
        return
    }

    Clear-Host
    Write-Info "Running: $($m.Name)"
    . $m.Entry
    Pause
}
