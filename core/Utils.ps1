# core/Utils.ps1
# Common Utilities - String, Layout, System Info Helpers

function Format-String {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text,
        
        [Parameter(Mandatory=$false)]
        [int]$Width = 120,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Left', 'Center', 'Right')]
        [string]$Align = 'Left',
        
        [Parameter(Mandatory=$false)]
        [string]$PaddingChar = ' '
    )
    
    if ($Text.Length -ge $Width) {
        return $Text.Substring(0, $Width)
    }
    
    $padLength = $Width - $Text.Length
    
    switch ($Align) {
        'Left' {
            return $Text + ($PaddingChar * $padLength)
        }
        'Center' {
            $leftPad = [math]::Floor($padLength / 2)
            $rightPad = $padLength - $leftPad
            return ($PaddingChar * $leftPad) + $Text + ($PaddingChar * $rightPad)
        }
        'Right' {
            return ($PaddingChar * $padLength) + $Text
        }
    }
}

function Get-DiskInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$DriveLetter = "C:"
    )
    
    try {
        $disk = Get-PSDrive -Name $DriveLetter -ErrorAction Stop
        $totalGB = [math]::Round($disk.Free + $disk.Used / 1GB, 2)
        $freeGB = [math]::Round($disk.Free / 1GB, 2)
        $usedPercent = [math]::Round(($disk.Used / ($disk.Free + $disk.Used)) * 100, 1)
        
        return @{
            TotalGB = $totalGB
            FreeGB = $freeGB
            UsedPercent = $usedPercent
            Drive = $DriveLetter
        }
    }
    catch {
        return @{
            TotalGB = 0
            FreeGB = 0
            UsedPercent = 0
            Drive = $DriveLetter
            Error = $_.Exception.Message
        }
    }
}

function Test-IsElevated {
    [CmdletBinding()]
    param()
    
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-FormattedSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [double]$Bytes
    )
    
    $units = @('B', 'KB', 'MB', 'GB', 'TB')
    $unitIndex = 0
    
    while ($Bytes -ge 1024 -and $unitIndex -lt $units.Length - 1) {
        $Bytes /= 1024
        $unitIndex++
    }
    
    return "{0:N2} {1}" -f $Bytes, $units[$unitIndex]
}

function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock]$ScriptBlock,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 3,
        
        [Parameter(Mandatory=$false)]
        [int]$RetryDelay = 1000
    )
    
    $retryCount = 0
    $lastError = $null
    
    while ($retryCount -le $MaxRetries) {
        try {
            return & $ScriptBlock
        }
        catch {
            $lastError = $_
            $retryCount++
            
            if ($retryCount -le $MaxRetries) {
                Write-Log -Level WARN -Message "Retry $retryCount/$MaxRetries after error: $_" -Silent $true
                Start-Sleep -Milliseconds $RetryDelay
            }
        }
    }
    
    throw $lastError
}

function Format-TimeSpan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [TimeSpan]$TimeSpan
    )
    
    if ($TimeSpan.TotalMinutes -lt 1) {
        return "$([math]::Round($TimeSpan.TotalSeconds, 1)) seconds"
    }
    elseif ($TimeSpan.TotalHours -lt 1) {
        return "$([math]::Round($TimeSpan.TotalMinutes, 1)) minutes"
    }
    else {
        return "$([math]::Round($TimeSpan.TotalHours, 1)) hours"
    }
}

# Export module functions
$ExportFunctions = @(
    'Format-String',
    'Get-DiskInfo',
    'Test-IsElevated',
    'Get-FormattedSize',
    'Invoke-WithRetry',
    'Format-TimeSpan'
)

Export-ModuleMember -Function $ExportFunctions
