function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Initialize-Security {
    if (-not (Test-Admin)) {
        Write-Warn "WinKit is NOT running as Administrator"
    }
}
