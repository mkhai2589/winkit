# core/FeatureRegistry.ps1
# Feature Self-Registration System - No UI, No Menu Logic

# Global registry variable - MUST follow this naming
$Global:WinKitFeatureRegistry = @()

function Register-Feature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Metadata,

        [Parameter(Mandatory=$true)]
        [ScriptBlock]$ScriptBlock,

        [Parameter(Mandatory=$false)]
        [ScriptBlock]$Requirement = $null
    )

    # Validate required metadata fields
    $requiredFields = @('Id', 'Title', 'Category', 'Order')
    foreach ($field in $requiredFields) {
        if (-not $Metadata.ContainsKey($field)) {
            Write-Log -Level ERROR -Message "Feature registration failed: Missing required field '$field'" -Silent $true
            return $false
        }
    }

    # Check for duplicate ID
    $existingFeature = $Global:WinKitFeatureRegistry | Where-Object { $_.Id -eq $Metadata.Id }
    if ($existingFeature) {
        Write-Log -Level WARN -Message "Feature with ID '$($Metadata.Id)' already registered. Skipping." -Silent $true
        return $false
    }

    # If no custom Requirement provided, create default one for backward compatibility
    if (-not $Requirement) {
        $Requirement = {
            param($Context, $Feature)
            
            # Backward compatibility: check old RequireAdmin and OnlineOnly fields
            if ($Feature.RequireAdmin -eq $true -and -not $Context.Security.IsAdmin) {
                return $false, "Administrator privileges required"
            }
            
            if ($Feature.OnlineOnly -eq $true -and -not $Context.Security.IsOnline) {
                return $false, "Internet connection required"
            }
            
            return $true, "All requirements satisfied"
        }
    }

    # Build feature object with Requirement support
    $feature = [PSCustomObject]@{
        Id          = $Metadata.Id
        Title       = $Metadata.Title
        Category    = $Metadata.Category
        Order       = $Metadata.Order
        Description = if ($Metadata.Description) { $Metadata.Description } else { "" }
        ScriptBlock = $ScriptBlock
        Requirement = $Requirement  # Custom requirement scriptblock
        
        # Legacy fields for backward compatibility (deprecated, but kept)
        RequireAdmin = if ($Metadata.RequireAdmin) { $Metadata.RequireAdmin } else { $false }
        OnlineOnly   = if ($Metadata.OnlineOnly) { $Metadata.OnlineOnly } else { $false }
        
        # Additional metadata (optional)
        Author      = if ($Metadata.Author) { $Metadata.Author } else { "" }
        Version     = if ($Metadata.Version) { $Metadata.Version } else { "1.0.0" }
        Tags        = if ($Metadata.Tags) { $Metadata.Tags } else { @() }
        
        # System fields
        RegisteredAt = Get-Date
        IsEnabled    = if ($Metadata.ContainsKey('Enabled')) { $Metadata.Enabled } else { $true }
    }

    # Add to registry
    $Global:WinKitFeatureRegistry += $feature

    # Sort registry by Category then Order
    $Global:WinKitFeatureRegistry = $Global:WinKitFeatureRegistry | Sort-Object -Property Category, Order

    Write-Log -Level INFO -Message "Feature registered: $($Metadata.Id) - $($Metadata.Title) [Requirement: $($Requirement.ToString().Substring(0, [math]::Min(50, $Requirement.ToString().Length))...)]" -Silent $true
    return $true
}

# Keep existing functions unchanged (they still work)
function Get-AllFeatures {
    [CmdletBinding()]
    param()
    return $Global:WinKitFeatureRegistry
}

function Get-FeaturesByCategory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Category
    )
    if ($Category) {
        return $Global:WinKitFeatureRegistry | Where-Object { $_.Category -eq $Category }
    } else {
        $grouped = $Global:WinKitFeatureRegistry | Group-Object -Property Category
        return $grouped
    }
}

function Get-FeatureById {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Id
    )
    return $Global:WinKitFeatureRegistry | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
}

function Invoke-Feature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Id,
        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters = @{}
    )
    $feature = Get-FeatureById -Id $Id
    if (-not $feature) {
        Write-Log -Level ERROR -Message "Feature not found: $Id" -Silent $true
        throw "Feature not found: $Id"
    }
    
    Write-Log -Level INFO -Message "Executing feature: $($feature.Id) - $($feature.Title)" -Silent $true
    
    if ($feature.ScriptBlock) {
        try {
            $result = & $feature.ScriptBlock @Parameters
            return $result
        } catch {
            Write-Log -Level ERROR -Message "Feature execution failed: $($feature.Id) - $_" -Silent $true
            throw "Feature execution failed: $_"
        }
    } else {
        Write-Log -Level WARN -Message "Feature $($feature.Id) has no script block" -Silent $true
        return $false
    }
}

function Clear-FeatureRegistry {
    [CmdletBinding()]
    param()
    $count = $Global:WinKitFeatureRegistry.Count
    $Global:WinKitFeatureRegistry = @()
    Write-Log -Level INFO -Message "Feature registry cleared. Removed $count features." -Silent $true
    return $count
}

function Get-FeatureCategories {
    [CmdletBinding()]
    param()
    return $Global:WinKitFeatureRegistry |
        Select-Object -ExpandProperty Category -Unique |
        Sort-Object
}

# New function to validate feature requirements (can be called by Menu.ps1)
function Test-FeatureRequirements {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureId,
        
        [Parameter(Mandatory=$false)]
        [bool]$ReturnDetails = $false
    )
    
    $feature = Get-FeatureById -Id $FeatureId
    if (-not $feature) {
        if ($ReturnDetails) {
            return @{ Passed = $false; Message = "Feature not found" }
        }
        return $false
    }
    
    $context = Get-WinKitContext
    $result = $feature.Requirement.Invoke($context, $feature)
    
    if ($ReturnDetails) {
        return @{
            Passed = $result[0]
            Message = $result[1]
            Feature = $feature
        }
    }
    
    return $result[0]
}
