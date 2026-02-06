# core/Security.ps1
# Security and System Requirement Checks - CHECK ONLY, NO MODIFICATIONS

# =========================================================
# GLOBAL LOGGER FALLBACK (IF LOGGER NOT LOADED)
# =========================================================
if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    function Write-Log {
        param($Level, $Message, $Silent)
        # Silent fallback - do nothing if logger not loaded
    }
}

# =========================================================
# CHECK FUNCTIONS (READ-ONLY, NO SYSTEM MODIFICATIONS)
# =========================================================

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

# =========================================================
# REQUIREMENT ASSERTION ENGINE
# =========================================================

function Assert-Requirement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSObject]$Feature,
        
        [Parameter(Mandatory=$false)]
        [bool]$ExitOnFail = $false,
        
        [Parameter(Mandatory=$false)]
        [switch]$ReturnMessage
    )
    
    # Get unified context (raw facts only)
    $context = Get-WinKitContext
    
    try {
        # Invoke the feature's Requirement scriptblock
        # Expected return format: @($bool, $string)
        $result = $feature.Requirement.Invoke($context, $feature)
        
        if ($result[0] -eq $true) {
            Write-Log -Level INFO -Message "Requirements satisfied for feature: $($feature.Id) - $($result[1])" -Silent $true
            
            if ($ReturnMessage) {
                return $true, $result[1]
            }
            return $true
        } else {
            $message = "Requirements failed for $($feature.Id): $($result[1])"
            Write-Log -Level WARN -Message $message -Silent $true
            
            if ($ExitOnFail) {
                throw $message
            }
            
            if ($ReturnMessage) {
                return $false, $result[1]
            }
            return $false
        }
    } catch {
        $errorMsg = "Requirement check failed for $($feature.Id): $_"
        Write-Log -Level ERROR -Message $errorMsg -Silent $true
        
        if ($ExitOnFail) {
            throw $errorMsg
        }
        
        if ($ReturnMessage) {
            return $false, "Internal error checking requirements"
        }
        return $false
    }
}

# =========================================================
# DEPRECATED FUNCTIONS (REMOVED)
# =========================================================
# ❌ XOÁ HOÀN TOÀN:
# - Set-ExecutionPolicyUnrestricted
# - Get-SystemChecks 
# - Bất kỳ hàm nào bắt đầu bằng "Set-", "Fix-", "Change-"

# =========================================================
# MODULE EXPORT
# =========================================================
if ($MyInvocation.InvocationName -ne '.') {
    Export-ModuleMember -Function `
        Test-IsAdmin, `
        Test-PowerShellVersion, `
        Test-IsOnline, `
        Test-ExecutionPolicy, `
        Assert-Requirement
}
