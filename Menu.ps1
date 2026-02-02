function Show-MainMenu {

    while ($true) {
        Clear-Host
        Show-Logo
        Write-Separator

        foreach ($category in $WK_CONFIG.ui.categoryOrder) {
            $features = Get-FeaturesByCategory $category
            if ($features.Count -eq 0) { continue }

            Write-CategoryHeader $category
            foreach ($f in $features) {
                Write-MenuItem $f.Order $f.Title
            }
            Write-Host ""
        }

        Write-Host "[0] Exit"
        $choice = Read-Host "Select option"

        if ($choice -eq "0") { break }

        $feature = Get-FeatureByOrder ([int]$choice)
        if ($null -ne $feature) {
            Invoke-Feature $feature
            Pause-Return
        }
    }
}
