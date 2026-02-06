# =========================================================
# core/Utils.ps1
# WinKit Common Utilities
#
# PURPOSE:
# - Pure helper functions
# - String / System / Retry / Format helpers
#
# ❌ No business logic
# ❌ No UI dependency
# ❌ No global state
#
# All functions must be deterministic & reusable
# =========================================================

# =========================================================
# STRING FORMATTER
# =========================================================
function Format-String {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [int]$Width = 120,

        [ValidateSet('Left', 'Center', 'Right')]
        [string]$Align = 'Left',

        [char]$PaddingChar = ' '
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
            $left = [math]::Floor($padLength / 2)
            $right = $padLength - $left
            return ($PaddingChar * $left) + $Text + ($PaddingChar * $right)
        }
        'Right' {
            return ($PaddingChar * $padLength) + $Text
        }
    }
}

# =========================================================
# DISK INFORMATION (SAFE)
# =========================================================
function Get-DiskInfo {
    [CmdletBinding()]
    param(
        [string]$DriveLetter = "C"
    )

    try {
        $drive = Get-PSDrive -Name $DriveLetter -ErrorAction Stop
        $total = $drive.Used + $drive.Free

        return @{
            Drive       = "$DriveLetter:"
            TotalGB     = [math]::Round($total / 1GB, 2)
            FreeGB      = [math]::Round($drive.Free / 1GB, 2)
            UsedPercent = if ($total -gt 0) {
                [math]::Round(($drive.Used / $total) * 100, 1)
            } else {
                0
            }
        }
    }
    catch {
        return @{
            Drive       = "$DriveLetter:"
            TotalGB     = 0
            FreeGB      = 0
            UsedPercent = 0
            Error       = $_.Exception.Message
        }
    }
}

# =========================================================
# ADMIN CHECK (PURE)
# =========================================================
function Test-IsElevated {
    [CmdletBinding()]
    param()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity

    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

# =========================================================
# BYTE SIZE FORMATTER
# =========================================================
function Get-FormattedSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [double]$Bytes
    )

    $units = @('B', 'KB', 'MB', 'GB', 'TB')
    $index = 0

    while ($Bytes -ge 1024 -and $index -lt ($units.Count - 1)) {
        $Bytes /= 1024
        $index++
    }

    return "{0:N2} {1}" -f $Bytes, $units[$index]
}

# =========================================================
# INVOKE WITH RETRY (CONTROLLED SIDE-EFFECT)
# =========================================================
function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ScriptBlock]$ScriptBlock,

        [int]$MaxRetries = 3,
        [int]$RetryDelay = 1000
    )

    $attempt = 0
    $lastError = $null

    while ($attempt -lt $MaxRetries) {
        try {
            return & $ScriptBlock
        }
        catch {
            $lastError = $_
            $attempt++

            Write-Log `
                -Level WARN `
                -Message "Retry $attempt/$MaxRetries failed: $($_.Exception.Message)" `
                -Silent $true

            Start-Sleep -Milliseconds $RetryDelay
        }
    }

    throw $lastError
}

# =========================================================
# TIMESAPN FORMATTER
# =========================================================
function Format-TimeSpan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [TimeSpan]$TimeSpan
    )

    if ($TimeSpan.TotalSeconds -lt 60) {
        return "{0:N1} seconds" -f $TimeSpan.TotalSeconds
    }

    if ($TimeSpan.TotalMinutes -lt 60) {
        return "{0:N1} minutes" -f $TimeSpan.TotalMinutes
    }

    return "{0:N1} hours" -f $TimeSpan.TotalHours
}

# =========================================================
# MODULE EXPORT
# =========================================================
if ($MyInvocation.InvocationName -ne '.') {
    Export-ModuleMember -Function `
        Format-String, `
        Get-DiskInfo, `
        Test-IsElevated, `
        Get-FormattedSize, `
        Invoke-WithRetry, `
        Format-TimeSpan
}
