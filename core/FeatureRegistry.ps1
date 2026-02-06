# =========================================================
# core/FeatureRegistry.ps1
# WinKit Feature Registry
#
# PURPOSE:
# - Feature self-registration
# - Store metadata + ScriptBlock + Requirement
#
# ❌ No UI
# ❌ No requirement execution
# ❌ No business logic
# =========================================================

# =========================================================
# GLOBAL REGISTRY (SINGLE SOURCE)
# =========================================================
if (-not $Global:WinKitFeatureRegistry) {
    $Global:WinKitFeatureRegistry = @()
}

# =========================================================
# REGISTER FEATURE
# =========================================================
function Register-Feature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Metadata,

        [Parameter(Mandatory)]
        [ScriptBlock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [ScriptBlock]$Requirement
    )

    # -------------------------
    # Validate metadata (HARD RULE)
    # -------------------------
    $requiredFields = @('Id', 'Title', 'Category', 'Order')
    foreach ($field in $requiredFields) {
        if (-not $Metadata.ContainsKey($field)) {
            throw "Feature registration failed: Missing required metadata field '$field'"
        }
    }

    # -------------------------
    # Prevent duplicate feature ID
    # -------------------------
    if ($Global:WinKitFeatureRegistry.Id -contains $Metadata.Id) {
        throw "Feature registration failed: Duplicate Feature Id '$($Metadata.Id)'"
    }

    # -------------------------
    # Backward compatibility requirement
    # -------------------------
    if (-not $Requirement) {
        $Requirement = {
            param($Context, $Feature)

            if ($Feature.RequireAdmin -and -not $Context.Security.IsAdmin) {
                return $false, "Administrator privileges required"
            }

            if ($Feature.OnlineOnly -and -not ($Context.Network.PingResults.Success -contains $true)) {
                return $false, "Internet connection required"
            }

            return $true, "Requirements satisfied"
        }
    }

    # -------------------------
    # Build immutable feature object
    # -------------------------
    $feature = [PSCustomObject]@{
        # Identity
        Id          = $Metadata.Id
        Title       = $Metadata.Title
        Category    = $Metadata.Category
        Order       = $Metadata.Order

        # Optional metadata
        Description = $Metadata.Description ?? ""
        Author      = $Metadata.Author ?? ""
        Version     = $Metadata.Version ?? "1.0.0"
        Tags        = $Metadata.Tags ?? @()

        # Execution
        ScriptBlock = $ScriptBlock
        Requirement = $Requirement

        # Legacy flags (DEPRECATED – READ ONLY)
        RequireAdmin = [bool]($Metadata.RequireAdmin ?? $false)
        OnlineOnly   = [bool]($Metadata.OnlineOnly ?? $false)

        # State
        Enabled      = if ($Metadata.ContainsKey('Enabled')) { [bool]$Metadata.Enabled } else { $true }
        RegisteredAt = Get-Date
    }

    # -------------------------
    # Register
    # -------------------------
    $Global:WinKitFeatureRegistry += $feature

    # Keep registry sorted
    $Global:WinKitFeatureRegistry =
        $Global:WinKitFeatureRegistry |
        Sort-Object Category, Order

    Write-Log -Level INFO -Message "Registered feature: $($feature.Id) - $($feature.Title)" -Silent $true

    return $feature
}

# =========================================================
# QUERY FUNCTIONS (READ ONLY)
# =========================================================
function Get-AllFeatures {
    return $Global:WinKitFeatureRegistry
}

function Get-FeatureById {
    param([Parameter(Mandatory)][string]$Id)
    return $Global:WinKitFeatureRegistry | Where-Object Id -eq $Id | Select-Object -First 1
}

function Get-FeaturesByCategory {
    param([string]$Category)
    if ($Category) {
        return $Global:WinKitFeatureRegistry | Where-Object Category -eq $Category
    }
    return $Global:WinKitFeatureRegistry
}

function Get-FeatureCategories {
    return $Global:WinKitFeatureRegistry.Category | Sort-Object -Unique
}

# =========================================================
# EXECUTION ENTRY (NO REQUIREMENT CHECK HERE)
# =========================================================
function Invoke-Feature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [hashtable]$Parameters = @{}
    )

    $feature = Get-FeatureById -Id $Id
    if (-not $feature) {
        throw "Feature not found: $Id"
    }

    if (-not $feature.Enabled) {
        throw "Feature disabled: $Id"
    }

    return & $feature.ScriptBlock @Parameters
}

# =========================================================
# MAINTENANCE
# =========================================================
function Clear-FeatureRegistry {
    $count = $Global:WinKitFeatureRegistry.Count
    $Global:WinKitFeatureRegistry = @()
    Write-Log -Level WARN -Message "Feature registry cleared ($count features removed)" -Silent $true
    return $count
}

# =========================================================
# MODULE EXPORT (SAFE)
# =========================================================
if ($MyInvocation.InvocationName -ne '.') {
    Export-ModuleMember -Function `
        Register-Feature, `
        Get-AllFeatures, `
        Get-FeatureById, `
        Get-FeaturesByCategory, `
        Get-FeatureCategories, `
        Invoke-Feature, `
        Clear-FeatureRegistry
}
