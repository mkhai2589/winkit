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
#
# SINGLE SOURCE OF TRUTH FOR FEATURES
# =========================================================

# =========================================================
# GLOBAL REGISTRY (SINGLE INSTANCE)
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

        [Parameter()]
        [ScriptBlock]$Requirement
    )

    # -----------------------------------------------------
    # HARD VALIDATION – REQUIRED METADATA
    # -----------------------------------------------------
    foreach ($field in @('Id', 'Title', 'Category', 'Order')) {
        if (-not $Metadata.ContainsKey($field)) {
            throw "Feature registration failed: Missing required metadata field '$field'"
        }
    }

    # -----------------------------------------------------
    # PREVENT DUPLICATE FEATURE ID
    # -----------------------------------------------------
    if ($Global:WinKitFeatureRegistry.Id -contains $Metadata.Id) {
        throw "Feature registration failed: Duplicate Feature Id '$($Metadata.Id)'"
    }

    # -----------------------------------------------------
    # BACKWARD-COMPAT REQUIREMENT ADAPTER
    # (RequireAdmin / OnlineOnly legacy support)
    # -----------------------------------------------------
    if (-not $Requirement) {
        $Requirement = {
            param($Context, $Feature)

            if ($Feature.RequireAdmin -and -not $Context.Security.IsAdmin) {
                return $false, "Administrator privileges required"
            }

            if ($Feature.OnlineOnly -and -not ($Context.Network.PingResults | Where-Object Success -eq $true)) {
                return $false, "Internet connection required"
            }

            return $true, "Requirements satisfied"
        }
    }

    # -----------------------------------------------------
    # BUILD FEATURE OBJECT (DATA + BEHAVIOR HANDLE)
    # -----------------------------------------------------
    $feature = [PSCustomObject]@{
        # Identity
        Id           = $Metadata.Id
        Title        = $Metadata.Title
        Category     = $Metadata.Category
        Order        = $Metadata.Order

        # Optional metadata
        Description  = $Metadata.Description ?? ""
        Author       = $Metadata.Author ?? ""
        Version      = $Metadata.Version ?? "1.0.0"
        Tags         = $Metadata.Tags ?? @()

        # Execution & requirement
        ScriptBlock  = $ScriptBlock
        Requirement  = $Requirement

        # Legacy flags (READ-ONLY / DEPRECATED)
        RequireAdmin = [bool]($Metadata.RequireAdmin ?? $false)
        OnlineOnly   = [bool]($Metadata.OnlineOnly ?? $false)

        # State
        Enabled      = if ($Metadata.ContainsKey('Enabled')) { [bool]$Metadata.Enabled } else { $true }
        RegisteredAt = Get-Date
    }

    # -----------------------------------------------------
    # IMMUTABLE FEATURE OBJECT (LOCK PROPERTIES)
    # -----------------------------------------------------
    $feature.PSObject.Properties |
        Where-Object IsSettable |
        ForEach-Object { $_.IsSettable = $false }

    # -----------------------------------------------------
    # REGISTER FEATURE
    # -----------------------------------------------------
    $Global:WinKitFeatureRegistry += $feature
    $Global:WinKitFeatureRegistry =
        $Global:WinKitFeatureRegistry |
        Sort-Object Category, Order

    Write-Log -Level INFO -Message "Registered feature: $($feature.Id) - $($feature.Title)" -Silent $true

    return $feature
}

# =========================================================
# QUERY FUNCTIONS (READ-ONLY)
# =========================================================
function Get-AllFeatures {
    return $Global:WinKitFeatureRegistry
}

function Get-FeatureById {
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    return $Global:WinKitFeatureRegistry |
        Where-Object Id -eq $Id |
        Select-Object -First 1
}

function Get-FeaturesByCategory {
    param(
        [string]$Category
    )

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
# MODULE EXPORT
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
