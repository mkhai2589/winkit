# =========================================================
# core/Interface.ps1
# WinKit Core Interface Bootstrap
#
# PURPOSE:
# - Application initialization
# - Configuration loading
# - Core bootstrap & wiring
#
# ❌ NO UI rendering
# ❌ NO feature logic
# ❌ NO requirement checking
#
# Interface = glue layer giữa core & runtime
# =========================================================

# =========================================================
# GLOBAL STATE
# =========================================================
if (-not $Global:WinKitConfig) {
    $Global:WinKitConfig = @{}
}

# =========================================================
# LOAD CONFIGURATION
# =========================================================
function Load-Configuration {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = "$PSScriptRoot\..\config.json"
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }

    try {
        $json = Get-Content -Path $ConfigPath -Raw -Encoding UTF8
        $config = $json | ConvertFrom-Json -ErrorAction Stop

        # Convert PSCustomObject → Hashtable (deep)
        $Global:WinKitConfig = ConvertTo-Hashtable -InputObject $config

        Write-Log -Level INFO -Message "Configuration loaded from $ConfigPath" -Silent $true
        return $Global:WinKitConfig
    }
    catch {
        throw "Failed to load configuration: $_"
    }
}

# =========================================================
# INITIALIZE WINKIT (CORE ONLY)
# =========================================================
function Initialize-WinKit {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = "$PSScriptRoot\..\config.json"
    )

    Write-Log -Level INFO -Message "Initializing WinKit core interface" -Silent $true

    # 1. Load configuration
    Load-Configuration -ConfigPath $ConfigPath | Out-Null

    # 2. Initialize logger if config exists
    if ($Global:WinKitConfig.Logging) {
        Initialize-Logger -Config $Global:WinKitConfig.Logging
    }

    # 3. Validate registry presence
    if (-not $Global:WinKitFeatureRegistry) {
        $Global:WinKitFeatureRegistry = @()
        Write-Log -Level WARN -Message "Feature registry was empty – initialized new registry" -Silent $true
    }

    Write-Log -Level INFO -Message "WinKit core initialized successfully" -Silent $true
    return $true
}

# =========================================================
# MERGE HASHTABLES (UTILITY – CORE SAFE)
# =========================================================
function Merge-Hashtables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Base,

        [Parameter(Mandatory)]
        [hashtable]$Override
    )

    foreach ($key in $Override.Keys) {
        if (
            $Base.ContainsKey($key) -and
            $Base[$key] -is [hashtable] -and
            $Override[$key] -is [hashtable]
        ) {
            Merge-Hashtables -Base $Base[$key] -Override $Override[$key]
        }
        else {
            $Base[$key] = $Override[$key]
        }
    }

    return $Base
}

# =========================================================
# HELPER: CONVERT TO HASHTABLE (DEEP)
# =========================================================
function ConvertTo-Hashtable {
    param(
        [Parameter(Mandatory)]
        $InputObject
    )

    if ($InputObject -is [System.Collections.IDictionary]) {
        $hash = @{}
        foreach ($key in $InputObject.Keys) {
            $hash[$key] = ConvertTo-Hashtable $InputObject[$key]
        }
        return $hash
    }
    elseif ($InputObject -is [System.Collections.IEnumerable] -and
            -not ($InputObject -is [string])) {
        return @(
            foreach ($item in $InputObject) {
                ConvertTo-Hashtable $item
            }
        )
    }
    elseif ($InputObject -is [pscustomobject]) {
        $hash = @{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            $hash[$prop.Name] = ConvertTo-Hashtable $prop.Value
        }
        return $hash
    }

    return $InputObject
}

# =========================================================
# MODULE EXPORT
# =========================================================
if ($MyInvocation.InvocationName -ne '.') {
    Export-ModuleMember -Function `
        Initialize-WinKit, `
        Load-Configuration, `
        Merge-Hashtables
}
