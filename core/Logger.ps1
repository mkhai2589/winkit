# core/Logger.ps1
# WinKit Logging Engine - Silent, Rotation, No Console Spam
# KHÔNG Export-ModuleMember - Dot-source only

# ============================================
# GLOBAL LOGGER CONFIGURATION
# ============================================

$Global:WinKitLoggerConfig = @{
    LogPath = $null
    MaxSizeMB = 1
    MaxBackupFiles = 3
    IsInitialized = $false
    CurrentLogFile = $null
    LogQueue = [System.Collections.Queue]::new()
    IsWriting = $false
}

# ============================================
# LOG INITIALIZATION
# ============================================

function Initialize-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$LogPath = "$env:TEMP\winkit"
    )
    
    try {
        # Expand environment variables
        if ($LogPath.Contains("%TEMP%")) {
            $LogPath = $LogPath.Replace("%TEMP%", $env:TEMP)
        }
        
        # XÓA TOÀN BỘ LOG CŨ TRƯỚC KHI BẮT ĐẦU
        if (Test-Path $LogPath) {
            Get-ChildItem -Path $LogPath -Filter "winkit*.log*" -File | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        else {
            New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
        }
        
        # Tạo tên file log với timestamp và random ID
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $randomId = [guid]::NewGuid().ToString().Substring(0, 6)
        $logFile = Join-Path $LogPath "winkit-$timestamp-$randomId.log"
        
        # Tạo file log
        New-Item -ItemType File -Path $logFile -Force | Out-Null
        
        # Cập nhật config
        $Global:WinKitLoggerConfig.LogPath = $logFile
        $Global:WinKitLoggerConfig.CurrentLogFile = $logFile
        $Global:WinKitLoggerConfig.IsInitialized = $true
        
        # Ghi header log đầu tiên
        $startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $psVersion = $PSVersionTable.PSVersion.ToString()
        $osVersion = [System.Environment]::OSVersion.VersionString
        
        $header = @"
=================================================================
WinKit Log File - $startTime
PowerShell: $psVersion | OS: $osVersion
Log Path: $logFile
=================================================================
"@
        
        [System.IO.File]::AppendAllText($logFile, $header + "`n")
        
        # Log sự kiện khởi tạo (KHÔNG in ra console)
        Write-Log -Level INFO -Message "Logger initialized successfully" -Silent $true
        
        return $true
    }
    catch {
        # Silent fallback - không in ra console
        try {
            # Fallback log file
            $fallbackFile = "$env:TEMP\winkit-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
            
            $Global:WinKitLoggerConfig.LogPath = $fallbackFile
            $Global:WinKitLoggerConfig.CurrentLogFile = $fallbackFile
            $Global:WinKitLoggerConfig.IsInitialized = $true
            
            New-Item -ItemType File -Path $fallbackFile -Force | Out-Null
            
            Write-Log -Level ERROR -Message "Logger initialization failed, using fallback: $_" -Silent $true
            return $false
        }
        catch {
            # Ultimate fallback - memory only
            $Global:WinKitLoggerConfig.IsInitialized = $true
            return $false
        }
    }
}

# ============================================
# LOG WRITING WITH ROTATION
# ============================================

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
        $logFile = $Global:WinKitLoggerConfig.CurrentLogFile
        
        # Check if log file exists and needs rotation
        if (Test-Path $logFile) {
            $fileInfo = Get-Item $logFile
            $sizeMB = $fileInfo.Length / 1MB
            
            if ($sizeMB -ge $Global:WinKitLoggerConfig.MaxSizeMB) {
                Rotate-Log -LogFile $logFile
                # Update current log file after rotation
                $Global:WinKitLoggerConfig.CurrentLogFile = $logFile
            }
        }
        
        # Format log entry
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $logEntry = "[$timestamp] [$Level] $Message"
        
        # Write to log file (thread-safe append)
        [System.IO.File]::AppendAllText($logFile, $logEntry + "`n")
        
        # NEVER output to console (UX principle)
        # Console output is handled by UI module only
        
    }
    catch {
        # Silent fail - logging should not break the application
        # Could write to event log as fallback, but keeping simple for now
    }
}

# ============================================
# LOG ROTATION (1MB MAX, 3 BACKUPS)
# ============================================

function Rotate-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogFile
    )
    
    try {
        $maxBackup = $Global:WinKitLoggerConfig.MaxBackupFiles
        $logDir = Split-Path $LogFile -Parent
        
        # Xóa backup cũ nhất nếu tồn tại
        $oldestBackup = "$LogFile.$maxBackup"
        if (Test-Path $oldestBackup) {
            Remove-Item $oldestBackup -Force -ErrorAction SilentlyContinue
        }
        
        # Shift existing backups (.1 → .2, .2 → .3, etc.)
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
        
        # Tạo log file mới với cùng tên
        New-Item -ItemType File -Path $LogFile -Force | Out-Null
        
        # Ghi log rotation event
        $rotationTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $rotationMsg = "[$rotationTime] [INFO] Log rotated - new file created"
        [System.IO.File]::AppendAllText($LogFile, $rotationMsg + "`n")
        
    }
    catch {
        # If rotation fails, truncate current log
        try {
            Set-Content -Path $LogFile -Value "" -Encoding UTF8 -Force
            Write-Log -Level WARN -Message "Log rotation failed, truncated current log: $_" -Silent $true
        }
        catch {
            # Last resort - do nothing
        }
    }
}

