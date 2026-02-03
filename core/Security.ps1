# core/Security.ps1
# Security and System Requirement Checks

function Test-IsAdmin {
    [CmdletBinding()]
    param()
    
    $isAdmin = $false
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    Write-Log -Level INFO -Message "Admin check result: $isAdmin" -Silent $true
    return $isAdmin
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
    return @{
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
    }
    catch {
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
        
        return @{
            IsAllowed = $isAllowed
            CurrentPolicy = $currentPolicy.ToString()
            AllowedPolicies = $allowedPolicies
        }
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to check execution policy: $_" -Silent $true
        return @{
            IsAllowed = $false
            CurrentPolicy = "Unknown"
            AllowedPolicies = @()
        }
    }
}

# ============================================
# NEW FUNCTION: AUTO SET EXECUTION POLICY - QUYỀN CAO NHẤT
# ============================================

function Set-ExecutionPolicyUnrestricted {
    [CmdletBinding()]
    param()
    
    try {
        # Priority: Process → CurrentUser → LocalMachine
        $success = $false
        $attemptedScopes = @()
        
        foreach ($scope in @("Process", "CurrentUser", "LocalMachine")) {
            try {
                $attemptedScopes += $scope
                Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope $scope -Force -ErrorAction Stop
                Write-Log -Level INFO -Message "ExecutionPolicy set to Unrestricted (Scope: $scope)" -Silent $true
                $success = $true
                break  # Dừng khi thành công ở scope đầu tiên
            }
            catch {
                Write-Log -Level WARN -Message "Failed to set ExecutionPolicy for scope $scope: $_" -Silent $true
                # Continue với scope tiếp theo
            }
        }
        
        # Nếu không thành công với bất kỳ scope nào, thử bằng registry
        if (-not $success) {
            Write-Log -Level WARN -Message "All standard scopes failed, attempting registry method" -Silent $true
            try {
                $regPath = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell"
                Set-ItemProperty -Path $regPath -Name "ExecutionPolicy" -Value "Unrestricted" -Force -ErrorAction Stop
                Write-Log -Level INFO -Message "ExecutionPolicy set via registry" -Silent $true
                $success = $true
            }
            catch {
                Write-Log -Level ERROR -Message "Registry method also failed: $_" -Silent $true
            }
        }
        
        # Log tổng kết
        if ($success) {
            Write-Log -Level INFO -Message "ExecutionPolicy successfully set to Unrestricted" -Silent $true
        } else {
            Write-Log -Level ERROR -Message "All ExecutionPolicy setting methods failed. Attempted scopes: $($attemptedScopes -join ', ')" -Silent $true
        }
        
        return $success
    }
    catch {
        Write-Log -Level ERROR -Message "Set-ExecutionPolicyUnrestricted failed: $_" -Silent $true
        return $false
    }
}

function Get-SystemChecks {
    [CmdletBinding()]
    param()
    
    # THÊM: Tự động set Execution Policy trước khi kiểm tra
    $executionPolicyFixed = Set-ExecutionPolicyUnrestricted
    
    $checks = @{
        IsAdmin = Test-IsAdmin
        PowerShellVersion = Test-PowerShellVersion -MinimumVersion 5
        IsOnline = Test-IsOnline
        ExecutionPolicy = Test-ExecutionPolicy
        # THÊM DÒNG NÀY - Kết quả auto fix
        ExecutionPolicyFixed = $executionPolicyFixed
        OSVersion = [System.Environment]::OSVersion.Version
        Is64Bit = [Environment]::Is64BitOperatingSystem
    }
    
    # Log all checks
    foreach ($key in $checks.Keys) {
        if ($key -ne "OSVersion") {
            Write-Log -Level DEBUG -Message "System check - $key : $($checks[$key])" -Silent $true
        }
    }
    
    return $checks
}

function Assert-Requirement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Requirement,
        
        [Parameter(Mandatory=$false)]
        [bool]$ExitOnFail = $false
    )
    
    $failedChecks = @()
    
    # Check Admin requirement
    if ($Requirement.RequireAdmin -eq $true) {
        if (-not (Test-IsAdmin)) {
            $failedChecks += "Administrator privileges required"
        }
    }
    
    # Check Online requirement
    if ($Requirement.OnlineOnly -eq $true) {
        if (-not (Test-IsOnline)) {
            $failedChecks += "Internet connection required"
        }
    }
    
    # Log requirement check
    if ($failedChecks.Count -eq 0) {
        Write-Log -Level INFO -Message "All requirements satisfied for feature: $($Requirement.Id)" -Silent $true
        return $true
    }
    else {
        $message = "Requirements failed for feature $($Requirement.Id): " + ($failedChecks -join ", ")
        Write-Log -Level WARN -Message $message -Silent $true
        
        if ($ExitOnFail) {
            throw $message
        }
        
        return $false
    }
}
