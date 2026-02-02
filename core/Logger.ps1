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
    param(
        [string]$LogPath = "$env:TEMP\winkit"
    )
    
    try {
        # Xóa tất cả log cũ trong thư mục này
        if (Test-Path $LogPath) {
            Get-ChildItem -Path $LogPath -Filter "*.log" -File | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        else {
            New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
        }
        
        # Tạo tên file log mới
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $logFile = Join-Path $LogPath "winkit-$timestamp.log"
        
        $Global:WinKitLoggerConfig.LogPath = $logFile
        $Global:WinKitLoggerConfig.IsInitialized = $true
        
        # Tạo file log
        New-Item -ItemType File -Path $logFile -Force | Out-Null
        
        return $true
    }
    catch {
        # Fallback
        $Global:WinKitLoggerConfig.LogPath = "$env:TEMP\winkit_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $Global:WinKitLoggerConfig.IsInitialized = $true
        
        try {
            New-Item -ItemType File -Path $Global:WinKitLoggerConfig.LogPath -Force | Out-Null
        }
        catch {}
        
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
        $logFile = $Global:WinKitLoggerConfig.LogPath
        if (Test-Path $logFile) {
            $logSize = (Get-Item $logFile).Length / 1MB
            if ($logSize -ge $Global:WinKitLoggerConfig.MaxSizeMB) {
                Rotate-Log -LogFile $logFile
            }
        }
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8 -Force
        
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

function Test-Logger {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log -Level INFO -Message "Logger self-test started" -Silent $true
        Write-Log -Level WARN -Message "This is a warning test" -Silent $true
        Write-Log -Level ERROR -Message "This is an error test" -Silent $true
        
        $logPath = Get-LogPath
        if (Test-Path $logPath) {
            Write-Log -Level INFO -Message "Logger self-test completed" -Silent $true
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# KHÔNG DÙNG Export-ModuleMember