# ============================================
# LOG MANAGEMENT FUNCTIONS
# ============================================

function Get-LogPath {
    [CmdletBinding()]
    param()
    
    return $Global:WinKitLoggerConfig.CurrentLogFile
}

function Get-LogHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$LastLines = 50
    )
    
    try {
        $logFile = $Global:WinKitLoggerConfig.CurrentLogFile
        if (Test-Path $logFile) {
            return Get-Content $logFile -Tail $LastLines -ErrorAction Stop
        }
        return @()
    }
    catch {
        return @()
    }
}

function Clear-Log {
    [CmdletBinding()]
    param()
    
    try {
        $logFile = $Global:WinKitLoggerConfig.CurrentLogFile
        if (Test-Path $logFile) {
            Set-Content -Path $logFile -Value "" -Encoding UTF8 -Force
            Write-Log -Level INFO -Message "Log cleared manually" -Silent $true
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

function Test-Logger {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log -Level INFO -Message "Logger self-test started" -Silent $true
        Write-Log -Level WARN -Message "This is a warning test message" -Silent $true
        Write-Log -Level ERROR -Message "This is an error test message" -Silent $true
        Write-Log -Level DEBUG -Message "This is a debug test message" -Silent $true
        
        $logPath = Get-LogPath
        if (Test-Path $logPath) {
            $fileInfo = Get-Item $logPath
            Write-Log -Level INFO -Message "Logger test completed. File: $($fileInfo.FullName), Size: $($fileInfo.Length) bytes" -Silent $true
            return $true
        }
        
        return $false
    }
    catch {
        return $false
    }
}

function Get-LogStats {
    [CmdletBinding()]
    param()
    
    try {
        $logFile = $Global:WinKitLoggerConfig.CurrentLogFile
        if (Test-Path $logFile) {
            $fileInfo = Get-Item $logFile
            $lineCount = (Get-Content $logFile | Measure-Object -Line).Lines
            
            return @{
                FilePath = $fileInfo.FullName
                FileSize = "$([math]::Round($fileInfo.Length / 1KB, 2)) KB"
                LineCount = $lineCount
                Created = $fileInfo.CreationTime
                LastModified = $fileInfo.LastWriteTime
                IsInitialized = $Global:WinKitLoggerConfig.IsInitialized
            }
        }
        
        return @{
            FilePath = "Not available"
            FileSize = "0 KB"
            LineCount = 0
            IsInitialized = $false
        }
    }
    catch {
        return @{
            FilePath = "Error"
            FileSize = "0 KB"
            LineCount = 0
            IsInitialized = $false
        }
    }
}

# ============================================
# LOG FORMATTING HELPERS
# ============================================

function Format-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context
    )
    
    $formattedMessage = $Message
    
    # Thêm context nếu có
    if ($Context -and $Context.Count -gt 0) {
        $contextStr = ""
        foreach ($key in $Context.Keys) {
            $contextStr += "$key=$($Context[$key]);"
        }
        $formattedMessage += " | Context: $contextStr"
    }
    
    return $formattedMessage
}

function Write-PerformanceLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Operation,
        
        [Parameter(Mandatory=$true)]
        [TimeSpan]$Duration,
        
        [Parameter(Mandatory=$false)]
        [string]$Details = ""
    )
    
    $durationMs = [math]::Round($Duration.TotalMilliseconds, 2)
    $message = "Performance: $Operation took ${durationMs}ms"
    
    if (-not [string]::IsNullOrEmpty($Details)) {
        $message += " | $Details"
    }
    
    Write-Log -Level INFO -Message $message -Silent $true
}

# ============================================
# LOG SECURITY (NO SENSITIVE DATA)
# ============================================

function Sanitize-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    # Loại bỏ thông tin nhạy cảm tiềm tàng
    $sanitized = $Message
    
    # Mask passwords (basic pattern)
    $sanitized = $sanitized -replace '(?i)password\s*[=:]\s*\S+', 'password=***'
    $sanitized = $sanitized -replace '(?i)passwd\s*[=:]\s*\S+', 'passwd=***'
    $sanitized = $sanitized -replace '(?i)secret\s*[=:]\s*\S+', 'secret=***'
    $sanitized = $sanitized -replace '(?i)apikey\s*[=:]\s*\S+', 'apikey=***'
    $sanitized = $sanitized -replace '(?i)token\s*[=:]\s*\S+', 'token=***'
    
    # Mask potential credit card numbers (basic)
    $sanitized = $sanitized -replace '\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b', '****-****-****-****'
    
    return $sanitized
}

# ============================================
# KHÔNG Export-ModuleMember
# Functions available when dot-sourced
# ============================================
