# =========================================================
# App.ps1 - WinKit Application Entry (FINAL)
# =========================================================

function Start-WinKit {
    [CmdletBinding()]
    param()

    try {
        # ---------- Theme ----------
        $themeName = 'default'
        if ($Global:WinKitConfig -and $Global:WinKitConfig.UI -and $Global:WinKitConfig.UI.Theme) {
            $themeName = $Global:WinKitConfig.UI.Theme
        }
        Initialize-Theme -ColorScheme $themeName | Out-Null

        # ---------- Header ----------
        Show-Header -WithStatus

        # ---------- Menu Loop ----------
        while ($true) {

            $menuData = Get-MenuData
            Show-Menu -MenuData $menuData

            $choice = Show-Prompt -Message "SELECT OPTION"
            if (-not $choice) { continue }

            if ($choice -eq $menuData.ExitNumber.ToString()) {
                Write-Colored "Exiting WinKit..." -Style Status
                break
            }

            $feature = Get-FeatureByNumber -Number ([int]$choice)

            if (-not $feature) {
                Write-Colored "Invalid option!" -Style Error
                Start-Sleep 1
                Show-Header
                continue
            }

            try {
                Assert-Requirement -Feature $feature
                Invoke-Feature -Feature $feature
            }
            catch {
                Write-Colored $_.Exception.Message -Style Error
            }

            Write-Colored "Press Enter to return to menu..." -Style Prompt
            Read-Host | Out-Null
            Show-Header
        }
    }
    catch {
        Write-Colored "Fatal error: $($_.Exception.Message)" -Style Error
    }
}
