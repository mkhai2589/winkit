# core/Logger.ps1
# WinKit Logging Engine - Silent, Rotation, No Console Spam
# KHÔNG Export-ModuleMember - Dot-source only

# ============================================
# GLOBAL LOGGER CONFIGURATION - ĐẢM BẢO LUÔN TỒN TẠI
# ============================================

# Khởi tạo global config nếu chưa có
if (-not $Global:WinKitLoggerConfig) {
    $Global:WinKitLoggerConfig = @{
        LogPath = $null
        MaxSizeMB = 1
        MaxBackupFiles = 3
        IsInitialized = $false
        CurrentLogFile = $null
        LogQueue = [System.Collections.Queue]::new()
        IsWriting = $false
    }
}

# Khởi tạo temp log ngay nếu chưa có logger
if (-not $Global:WinKitLoggerConfig.IsInitialized) {
    # Tạo temp log directory
    $tempLogDir = "$env:TEMP\winkit"
    if (-not (Test-Path $tempLogDir)) {
        New-Item -ItemType Directory -Path $tempLogDir -Force | Out-Null
    }
    
    # Tạo temp log file
    $tempLogFile = "$tempLogDir\winkit-loader.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] [BOOTSTRAP] Logger.ps1 starting" | Out-File -FilePath $tempLogFile -Append -Force
}
