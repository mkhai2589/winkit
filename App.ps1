# App.ps1
# WinKit Application Entry
# RESPONSIBILITY:
# - Initialize system
# - Render UI
# - Handle main loop

# ==============================
# LOAD CORE & UI
# ==============================
Load-Modules -Modules @(
    'Logger',
    'Utils',
    'Security',
    'FeatureRegistry',
    'Interface'
) -Layer 'core'

Load-Modules -Modules @(
    'Theme',
    'Logo',
    'UI'
) -Layer 'ui'

# ==============================
# INIT CONFIG
# ==============================
if (-not $Global:WinKitConfig) {
    $Global:WinKitConfig = Get-Content "config.json" -Raw | ConvertFrom-Json
}

# ==============================
# INIT THEME (PS 5.1 SAFE)
# ==============================
$themeName = 'default'
if ($Global:WinKitConfig.UI -and $Global:WinKitConfig.UI.Theme) {
    $themeName = $Global:WinKitConfig.UI.Theme
}
Initialize-Theme -ColorScheme $themeName | Out-Null

# ==============================
# LOAD FEATURES
# ==============================
Get-ChildItem "features\*.ps1" | ForEach-Object {
    . $_.FullName
}

# ==============================
# MAIN LOOP
# ==============================
while ($true) {
    Show-Header -WithStatus

    $menuData = Build-MenuData   # từ Menu.ps1
    Show-Menu -MenuData $menuData

    $choice = Show-Prompt "SELECT OPTION"

    if ($choice -eq $menuData.ExitNumber) {
        break
    }

    Invoke-MenuSelection -Choice $choice -MenuData $menuData
}
