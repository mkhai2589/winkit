# =========================================================
# WinKit - Security.ps1
# Security & permission enforcement
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -------------------------
# CHECK ADMIN
# -------------------------
function Test-IsAdmin {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal   = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Require-Admin {
    if (-not (Test-IsAdmin)) {
        Write-ErrorX "Administrator privileges required"
        Write-Warn "Please run PowerShell as Administrator"
        Exit-WinKit
    }

    Write-Success "Administrator privileges confirmed"
}

# -------------------------
# EXECUTION POLICY
# -------------------------
function Get-ExecutionPolicySafe {
    try {
        return Get-ExecutionPolicy -Scope Process
    }
    catch {
        return "Unknown"
    }
}

function Ensure-ExecutionPolicy {
    $policy = Get-ExecutionPolicySafe

    if ($policy -eq "Restricted") {
        Write-Warn "ExecutionPolicy is Restricted"
        Write-Info "Temporarily setting policy to Bypass (Process scope)"

        try {
            Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
            Write-Success "ExecutionPolicy set to Bypass (Process)"
        }
        catch {
            Write-ErrorX "Failed to set ExecutionPolicy"
            Write-ErrorX $_.Exception.Message
            Exit-WinKit
        }
    }
}

# -------------------------
# POWERSHELL VERSION
# -------------------------
function Ensure-PowerShellVersion {
    $minMajor = 5
    $version  = $PSVersionTable.PSVersion.Major

    if ($version -lt $minMajor) {
        Write-ErrorX "PowerShell $minMajor or higher is required"
        Write-ErrorX "Detected version: $version"
        Exit-WinKit
    }

    Write-Success "PowerShell version OK ($version)"
}

# -------------------------
# INTERNET SAFETY
# -------------------------
function Block-ExternalDownloads {
    # Trust rule:
    # WinKit DOES NOT download any external binaries
    # This function exists to make policy explicit

    Write-Info "External downloads are disabled by policy"
}

# -------------------------
# MODULE SECURITY CHECK
# -------------------------
function Validate-ModuleSecurity {
    param(
        [Parameter(Mandatory)]
        [hashtable]$ModuleMeta
    )

    if ($ModuleMeta.requireAdmin -eq $true -and -not (Test-IsAdmin)) {
        Write-Warn "Module '$($ModuleMeta.name)' requires Administrator privileges"
        return $false
    }

    return $true
}

# -------------------------
# ENTRY SECURITY PIPELINE
# -------------------------
function Initialize-Security {
    Write-Info "Initializing security checks"

    Ensure-PowerShellVersion
    Ensure-ExecutionPolicy
    Require-Admin
    Block-ExternalDownloads

    Write-Success "Security checks passed"
}
