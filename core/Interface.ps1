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
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $admin = if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { "YES" } else { "NO" }
        
        # Network status
        $online = Test-Connection 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue
        $mode = if ($online) { "Online" } else { "Offline" }
        
        # Time Zone with location
        $tz = Get-TimeZone
        $timeZone = "$($tz.Id) (UTC$($tz.BaseUtcOffset.ToString().Substring(0,6)))"
        
        # TPM check
        $tpmStatus = "NO"
        try {
            $tpm = Get-Tpm -ErrorAction SilentlyContinue
            if ($tpm -and $tpm.TpmPresent) { $tpmStatus = "YES" }
        } catch {
            try {
                $tpm = Get-WmiObject -Class Win32_Tpm -Namespace "root\cimv2\security\microsofttpm" -ErrorAction SilentlyContinue
                if ($tpm -and $tpm.IsEnabled_InitialValue) { $tpmStatus = "YES" }
            } catch {
                $tpmStatus = "NO"
            }
        }
        
        # Disk info - compact display
        $disks = Get-PSDrive -PSProvider FileSystem | Where-Object Root | ForEach-Object {
            $freeGB = [math]::Round($_.Free / 1GB, 1)
            $usedGB = [math]::Round($_.Used / 1GB, 1)
            $totalGB = $freeGB + $usedGB
            $percentage = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100) } else { 0 }
            
            @{
                Name = $_.Name
                FreeGB = $freeGB
                UsedGB = $usedGB
                TotalGB = $totalGB
                Percentage = $percentage
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

function Write-WKInfo([string]$Message) {
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

function Write-WKSuccess([string]$Message) {
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-WKWarn([string]$Message) {
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-WKError([string]$Message) {
    Write-Host "[-] $Message" -ForegroundColor Red
}

function Ask-WKConfirm([string]$Message, [switch]$Dangerous) {
    Write-Host ""
    
    if ($Dangerous) {
        Write-Host "=== DANGEROUS OPERATION ===" -ForegroundColor Red
        Write-Host $Message -ForegroundColor White
        Write-Host "==========================" -ForegroundColor Red
        Write-Host "Type 'YES' to confirm: " -ForegroundColor Red -NoNewline
        return (Read-Host) -eq "YES"
    }
    else {
        Write-Host "$Message [y/N]: " -ForegroundColor Yellow -NoNewline
        $input = Read-Host
        return $input -in @('y', 'Y', 'yes', 'YES')
    }
}
