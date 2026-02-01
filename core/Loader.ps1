$Global:WinKitModules = @()

function Load-WinKitModules {

    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $modulesRoot = Join-Path $root "modules"

    $jsonFiles = Get-ChildItem $modulesRoot -Recurse -Filter module.json

    foreach ($file in $jsonFiles) {
        try {
            $m = Get-Content $file.FullName -Raw | ConvertFrom-Json
            $modulePath = Split-Path $file.FullName -Parent
            $entryPath  = Join-Path $modulePath $m.entry

            if (-not (Test-Path $entryPath)) { continue }

            $Global:WinKitModules += [PSCustomObject]@{
                Id           = [int]$m.id
                Name         = $m.name
                Category     = $m.category
                Description  = $m.description
                Version      = $m.version
                RequireAdmin = $m.requireAdmin
                SupportedOS  = $m.supportedOS
                Entry        = $entryPath
            }
        } catch {}
    }

    $Global:WinKitModules = $Global:WinKitModules | Sort-Object Id
}
