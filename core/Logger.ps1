# core/Logger.ps1 - WinKit Logging Engine (SILENT)
# KHÔNG DÙNG Export-ModuleMember

$Global:WinKitLoggerConfig = @{
    LogPath = $null
    MaxSizeMB = 1
    MaxBackupFiles = 3
    IsInitialized = $false
}

function Initialize-Log {
    [CmdletBinding()]
    param()
    
    try {
        $logDir = "$env:TEMP\winkit"
        
        # Xóa log cũ
        if (Test-Path $logDir) {
            Get-ChildItem -Path $logDir -Filter "*.log" -File | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        else {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        # Tạo file log mới với timestamp
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $logFile = Join-Path $logDir "winkit-$timestamp.log"
        
        $Global:WinKitLoggerConfig.LogPath = $logFile
        $Global:WinKitLoggerConfig.IsInitialized = $true
        
        # Tạo file
        New-Item -ItemType File -Path $logFile -Force | Out-Null
        
        return $true
    }
    catch {
        # Fallback
        $Global:WinKitLoggerConfig.LogPath = "$env:TEMP\winkit-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $Global:WinKitLoggerConfig.IsInitialized = $true
        return $false
    }
}



function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [bool]$Silent = $true
    )
    
    if (-not $Global:WinKitLoggerConfig.IsInitialized) {
        return
    }
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        
        Add-Content -Path $Global:WinKitLoggerConfig.LogPath -Value $logEntry -Encoding UTF8 -Force
    }
    catch {
        # Silent fail
    }
}

function Rotate-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogFile
    )
    
    try {
        $maxBackup = $Global:WinKitLoggerConfig.MaxBackupFiles
        
        # Xóa backup cũ nhất
        $oldestBackup = "$LogFile.$maxBackup"
        if (Test-Path $oldestBackup) {
            Remove-Item $oldestBackup -Force -ErrorAction SilentlyContinue
        }
        
        # Shift backups
        for ($i = $maxBackup - 1; $i -ge 1; $i--) {
            $currentBackup = "$LogFile.$i"
            $nextBackup = "$LogFile.$($i + 1)"
            
            if (Test-Path $currentBackup) {
                Move-Item $currentBackup $nextBackup -Force -ErrorAction SilentlyContinue
            }
        }
        
        # Rename current log
        $firstBackup = "$LogFile.1"
        if (Test-Path $LogFile) {
            Move-Item $LogFile $firstBackup -Force -ErrorAction SilentlyContinue
        }
        
        # Tạo log mới
        New-Item -ItemType File -Path $LogFile -Force | Out-Null
        
    }
    catch {
        try {
            Set-Content -Path $LogFile -Value "" -Encoding UTF8 -Force
        }
        catch {}
    }
}

function Get-LogPath {
    [CmdletBinding()]
    param()
    
    return $Global:WinKitLoggerConfig.LogPath
}

# KHÔNG DÙNG Export-ModuleMember
