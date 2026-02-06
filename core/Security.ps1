# core/Security.ps1
# Security and System Requirement Checks - CHECK ONLY, NO MODIFICATIONS

# Ensure Write-Log exists (fallback for early loading)
if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    function Write-Log {
        param($Level, $Message, $Silent)
        # Fallback - write to temp file if Logger not loaded
        $tempLog = "$env:TEMP\winkit-security-fallback.log"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $tempLog -Value "[$timestamp] [$Level] $Message" -Force
    }
}

# ====================
# CHECK FUNCTIONS (ONLY)
# ====================

function Test-IsAdmin {
    [CmdletBinding()]
    param()
    
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        Write-Log -Level INFO -Message "Admin check result: $isAdmin" -Silent $true
        return $isAdmin
    } catch {
        Write-Log -Level ERROR -Message "Admin check failed: $_" -Silent $true
        return $false
    }
}

function Test-PowerShellVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$MinimumVersion = 5
    )
    
    $psVersion = $PSVersionTable.PSVersion.Major
    $isValid = $psVersion -ge $MinimumVersion
    
    Write-Log -Level INFO -Message "PowerShell version check: $psVersion (Minimum: $MinimumVersion) - Valid: $isValid" -Silent $true
    
    return [PSCustomObject]@{
        IsValid = $isValid
        CurrentVersion = $psVersion
        MinimumVersion = $MinimumVersion
    }
}

function Test-IsOnline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$TestHost = "8.8.8.8",
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 3000
    )
    
    try {
        $ping = New-Object System.Net.NetworkInformation.Ping
        $result = $ping.Send($TestHost, $Timeout)
        $isOnline = $result.Status -eq [System.Net.NetworkInformation.IPStatus]::Success
        
        Write-Log -Level INFO -Message "Online check result: $isOnline (Test host: $TestHost)" -Silent $true
        return $isOnline
    } catch {
        Write-Log -Level WARN -Message "Online check failed: $_" -Silent $true
        return $false
    }
}

function Test-ExecutionPolicy {
    [CmdletBinding()]
    param()
    
    try {
        $currentPolicy = Get-ExecutionPolicy -Scope Process
        $allowedPolicies = @('RemoteSigned', 'Unrestricted', 'Bypass')
        $isAllowed = $currentPolicy -in $allowedPolicies
        
        Write-Log -Level INFO -Message "Execution policy: $currentPolicy - Allowed: $isAllowed" -Silent $true
        
        return [PSCustomObject]@{
            IsAllowed = $isAllowed
            CurrentPolicy = $currentPolicy.ToString()
            AllowedPolicies = $allowedPolicies
        }
    } catch {
        Write-Log -Level ERROR -Message "Failed to check execution policy: $_" -Silent $true
        return [PSCustomObject]@{
            IsAllowed = $false
            CurrentPolicy = "Unknown"
            AllowedPolicies = @()
        }
    }
}

# ====================
# REMOVED FUNCTIONS
# ====================
# ❌ XÓA HOÀN TOÀN:
# Set-ExecutionPolicyUnrestricted
# Get-SystemChecks (nếu có)
# Bất kỳ hàm nào có chữ "Set", "Fix", "Change", "Modify"

# ====================
# NEW ASSERT-REQUIREMENT FUNCTION
# ====================

function Assert-Requirement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSObject]$Feature,
        
        [Parameter(Mandatory=$false)]
        [bool]$ExitOnFail = $false,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalContext = @{}
    )
    
    # Get unified context
    $context = Get-WinKitContext
    
    # Merge additional context if provided
    if ($AdditionalContext.Count -gt 0) {
        foreach ($key in $AdditionalContext.Keys) {
            $context | Add-Member -NotePropertyName $key -NotePropertyValue $AdditionalContext[$key] -Force
        }
    }
    
    try {
        # Invoke the feature's Requirement scriptblock
        $result = $feature.Requirement.Invoke($context, $feature)
        
        # Expected result format: @($passed, $message)
        if ($result[0] -eq $true) {
            Write-Log -Level INFO -Message "Requirements satisfied for feature: $($feature.Id) - $($result[1])" -Silent $true
            return $true
        } else {
            $message = "Requirements failed for feature $($feature.Id): $($result[1])"
            Write-Log -Level WARN -Message $message -Silent $true
            
            if ($ExitOnFail) {
                throw $message
            }
            return $false
        }
    } catch {
        $errorMsg = "Requirement check failed for feature $($feature.Id): $_"
        Write-Log -Level ERROR -Message $errorMsg -Silent $true
        
        if ($ExitOnFail) {
            throw $errorMsg
        }
        return $false
    }
}

# ====================
# UTILITY FUNCTIONS
# ====================

function Get-BasicSystemInfo {
    [CmdletBinding()]
    param()
    
    $context = Get-WinKitContext
    
    return [PSCustomObject]@{
        OSVersion    = $context.System.OSVersion
        Architecture = $context.System.Architecture
        IsAdmin      = $context.Security.IsAdmin
        IsOnline     = $context.Security.IsOnline
        PSVersion    = $context.Security.PSVersion
        ComputerName = $context.System.ComputerName
        UserName     = $context.System.UserName
    }
}

# Export only check functions
$exportFunctions = @(
    'Test-IsAdmin',
    'Test-PowerShellVersion',
    'Test-IsOnline',
    'Test-ExecutionPolicy',
    'Assert-Requirement',
    'Get-BasicSystemInfo'
)

if ($MyInvocation.InvocationName -ne '.') {
    Export-ModuleMember -Function $exportFunctions
}
