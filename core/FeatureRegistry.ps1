$global:WK_FEATURES = @()
$global:WK_FEATURES_BY_ID = @{}
$global:WK_CATEGORIES = @{}

function Register-Feature {
    param(
        [string]$Id,
        [string]$Title,
        [string]$Description,
        [ValidateSet("Essential","Advanced","Tools")]
        [string]$Category,
        [int]$Order,
        [string]$FileName,
        [scriptblock]$Execute,
        [bool]$RequireAdmin = $true
    )

    if ($global:WK_FEATURES_BY_ID.ContainsKey($Id)) {
        Write-Log "Feature duplicated: $Id" "WARN"
        return
    }

    $feature = [PSCustomObject]@{
        Id = $Id
        Title = $Title
        Description = $Description
        Category = $Category
        Order = $Order
        FileName = $FileName
        Execute = $Execute
        RequireAdmin = $RequireAdmin
        RegisteredAt = Get-Date
    }

    $global:WK_FEATURES += $feature
    $global:WK_FEATURES_BY_ID[$Id] = $feature

    if (-not $global:WK_CATEGORIES.ContainsKey($Category)) {
        $global:WK_CATEGORIES[$Category] = @()
    }

    $global:WK_CATEGORIES[$Category] += $feature
}

function Get-AllFeatures {
    $global:WK_FEATURES | Sort-Object Order
}

function Get-FeaturesByCategory($Category) {
    if ($global:WK_CATEGORIES.ContainsKey($Category)) {
        return $global:WK_CATEGORIES[$Category] | Sort-Object Order
    }
    return @()
}

function Get-FeatureByOrder($Order) {
    $global:WK_FEATURES | Where-Object { $_.Order -eq $Order } | Select-Object -First 1
}

function Invoke-Feature($Feature) {
    if ($Feature.RequireAdmin -and -not (Test-AdminSilent)) {
        throw "Administrator privileges required"
    }
    & $Feature.Execute
}
