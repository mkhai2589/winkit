# core/Logger.ps1
# WinKit Logging Engine - Silent, Rotation, No Console Spam

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
        # Expand environment variables
        if ($LogPath.Contains("%TEMP%")) {
            $LogPath = $LogPath.Replace("%TEMP%", $env:TEMP)
        }
        
        # Create log directory if not exists
        if (-not (Test-Path $LogPath)) {
            New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
        }
        
        # Set log file path
        $logFile = Join-Path $LogPath "winkit.log"
        $Global:WinKitLoggerConfig.LogPath = $logFile
        $Global:WinKitLoggerConfig.IsInitialized = $true
        
        # Tạo file log nếu chưa tồn tại
        if (-not (Test-Path $logFile)) {
            New-Item -ItemType File -Path $logFile -Force | Out-Null
        }
        
        Write-Log -Level INFO -Message "Logger initialized at: $logFile" -Silent $true
        return $true
    }
    catch {
        # Fallback
        $Global:WinKitLoggerConfig.LogPath = "$env:TEMP\winkit_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $Global:WinKitLoggerConfig.IsInitialized = $true
        
        # Tạo file fallback
        try {
            New-Item -ItemType File -Path $Global:WinKitLoggerConfig.LogPath -Force | Out-Null
        }
        catch {
            # Last resort - in memory only
        }
        
        Write-Log -Level ERROR -Message "Failed to initialize logger: $_" -Silent $true
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
    
    # Skip if logger not initialized
    if (-not $Global:WinKitLoggerConfig.IsInitialized) {
        return
    }
    
    try {
        # Rotate log if needed
        $logFile = $Global:WinKitLoggerConfig.LogPath
        if (Test-Path $logFile) {
            $logSize = (Get-Item $logFile).Length / 1MB
            if ($logSize -ge $Global:WinKitLoggerConfig.MaxSizeMB) {
                Rotate-Log -LogFile $logFile
            }
        }
        
        # Format log entry
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        
        # Write to log file
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8 -Force
        
        # NEVER output to console (UX principle)
        # Console output is handled by UI module only
        
    }
    catch {
        # Silent fail - logging should not break the application
        # Could write to event log as fallback, but keeping simple for now
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
        
        # Delete oldest backup if exists
        $oldestBackup = "$LogFile.$maxBackup"
        if (Test-Path $oldestBackup) {
            Remove-Item $oldestBackup -Force -ErrorAction SilentlyContinue
        }
        
        # Shift existing backups
        for ($i = $maxBackup - 1; $i -ge 1; $i--) {
            $currentBackup = "$LogFile.$i"
            $nextBackup = "$LogFile.$($i + 1)"
            
            if (Test-Path $currentBackup) {
                Move-Item $currentBackup $nextBackup -Force -ErrorAction SilentlyContinue
            }
        }
        
        # Rename current log to .1
        $firstBackup = "$LogFile.1"
        if (Test-Path $LogFile) {
            Move-Item $LogFile $firstBackup -Force -ErrorAction SilentlyContinue
        }
        
        # Create new log file
        New-Item -ItemType File -Path $LogFile -Force | Out-Null
        
    }
    catch {
        # If rotation fails, truncate current log
        try {
            Set-Content -Path $LogFile -Value "" -Encoding UTF8 -Force
        }
        catch {
            # Last resort - do nothing
        }
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
        Write-Log -Level DEBUG -Message "This is a debug test" -Silent $true
        
        $logPath = Get-LogPath
        if (Test-Path $logPath) {
            Write-Log -Level INFO -Message "Logger self-test completed successfully" -Silent $true
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# Export module functions
$ExportFunctions = @(
    'Initialize-Log',
    'Write-Log',
    'Get-LogPath',
    'Test-Logger'
)

Export-ModuleMember -Function $ExportFunctions
