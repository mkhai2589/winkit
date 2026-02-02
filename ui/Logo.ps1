# ui/Logo.ps1 - ASCII Logo Renderer

$Global:WinKitLogo = @"
              W I N K I T
      __        ___      _  ___ _ _
      \ \      / (_)_ __| |/ (_) | |
       \ \ /\ / /| | '__| ' /| | | |
        \ V  V / | | |  | . \| | | |
         \_/\_/  |_|_|  |_|\_\_|_|_|

        Windows Optimization Toolkit
        Author: Minh Khai Contact: 0333090930
"@

function Get-Logo {
    [CmdletBinding()]
    param()
    
    return $Global:WinKitLogo
}

function Show-Logo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Centered
    )
    
    $logo = Get-Logo
    $logoLines = $logo -split "`n"
    
    foreach ($line in $logoLines) {
        if ($Centered) {
            $consoleWidth = $host.UI.RawUI.WindowSize.Width
            if ($consoleWidth -gt 0) {
                $padding = [math]::Max(0, [math]::Floor(($consoleWidth - $line.Length) / 2))
                $line = (" " * $padding) + $line
            }
        }
        
        Write-Host $line -ForegroundColor Cyan
    }
}
