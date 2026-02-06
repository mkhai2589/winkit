# =========================================================
# core/Context.ps1
# WinKit Unified Context Provider
# SINGLE SOURCE OF TRUTH – DATA ONLY
#
# ❌ NO business logic
# ❌ NO decision / evaluation
# ❌ NO feature-specific rules
#
# ✅ Raw system facts only
# =========================================================

function Get-WinKitContext {
    [CmdletBinding()]
    param()

    # =========================
    # SYSTEM CONTEXT (RAW FACTS)
    # =========================
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue

    $systemContext = [PSCustomObject]@{
        Caption        = $os?.Caption
        VersionString  = $os?.Version
        BuildNumber    = [Environment]::OSVersion.Version.Build
        Version        = [Environment]::OSVersion.Version
        Architecture   = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
        ComputerName   = $env:COMPUTERNAME
        UserName       = $env:USERNAME
        Domain         = $env:USERDOMAIN
        InstallDate    = $os?.InstallDate
        TotalMemoryMB  = if ($os) { [math]::Round($os.TotalVisibleMemorySize / 1KB, 0) } else { $null }
        SystemDrive    = $env:SystemDrive
    }

    # =========================
    # SECURITY CONTEXT (RAW FACTS)
    # =========================
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)

    $securityContext = [PSCustomObject]@{
        IsAdmin         = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        UserSID         = $identity.User?.Value
        PSVersion       = $PSVersionTable.PSVersion
        ExecutionPolicy = (Get-ExecutionPolicy -Scope Process).ToString()
    }

    # =========================
    # NETWORK CONTEXT (RAW FACTS)
    # =========================
    $networkTests = @()
    foreach ($host in @("8.8.8.8", "1.1.1.1", "www.microsoft.com")) {
        try {
            $ping = New-Object System.Net.NetworkInformation.Ping
            $reply = $ping.Send($host, 2000)

            $networkTests += [PSCustomObject]@{
                Host    = $host
                Success = ($reply.Status -eq 'Success')
                Status  = $reply.Status.ToString()
                TimeMs  = $reply.RoundtripTime
            }
        } catch {
            $networkTests += [PSCustomObject]@{
                Host    = $host
                Success = $false
                Status  = "Error"
                TimeMs  = $null
            }
        }
    }

    $networkContext = [PSCustomObject]@{
        PingResults = $networkTests
    }

    # =========================
    # DISK CONTEXT (RAW FACTS)
    # =========================
    $diskContext = @()
    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        $diskContext += [PSCustomObject]@{
            Name        = $drive.Name
            Root        = $drive.Root
            FreeGB      = [math]::Round($drive.Free / 1GB, 2)
            UsedGB      = [math]::Round($drive.Used / 1GB, 2)
            TotalGB     = [math]::Round(($drive.Free + $drive.Used) / 1GB, 2)
        }
    }

    # =========================
    # RUNTIME CONTEXT (RAW FACTS)
    # =========================
    $runtimeContext = [PSCustomObject]@{
        StartTime   = (Get-Date)
        ProcessId  = $PID
        SessionId  = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
        LogPath    = if ($Global:WinKitLoggerConfig?.LogPath) {
            $Global:WinKitLoggerConfig.LogPath
        } else {
            "$env:TEMP\winkit"
        }
    }

    # =========================
    # UNIFIED CONTEXT OBJECT
    # =========================
    return [PSCustomObject]@{
        System    = $systemContext
        Security  = $securityContext
        Network   = $networkContext
        Disk      = $diskContext
        Runtime   = $runtimeContext
        Timestamp = (Get-Date)
    }
}

# =========================================================
# BACKWARD-COMPATIBILITY ALIASES
# =========================================================

function Get-SystemContext   { (Get-WinKitContext).System }
function Get-SecurityContext { (Get-WinKitContext).Security }
function Get-NetworkContext  { (Get-WinKitContext).Network }
function Get-DiskContext     { (Get-WinKitContext).Disk }
function Get-RuntimeContext  { (Get-WinKitContext).Runtime }

# =========================================================
# MODULE EXPORT
# =========================================================
if ($MyInvocation.InvocationName -ne '.') {
    Export-ModuleMember -Function `
        Get-WinKitContext, `
        Get-SystemContext, `
        Get-SecurityContext, `
        Get-NetworkContext, `
        Get-DiskContext, `
        Get-RuntimeContext
}
