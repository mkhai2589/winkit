function Get-WKSystemInfo {
    $info = @{
        User = [System.Environment]::UserName
        Computer = [System.Environment]::MachineName
        OS = "Windows $([System.Environment]::OSVersion.Version.Major)"
        Build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
        PSVersion = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
        Admin = if ([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { "YES" } else { "NO" }
        TimeZone = (Get-TimeZone).Id
        Version = "1.0.0"
    }
    
    try {
        $tpm = Get-Tpm -ErrorAction SilentlyContinue
        $info.TPM = if ($tpm.TpmPresent) { "YES" } else { "NO" }
    } catch {
        $info.TPM = "NO"
    }
    
    try {
        $online = Test-Connection 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue
        $info.Mode = if ($online) { "Online" } else { "Offline" }
    } catch {
        $info.Mode = "Offline"
    }
    
    try {
        $disks = Get-PSDrive -PSProvider FileSystem | Where-Object Root | ForEach-Object {
            "$($_.Name): $([math]::Round($_.Free/1GB,1))GB free"
        }
        $info.Disks = $disks -join ' | '
    } catch {
        $info.Disks = "Unknown"
    }
    
    return $info
}

function Write-WKInfo {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

function Write-WKSuccess {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-WKWarn {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-WKError {
    param([string]$Message)
    Write-Host "[-] $Message" -ForegroundColor Red
}

function Ask-WKConfirm {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [switch]$Dangerous
    )
    
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
