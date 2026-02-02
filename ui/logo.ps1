# ui/Logo.ps1 - Updated to read from assets/ascii.txt

$Global:WinKitLogoData = @{
    default = @"
              W I N K I T
      __        ___      _  ___ _ _
      \ \      / (_)_ __| |/ (_) | |
       \ \ /\ / /| | '__| ' /| | | |
        \ V  V / | | |  | . \| | | |
         \_/\_/  |_|_|  |_|\_\_|_|_|

        Windows Optimization Toolkit
        Author: Minh Khai Contact: 0333090930
"@
}

function Get-Logo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Style = 'default'
    )
    
    # Ưu tiên đọc từ assets/ascii.txt
    $assetsPath = "assets\ascii.txt"
    if (Test-Path $assetsPath) {
        try {
            $logoContent = Get-Content $assetsPath -Raw -ErrorAction Stop
            if (-not [string]::IsNullOrWhiteSpace($logoContent)) {
                return $logoContent
            }
        }
        catch {
            Write-Log -Level WARN -Message "Failed to read logo from assets: $_" -Silent $true
        }
    }
    
    # Fallback to built-in
    if ($Global:WinKitLogoData.ContainsKey($Style)) {
        return $Global:WinKitLogoData[$Style]
    }
    
    return $Global:WinKitLogoData['default']
}

function Show-Logo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Style = 'default',
        
        [Parameter(Mandatory=$false)]
        [switch]$Centered
    )
    
    $logo = Get-Logo -Style $Style
    $logoLines = $logo -split "`n"
    
    foreach ($line in $logoLines) {
        if ($Centered) {
            $consoleWidth = $host.UI.RawUI.WindowSize.Width
            if ($consoleWidth -gt 0) {
                $padding = [math]::Max(0, [math]::Floor(($consoleWidth - $line.Length) / 2))
                $line = (" " * $padding) + $line
            }
        }
        
        Write-Colored $line -Style Header
    }
}
