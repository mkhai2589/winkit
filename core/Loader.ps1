# =========================================================
# WinKit - Loader.ps1
# Module discovery & registration
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Global module registry
$Global:WinKitModules = @()

# -------------------------
# VALIDATE MODULE.JSON
# -------------------------
function Test-ModuleSchema {
    param (
        [Parameter(Mandatory)]
        [hashtable]$Meta,
        [Parameter(Mandatory)]
        [string]$ModulePath
    )

    $required = @(
        "name",
        "id",
        "category",
        "description",
        "entry",
        "version",
        "requireAdmin",
        "supportedOS"
    )

    foreach ($key in $required) {
        if (-not $Meta.ContainsKey($key)) {
            Write-Warn "Invalid module schema in $ModulePath"
            Write-Warn "Missing key: $key"
            return $false
        }
    }

    return $true
}

# -------------------------
# LOAD MODULE.JSON SAFELY
# -------------------------
function Read-ModuleMeta {
    param (
        [Parameter(Mandatory)]
        [string]$JsonPath
    )

    try {
        $raw = Get-Content $JsonPath -Raw -Encoding UTF8
        return ConvertFrom-Json $raw -AsHashtable
    }
    catch {
        Write-Warn "Failed to read module.json: $JsonPath"
        Write-Warn $_.Exception.Message
        return $null
    }
}

# -------------------------
# DISCOVER MODULES
# -------------------------
function Discover-Modules {
    param (
        [string]$ModulesRoot = "$PSScriptRoot\..\modules"
    )

    Write-Info "Discovering modules"

    if (-not (Test-Path $ModulesRoot)) {
        Write-Warn "Modules directory not found"
        return
    }

    $jsonFiles = Get-ChildItem -Path $ModulesRoot -Recurse -Filter "module.json" -File

    foreach ($json in $jsonFiles) {

        $moduleDir = Split-Path $json.FullName -Parent
        $meta = Read-ModuleMeta -JsonPath $json.FullName
        if (-not $meta) { continue }

        if (-not (Test-ModuleSchema -Meta $meta -ModulePath $moduleDir)) {
            continue
        }

        $entryPath = Join-Path $moduleDir $meta.entry
        if (-not (Test-Path $entryPath)) {
            Write-Warn "Module entry not found: $entryPath"
            continue
        }

        $module = [ordered]@{
            Name         = $meta.name
            Id           = $meta.id
            Category     = $meta.category
            Description  = $meta.description
            Version      = $meta.version
            RequireAdmin = [bool]$meta.requireAdmin
            SupportedOS  = @($meta.supportedOS)
            Entry        = $entryPath
            Root         = $moduleDir
        }

        $Global:WinKitModules += $module
    }

    if ($Global:WinKitModules.Count -eq 0) {
        Write-Warn "No valid modules found"
    }
    else {
        Write-Success ("Loaded {0} modules" -f $Global:WinKitModules.Count)
    }
}

# -------------------------
# GET MODULES BY CATEGORY
# -------------------------
function Get-ModulesByCategory {
    param (
        [Parameter(Mandatory)]
        [string]$Category
    )

    return $Global:WinKitModules | Where-Object {
        $_.Category -eq $Category
    }
}

# -------------------------
# GET UNIQUE CATEGORIES
# -------------------------
function Get-ModuleCategories {
    return $Global:WinKitModules |
        Select-Object -ExpandProperty Category -Unique |
        Sort-Object
}

# -------------------------
# EXECUTE MODULE (SAFE)
# -------------------------
function Invoke-Module {
    param (
        [Parameter(Mandatory)]
        [hashtable]$Module
    )

    # Security check
    if (-not (Validate-ModuleSecurity $Module)) {
        Pause-Console
        return
    }

    # OS support check
    if (-not (Test-ModuleOSSupport $Module.SupportedOS)) {
        Pause-Console
        return
    }

    Write-Info ("Launching module: {0}" -f $Module.Name)

    try {
        . $Module.Entry

        $startFunc = "Start-$($Module.Id)"
        if (-not (Get-Command $startFunc -ErrorAction SilentlyContinue)) {
            Write-ErrorX "Entry function not found: $startFunc"
            Pause-Console
            return
        }

        & $startFunc
    }
    catch {
        Write-ErrorX "Module execution failed"
        Write-ErrorX $_.Exception.Message
        Pause-Console
    }
}

# -------------------------
# INITIALIZE LOADER
# -------------------------
function Initialize-Loader {
    Discover-Modules
}
