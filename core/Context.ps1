# core/Context.ps1
# WinKit Unified Context Provider - SINGLE SOURCE OF TRUTH
# DO NOT ADD BUSINESS LOGIC HERE - PROVIDE DATA ONLY

function Get-WinKitContext {
    [CmdletBinding()]
    param()
    
    # SYSTEM CONTEXT - OS/Hardware Information
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    
    $systemContext = [PSCustomObject]@{
        Edition        = if ($os) { $os.Caption } else { "Unknown" }
        BuildNumber    = [System.Environment]::OSVersion.Version.Build
        Version        = [System.Environment]::OSVersion.Version
        IsWindows11    = [System.Environment]::OSVersion.Version.Build -ge 22000
        Architecture   = if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
        ComputerName   = [System.Environment]::MachineName
        UserName       = [System.Environment]::UserName
        Domain         = [System.Environment]::UserDomainName
        OSVersion      = [System.Environment]::OSVersion.VersionString
        SystemDrive    = $env:SystemDrive
        TotalMemoryGB  = if ($os) { [math]::Round($os.TotalVisibleMemorySize / 1MB, 2) } else { 0 }
        InstallDate    = if ($os) { $os.InstallDate } else { $null }
    }
    
    # SECURITY CONTEXT - Check Only, No Modifications
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    
    # Check online status with multiple fallbacks
    $isOnline = $false
    $testHosts = @("8.8.8.8", "1.1.1.1", "www.microsoft.com")
    foreach ($host in $testHosts) {
        try {
            $ping = New-Object System.Net.NetworkInformation.Ping
            $result = $ping.Send($host, 2000)
            if ($result.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                $isOnline = $true
                break
            }
        } catch {
            continue
        }
    }
    
    $securityContext = [PSCustomObject]@{
        IsAdmin         = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        IsOnline        = $isOnline
        PSVersion       = $PSVersionTable.PSVersion
        ExecutionPolicy = (Get-ExecutionPolicy -Scope Process).ToString()
        UserSID         = $identity.User.Value
        IsElevated      = if ($identity -and $identity.User) {
            $token = $identity.Token
            $elevated = $token -band 0x2000
            [bool]$elevated
        } else { $false }
    }
    
    # RUNTIME CONTEXT - WinKit Internal State
    $runtimeContext = [PSCustomObject]@{
        StartTime     = [datetime]::Now
        LogPath       = if ($Global:WinKitLoggerConfig -and $Global:WinKitLoggerConfig.LogPath) { 
            $Global:WinKitLoggerConfig.LogPath 
        } else { 
            "$env:TEMP\winkit" 
        }
        FeatureCount  = if ($Global:WinKitFeatureRegistry) { 
            $Global:WinKitFeatureRegistry.Count 
        } else { 
            0 
        }
        LoadedModules = Get-Module | Where-Object { $_.Name -like "WinKit*" } | Select-Object -ExpandProperty Name
        ProcessId     = $PID
        SessionId     = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
    }
    
    # DISK CONTEXT - Storage Information
    $diskContext = [PSCustomObject]@{
        SystemDrive = [PSCustomObject]@{
            Drive       = $env:SystemDrive
            FreeGB      = try { 
                $drive = Get-PSDrive -Name $env:SystemDrive.Replace(':', '') -ErrorAction Stop
                [math]::Round($drive.Free / 1GB, 2)
            } catch { 0 }
            TotalGB     = try {
                $drive = Get-PSDrive -Name $env:SystemDrive.Replace(':', '') -ErrorAction Stop
                [math]::Round(($drive.Free + $drive.Used) / 1GB, 2)
            } catch { 0 }
            UsedPercent = try {
                $drive = Get-PSDrive -Name $env:SystemDrive.Replace(':', '') -ErrorAction Stop
                if (($drive.Free + $drive.Used) -gt 0) {
                    [math]::Round(($drive.Used / ($drive.Free + $drive.Used)) * 100, 1)
                } else { 0 }
            } catch { 0 }
        }
    }
    
    # RETURN UNIFIED CONTEXT OBJECT
    return [PSCustomObject]@{
        System   = $systemContext
        Security = $securityContext
        Runtime  = $runtimeContext
        Disk     = $diskContext
        Timestamp = [datetime]::Now
    }
}

# Aliases for backward compatibility (Optional but recommended)
function Get-SystemContext {
    return (Get-WinKitContext).System
}

function Get-SecurityContext {
    return (Get-WinKitContext).Security
}

function Get-RuntimeContext {
    return (Get-WinKitContext).Runtime
}

function Get-DiskContext {
    return (Get-WinKitContext).Disk
}

# Export only necessary functions (when loaded as module)
if ($MyInvocation.InvocationName -eq '.') {
    # Dot-sourcing, no export needed
} else {
    Export-ModuleMember -Function Get-WinKitContext, Get-SystemContext, Get-SecurityContext, Get-RuntimeContext, Get-DiskContext
}
