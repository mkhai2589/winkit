# =========================================================
# WinKit - Environment.ps1
# System & OS detection
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Global environment object
$Global:WinKitEnv = [ordered]@{}

# -------------------------
# OS DETECTION
# -------------------------
function Get-WindowsInfo {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cv = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

        return @{
            Name        = $os.Caption
            Version     = $os.Version
            Build       = [int]$cv.CurrentBuild
            ReleaseId  = $cv.ReleaseId
            DisplayVer = $cv.DisplayVersion
            Edition    = $cv.EditionID
            Arch       = $os.OSArchitecture
        }
    }
    catch {
        Write-ErrorX "Failed to detect Windows information"
        Write-ErrorX $_.Exception.Message
        Exit-WinKit
    }
}

function Detect-WindowsGeneration {
    param (
        [int]$Build
    )

    if ($Build -ge 22000) {
        return "Windows11"
    }
    elseif ($Build -ge 10240) {
        return "Windows10"
    }
    else {
        return "Unsupported"
    }
}

# -------------------------
# ENVIRONMENT INITIALIZER
# -------------------------
function Initialize-Environment {
    Write-Info "Detecting system environment"

    $info = Get-WindowsInfo
    $generation = Detect-WindowsGeneration -Build $info.Build

    if ($generation -eq "Unsupported") {
        Write-ErrorX "Unsupported Windows version detected"
        Write-ErrorX "Build number: $($info.Build)"
        Exit-WinKit
    }

    $Global:WinKitEnv = [ordered]@{
        OSName        = $info.Name
        Generation    = $generation
        Version       = $info.Version
        Build         = $info.Build
        ReleaseId     = $info.ReleaseId
        DisplayVer    = $info.DisplayVer
        Edition       = $info.Edition
        Architecture  = $info.Arch
        IsWindows10   = ($generation -eq "Windows10")
        IsWindows11   = ($generation -eq "Windows11")
    }

    Write-Success "Environment detected"
    Write-Info ("OS        : {0}" -f $Global:WinKitEnv.OSName)
    Write-Info ("Edition   : {0}" -f $Global:WinKitEnv.Edition)
    Write-Info ("Version   : {0}" -f $Global:WinKitEnv.DisplayVer)
    Write-Info ("Build     : {0}" -f $Global:WinKitEnv.Build)
    Write-Info ("Arch      : {0}" -f $Global:WinKitEnv.Architecture)
}

# -------------------------
# OS SUPPORT CHECK
# -------------------------
function Test-ModuleOSSupport {
    param (
        [Parameter(Mandatory)]
        [string[]]$SupportedOS
    )

    if ($SupportedOS -contains "All") {
        return $true
    }

    if ($Global:WinKitEnv.Generation -in $SupportedOS) {
        return $true
    }

    Write-Warn "This module does not support your OS"
    Write-Warn "Detected: $($Global:WinKitEnv.Generation)"
    Write-Warn "Supported: $($SupportedOS -join ', ')"

    return $false
}
