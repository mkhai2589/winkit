$global:WK_FEATURES = @()
$global:WK_FEATURES_BY_ID = @{}
$global:WK_CATEGORIES = @{}

function Register-Feature {
    param(
        [string]$Id,
        [string]$Title,
        [string]$Description,
        [string]$Category,
        [int]$Order,
        [string]$FileName,
        [scriptblock]$Execute,
        [bool]$RequireAdmin = $true
    )

    if ($WK_FEATURES_BY_ID.ContainsKey($Id)) {
        Write-Log "Duplicate feature: $Id" "WARN"
        return
    }

    $feature = [PSCustomObject]@{
        Id = $Id
        Title = $Title
        Description = $Description
        Category = $Category
        Order = $Order
        Execute = $Execute
        RequireAdmin = $RequireAdmin
        FileName = $FileName
    }

    $WK_FEATURES += $feature
    $WK_FEATURES_BY_ID[$Id] = $feature

    if (-not $WK_CATEGORIES.ContainsKey($Category)) {
        $WK_CATEGORIES[$Category] = @()
    }
    $WK_CATEGORIES[$Category] += $feature
}

function Get-FeaturesByCategory($Category) {
    if ($WK_CATEGORIES.ContainsKey($Category)) {
        return $WK_CATEGORIES[$Category] | Sort-Object Order
    }
    return @()
}

function Get-FeatureByOrder($Order) {
    $WK_FEATURES | Where-Object { $_.Order -eq $Order } | Select-Object -First 1
}

function Invoke-Feature($Feature) {
    if ($Feature.RequireAdmin -and -not (Test-AdminSilent)) {
        Write-ErrorBox "Administrator rights required"
        return
    }
    & $Feature.Execute
}
