# core/FeatureRegistry.ps1
# Feature Self-Registration System - No UI, No Menu Logic

# Global registry variable - MUST follow this naming
$Global:WinKitFeatureRegistry = @()

function Register-Feature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Metadata,
        
        [Parameter(Mandatory=$false)]
        [ScriptBlock]$ScriptBlock
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
    
    # Build feature object
    $feature = [PSCustomObject]@{
        Id = $Metadata.Id
        Title = $Metadata.Title
        Category = $Metadata.Category
        Order = $Metadata.Order
        Description = if ($Metadata.Description) { $Metadata.Description } else { "" }
        ScriptBlock = if ($ScriptBlock) { $ScriptBlock } else { $null }
        RequireAdmin = if ($Metadata.RequireAdmin) { $Metadata.RequireAdmin } else { $false }
        OnlineOnly = if ($Metadata.OnlineOnly) { $Metadata.OnlineOnly } else { $false }
        RegisteredAt = Get-Date
    }
    
    # Add to registry
    $Global:WinKitFeatureRegistry += $feature
    
    # Sort registry by Category then Order
    $Global:WinKitFeatureRegistry = $Global:WinKitFeatureRegistry | 
        Sort-Object -Property Category, Order
    
    Write-Log -Level INFO -Message "Feature registered: $($Metadata.Id) - $($Metadata.Title)" -Silent $true
    return $true
}

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
    }
    else {
        # Group by category
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
    
    # Check requirements
    $requirement = @{
        Id = $feature.Id
        RequireAdmin = $feature.RequireAdmin
        OnlineOnly = $feature.OnlineOnly
    }
    
    try {
        if (-not (Assert-Requirement -Requirement $requirement -ExitOnFail $false)) {
            return $false
        }
        
        Write-Log -Level INFO -Message "Executing feature: $($feature.Id) - $($feature.Title)" -Silent $true
        
        if ($feature.ScriptBlock) {
            $result = & $feature.ScriptBlock @Parameters
            return $result
        }
        else {
            Write-Log -Level WARN -Message "Feature $($feature.Id) has no script block" -Silent $true
            return $false
        }
    }
    catch {
        Write-Log -Level ERROR -Message "Feature execution failed: $($feature.Id) - $_" -Silent $true
        throw "Feature execution failed: $_"
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

