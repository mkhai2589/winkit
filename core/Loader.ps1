# ================================
# WinKit Loader
# ================================

$Global:WinKitModules = @()

function Load-WinKitModules {

    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $modulesPath = Join-Path $root "modules"

    if (-not (Test-Path $modulesPath)) {
        Write-Host "[ERROR] modules folder not found" -ForegroundColor Red
        return
    }

    $jsonFiles = Get-ChildItem -Path $modulesPath -Recurse -Filter "module.json"

    foreach ($json in $jsonFiles) {
        try {
            $data = Get-Content $json.FullName -Raw | ConvertFrom-Json

            if (-not ($data.id -and $data.name -and $data.entry)) {
                Write-Host "[SKIP] Invalid module.json: $($json.FullName)" -ForegroundColor DarkYellow
                continue
            }

            $moduleRoot = Split-Path $json.FullName -Parent
            $entryPath  = Join-Path $moduleRoot $data.entry

            if (-not (Test-Path $entryPath)) {
                Write-Host "[SKIP] Entry file not found: $entryPath" -ForegroundColor DarkYellow
                continue
            }

            $Global:WinKitModules += [PSCustomObject]@{
                Id            = [int]$data.id
                Name          = $data.name
                Category      = $data.category
                RequireAdmin  = $data.requireAdmin
                Support       = $data.support
                Entry         = $entryPath
            }

        } catch {
            Write-Host "[ERROR] Failed to load $($json.FullName)" -ForegroundColor Red
        }
    }

    # Sort by menu id
    $Global:WinKitModules = $Global:WinKitModules | Sort-Object Id
}
