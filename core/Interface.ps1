function Get-WKSystemInfo {
    try {
        # OS Info
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if (-not $os) {
            throw "Cannot retrieve OS information"
        }
        
        $osName = $os.Caption
        $osBuild = $os.BuildNumber
        $osArch = if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
        
        # Combine OS info
        $fullOS = "$osName Build $osBuild ($osArch)"
        
        # User and Computer
        $user = [System.Environment]::UserName
        $computer = [System.Environment]::MachineName
        
        # PowerShell version
        $psVersion = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
        
        # Admin check
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $admin = if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { "Administrator" } else { "User" }
        
        # Network status
        $online = $false
        try {
            $online = Test-Connection 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue
        } catch {}
        $mode = if ($online) { "Online" } else { "Offline" }
        
        # Time Zone with location
        $timeZone = "Unknown"
        try {
            $tz = Get-TimeZone -ErrorAction SilentlyContinue
            if ($tz) {
                $timeZone = "$($tz.Id) (UTC$($tz.BaseUtcOffset.ToString().Substring(0,6)))"
            }
        } catch {}
        
        # TPM check
        $tpmStatus = "NO"
        try {
            $tpm = Get-Tpm -ErrorAction SilentlyContinue
            if ($tpm -and $tpm.TpmPresent) { 
                $tpmStatus = "YES" 
            }
        } catch {
            try {
                $tpm = Get-WmiObject -Class Win32_Tpm -Namespace "root\cimv2\security\microsofttpm" -ErrorAction SilentlyContinue
                if ($tpm -and $tpm.IsEnabled_InitialValue) { 
                    $tpmStatus = "YES" 
                }
            } catch {
                $tpmStatus = "NO"
            }
        }
        
        # Disk info
        $disks = @()
        try {
            $diskDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -and $_.Used -ne $null -and $_.Free -ne $null }
            foreach ($drive in $diskDrives) {
                $freeGB = [math]::Round($drive.Free / 1GB, 1)
                $usedGB = [math]::Round($drive.Used / 1GB, 1)
                $totalGB = $freeGB + $usedGB
                $percentage = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100) } else { 0 }
                
                $disks += @{
                    Name = $drive.Name
                    FreeGB = $freeGB
                    UsedGB = $usedGB
                    TotalGB = $totalGB
                    Percentage = $percentage
                }
            }
        } catch {
            # Continue without disk info
        }
        
        return @{
            User = $user
            Computer = $computer
            OS = $fullOS
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
            Admin = "User"
            Mode = "Offline"
            TimeZone = "Unknown"
            TPM = "NO"
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

# ==================== FEATURE REGISTRY SYSTEM ====================
# KHÔNG THÊM FILE MỚI - Đặt ngay trong Interface.ps1
# ================================================================

$global:WK_FEATURES_REGISTRY = @()
$global:WK_FEATURES_BY_ID = @{}
$global:WK_CATEGORIES = @{
    "Essential" = @()
    "Advanced" = @()
    "Tools" = @()
}

function Register-Feature {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Id,
        
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$false)]
        [string]$Description = "",
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Essential", "Advanced", "Tools")]
        [string]$Category,
        
        [Parameter(Mandatory=$true)]
        [int]$Order,
        
        [Parameter(Mandatory=$true)]
        [string]$FileName,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$ExecuteAction,
        
        [Parameter(Mandatory=$false)]
        [bool]$RequireAdmin = $true
    )
    
    # Validate unique ID and Order
    $existingById = $global:WK_FEATURES_REGISTRY | Where-Object { $_.Id -eq $Id }
    $existingByOrder = $global:WK_FEATURES_REGISTRY | Where-Object { $_.Order -eq $Order }
    
    if ($existingById) {
        Write-WKWarn "Feature with ID '$Id' already registered. Skipping..."
        return
    }
    
    if ($existingByOrder) {
        Write-WKWarn "Feature with Order '$Order' already registered: $($existingByOrder.Title). Assigning next available order..."
        # Find next available order
        $maxOrder = ($global:WK_FEATURES_REGISTRY | Measure-Object -Property Order -Maximum).Maximum
        $Order = $maxOrder + 1
    }
    
    $feature = [PSCustomObject]@{
        Id = $Id
        Title = $Title
        Description = $Description
        Category = $Category
        Order = $Order
        FileName = $FileName
        ExecuteAction = $ExecuteAction
        RequireAdmin = $RequireAdmin
        RegisteredAt = (Get-Date)
    }
    
    # Register feature
    $global:WK_FEATURES_REGISTRY += $feature
    $global:WK_FEATURES_BY_ID[$Id] = $feature
    
    # Add to category
    if (-not $global:WK_CATEGORIES.ContainsKey($Category)) {
        $global:WK_CATEGORIES[$Category] = @()
    }
    $global:WK_CATEGORIES[$Category] += $feature
    
    # Sort features in each category by Order
    foreach ($cat in $global:WK_CATEGORIES.Keys) {
        $global:WK_CATEGORIES[$cat] = @($global:WK_CATEGORIES[$cat] | Sort-Object Order)
    }
    
    # Sort global registry
    $global:WK_FEATURES_REGISTRY = @($global:WK_FEATURES_REGISTRY | Sort-Object Order)
    
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log -Message "Feature registered: $Id ($Title) as Order $Order in '$Category'" -Level "DEBUG"
    }
}

function Get-FeatureByOrder([int]$Order) {
    return $global:WK_FEATURES_REGISTRY | Where-Object { $_.Order -eq $Order } | Select-Object -First 1
}

function Get-FeaturesByCategory([string]$Category) {
    if ($global:WK_CATEGORIES.ContainsKey($Category)) {
        return $global:WK_CATEGORIES[$Category] | Sort-Object Order
    }
    return @()
}

function Get-AllFeatures {
    return $global:WK_FEATURES_REGISTRY | Sort-Object Order
}

function Invoke-Feature([string]$FeatureId) {
    if (-not $global:WK_FEATURES_BY_ID.ContainsKey($FeatureId)) {
        throw "Feature '$FeatureId' not found in registry"
    }
    
    $feature = $global:WK_FEATURES_BY_ID[$FeatureId]
    
    # Check admin requirement
    if ($feature.RequireAdmin) {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw "This feature requires Administrator privileges"
        }
    }
    
    # Execute the feature
    & $feature.ExecuteAction
}
