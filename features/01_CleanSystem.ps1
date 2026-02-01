# ==========================================
# WinKit Feature: Clean System
# ==========================================

function Start-CleanSystem {
    Write-Host ""
    Write-Host "CLEAN SYSTEM" -ForegroundColor Cyan
    Write-Host "-------------------------------------"

    $options = @(
        "Clean TEMP (User + Windows)",
        "Clean Windows Update Cache",
        "Clean Prefetch",
        "Clean Event Logs (Basic)",
        "Run ALL (Recommended)",
        "Back to Main Menu"
    )
    
    $choice = Get-WKChoice -Prompt "Select operation:" -Options $options
    
    switch ($choice) {
        1 { Clean-Temp }
        2 { Clean-WindowsUpdate }
        3 { Clean-Prefetch }
        4 { Clean-EventLogs }
        5 { 
            if (Get-WKConfirm -Message "Run FULL System Clean?" -Dangerous) {
                Show-WKProgress -Activity "System Clean" -Status "Starting full cleanup..."
                
                Clean-Temp
                Clean-WindowsUpdate
                Clean-Prefetch
                Clean-EventLogs
                
                Complete-WKProgress
                Write-Host "`nFull system clean completed successfully!" -ForegroundColor Green
                Write-WKLog -Message "Full system clean completed" -Level INFO -Feature "CleanSystem"
            }
            else {
                Write-Host "Operation cancelled." -ForegroundColor Yellow
            }
        }
        6 { return }
    }
    
    Pause-WK
}

# -----------------------------
# SUB-FUNCTIONS
# -----------------------------
function Clean-Temp {
    Write-Host "`nCleaning TEMP folders..." -ForegroundColor Cyan
    
    try {
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "TEMP folders cleaned." -ForegroundColor Green
        Write-WKLog -Message "TEMP folders cleaned" -Level INFO -Feature "CleanSystem"
    }
    catch {
        Write-Host "Error cleaning TEMP folders: $_" -ForegroundColor Red
        Write-WKLog -Message "Error cleaning TEMP: $_" -Level ERROR -Feature "CleanSystem"
    }
}

function Clean-WindowsUpdate {
    Write-Host "`nCleaning Windows Update cache..." -ForegroundColor Cyan
    
    try {
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Stop-Service bits -Force -ErrorAction SilentlyContinue
        
        Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        Start-Service wuauserv -ErrorAction SilentlyContinue
        Start-Service bits -ErrorAction SilentlyContinue
        
        Write-Host "Windows Update cache cleaned." -ForegroundColor Green
        Write-WKLog -Message "Windows Update cache cleaned" -Level INFO -Feature "CleanSystem"
    }
    catch {
        Write-Host "Error cleaning Windows Update cache: $_" -ForegroundColor Red
        Write-WKLog -Message "Error cleaning Windows Update cache: $_" -Level ERROR -Feature "CleanSystem"
    }
}

function Clean-Prefetch {
    Write-Host "`nCleaning Prefetch..." -ForegroundColor Cyan
    
    try {
        Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Prefetch cleaned." -ForegroundColor Green
        Write-WKLog -Message "Prefetch cleaned" -Level INFO -Feature "CleanSystem"
    }
    catch {
        Write-Host "Error cleaning Prefetch: $_" -ForegroundColor Red
        Write-WKLog -Message "Error cleaning Prefetch: $_" -Level ERROR -Feature "CleanSystem"
    }
}

function Clean-EventLogs {
    if (-not (Get-WKConfirm -Message "Clear all Event Logs?" -Dangerous)) {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }
    
    Write-Host "`nCleaning Event Logs..." -ForegroundColor Cyan
    
    try {
        wevtutil el | ForEach-Object {
            try {
                wevtutil cl $_
            }
            catch {}
        }
        
        Write-Host "Event Logs cleaned." -ForegroundColor Green
        Write-WKLog -Message "Event Logs cleaned" -Level INFO -Feature "CleanSystem"
    }
    catch {
        Write-Host "Error cleaning Event Logs: $_" -ForegroundColor Red
        Write-WKLog -Message "Error cleaning Event Logs: $_" -Level ERROR -Feature "CleanSystem"
    }
}
