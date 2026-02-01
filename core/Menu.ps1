# =========================================================
# WinKit - Menu.ps1
# Console menu renderer & controller
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -------------------------
# RENDER CATEGORY MENU
# -------------------------
function Show-CategoryMenu {
    param (
        [string[]]$Categories
    )

    Clear-Host
    Show-Header

    Write-Info "Select a category"
    Write-Host ""

    $index = 1
    $map = @{}

    foreach ($cat in $Categories) {
        Write-MenuItem $index $cat
        $map[$index] = $cat
        $index++
    }

    Write-MenuItem 0 "Exit"
    Write-Host ""

    $choice = Read-Choice "Enter choice"

    if ($choice -eq 0) {
        Exit-WinKit
    }

    if (-not $map.ContainsKey($choice)) {
        Write-Warn "Invalid selection"
        Pause-Console
        return $null
    }

    return $map[$choice]
}

# -------------------------
# RENDER MODULE MENU
# -------------------------
function Show-ModuleMenu {
    param (
        [string]$Category
    )

    Clear-Host
    Show-Header

    Write-Info "Category: $Category"
    Write-Host ""

    $modules = Get-ModulesByCategory $Category
    if (-not $modules -or $modules.Count -eq 0) {
        Write-Warn "No modules available"
        Pause-Console
        return
    }

    $index = 1
    $map = @{}

    foreach ($m in $modules) {
        Write-MenuItem $index $m.Name -Description $m.Description
        $map[$index] = $m
        $index++
    }

    Write-MenuItem 0 "Back"
    Write-Host ""

    $choice = Read-Choice "Enter choice"

    if ($choice -eq 0) {
        return
    }

    if (-not $map.ContainsKey($choice)) {
        Write-Warn "Invalid selection"
        Pause-Console
        return
    }

    Invoke-Module $map[$choice]
}

# -------------------------
# MAIN MENU LOOP
# -------------------------
function Start-Menu {
    while ($true) {

        $categories = Get-ModuleCategories
        if (-not $categories -or $categories.Count -eq 0) {
            Write-ErrorX "No modules loaded"
            Exit-WinKit
        }

        $selectedCategory = Show-CategoryMenu $categories
        if (-not $selectedCategory) {
            continue
        }

        Show-ModuleMenu $selectedCategory
    }
}
