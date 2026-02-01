function Get-WKSystemInfo {
    try {
        # OS Info
        $os = Get-CimInstance Win32_OperatingSystem
        $osName = $os.Caption
        $osBuild = $os.BuildNumber
        $osArch = if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
        
        # User and Computer
        $user = [System.Environment]::UserName
        $computer = [System.Environment]::MachineName
        
        # PowerShell version
        $psVersion = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
        
        # Admin check
        $admin = if ([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { "YES" } else { "NO" }
        
        # Network status
        $online = Test-Connection 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue
        $mode = if ($online) { "Online" } else { "Offline" }
        
        # Time Zone with location
        $tz = Get-TimeZone
        $timeZone = "$($tz.Id) (UTC$($tz.BaseUtcOffset.ToString().Substring(0,6)))"
        
        # TPM check (multiple methods for compatibility)
        $tpmStatus = "NO"
        try {
            if (Get-Command Get-Tpm -ErrorAction SilentlyContinue) {
                $tpm = Get-Tpm -ErrorAction SilentlyContinue
                if ($tpm -and $tpm.TpmPresent) { $tpmStatus = "YES" }
            } elseif (Get-WmiObject -Class Win32_Tpm -Namespace "root\cimv2\security\microsofttpm" -ErrorAction SilentlyContinue) {
                $tpm = Get-WmiObject -Class Win32_Tpm -Namespace "root\cimv2\security\microsofttpm" -ErrorAction SilentlyContinue
                if ($tpm -and $tpm.IsEnabled_InitialValue) { $tpmStatus = "YES" }
            }
        } catch {
            $tpmStatus = "NO"
        }
        
        # Disk info with detailed stats
        $disks = @()
        $diskDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null -and $_.Free -ne $null }
        foreach ($drive in $diskDrives) {
            $freeGB = [math]::Round($drive.Free / 1GB, 2)
            $usedGB = [math]::Round($drive.Used / 1GB, 2)
            $totalGB = $freeGB + $usedGB
            $percentage = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100) } else { 0 }
            
            $disks += @{
                Name = $drive.Name
                FreeGB = $freeGB
                UsedGB = $usedGB
                TotalGB = $totalGB
                Percentage = $percentage
                Display = "$($drive.Name): $freeGB GB free ($percentage% used)"
            }
        }
        
        return @{
            User = $user
            Computer = $computer
            OS = $osName
            Build = $osBuild
            Arch = $osArch
            PSVersion = $psVersion
            Admin = $admin
            Mode = $mode
            TimeZone = $timeZone
            TPM = $tpmStatus
            Disks = $disks
            Version = "1.0.0"
        }
    }
    catch {
        return @{
            User = "Unknown"
            Computer = "Unknown"
            OS = "Windows"
            Build = "Unknown"
            Arch = "Unknown"
            PSVersion = "Unknown"
            Admin = "NO"
            Mode = "Offline"
            TimeZone = "Unknown"
            TPM = "UNKNOWN"
            Disks = @()
            Version = "1.0.0"
        }
    }
}
