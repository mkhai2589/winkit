# ui/Logo.ps1
# WinKit ASCII Logo Renderer - No Business Logic

$Global:WinKitLogoData = @{
    ascii = @"
---------------------------------------------------------------------------------------------------
          __        ___ _   _ _  __     _______ ___ _______ 
          \ \      / (_) | (_) |/ /    |_  /_ _|_ _|_   _| |
           \ \ /\ / /| | | | | ' / _____ / / | | | |  | | | |
            \ V  V / | | | | | . \|_____/ /  | | | |  | | |_|
             \_/\_/  |_|_|_|_|_|\_\    /___|___|___| |_| (_)
---------------------------------------------------------------------------------------------------
Windows Optimization Toolkit
"@
    
    boxed = @"
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                                  │
│          __        ___ _   _ _  __     _______ ___ _______                                       │
│          \ \      / (_) | (_) |/ /    |_  /_ _|_ _|_   _| |                                      │
│           \ \ /\ / /| | | | | ' / _____ / / | | | |  | | | |                                     │
│            \ V  V / | | | | | . \|_____/ /  | | | |  | | |_|                                     │
│             \_/\_/  |_|_|_|_|_|\_\    /___|___|___| |_| (_)                                     │
│                                                                                                  │
│                           Windows Optimization Toolkit                                            │
│                                                                                                  │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
"@
    
    simple = @"
W I N K I T
===========
Windows Optimization Toolkit
"@
    
    minimal = @"
WinKit
------
Windows Optimization Toolkit
"@
}

function Get-Logo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('ascii', 'boxed', 'simple', 'minimal')]
        [string]$Style = 'ascii'
    )
    
    Write-Log -Level INFO -Message "Getting logo with style: $Style" -Silent $true
    
    if ($Global:WinKitLogoData.ContainsKey($Style)) {
        return $Global:WinKitLogoData[$Style]
    }
    
    # Fallback to ascii if style not found
    Write-Log -Level WARN -Message "Logo style '$Style' not found, using 'ascii'" -Silent $true
    return $Global:WinKitLogoData['ascii']
}

function Show-Logo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Style = $Global:WinKitConfig.UI.LogoStyle,
        
        [Parameter(Mandatory=$false)]
        [switch]$Centered
    )
    
    $logo = Get-Logo -Style $Style
    
    # Split logo into lines
    $logoLines = $logo -split "`n"
    
    # Get console width for centering
    $consoleWidth = $host.UI.RawUI.WindowSize.Width
    
    foreach ($line in $logoLines) {
        if ($Centered -and $consoleWidth -gt 0) {
            # Center each line
            $padding = [math]::Max(0, [math]::Floor(($consoleWidth - $line.Length) / 2))
            $line = (" " * $padding) + $line
        }
        
        Write-Colored $line -Style Header
    }
}

function Get-LogoHeight {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Style = $Global:WinKitConfig.UI.LogoStyle
    )
    
    $logo = Get-Logo -Style $Style
    return ($logo -split "`n").Count
}

# Export functions
$ExportFunctions = @(
    'Get-Logo',
    'Show-Logo',
    'Get-LogoHeight'
)

Export-ModuleMember -Function $ExportFunctions
