# ==========================================
# WinKit UI Module
# Presentation and layout functions
# ==========================================

function Initialize-UI {
    Clear-Host
    
    # Load and display ASCII art if available
    $asciiPath = Join-Path $global:WK_ROOT "assets\ascii.txt"
    if (Test-Path $asciiPath) {
        try {
            $asciiArt = Get-Content $asciiPath
            foreach ($line in $asciiArt) {
                Write-Host $line -ForegroundColor $WK_THEME.Header
            }
            Write-Host ""
        }
        catch {
            # If ASCII fails, show minimal header
            Write-Host "WinKit" -ForegroundColor $WK_THEME.Header
            Write-Host "══════════════════════════════════════════" -ForegroundColor $WK_THEME.Border
        }
    }
    else {
        Write-Host "WinKit - Windows Optimization Toolkit" -ForegroundColor $WK_THEME.Header
        Write-Host "══════════════════════════════════════════" -ForegroundColor $WK_THEME.Border
    }
}

function Show-Header {
    $sysInfo = Get-WKSystemInfo
    
    Write-Host "┌─────────────────────────────────────────────────────┐" -ForegroundColor $WK_THEME.Border
    Write-Host "│ " -NoNewline -ForegroundColor $WK_THEME.Border
    Write-Host "$($sysInfo.User)" -NoNewline -ForegroundColor $WK_THEME.Primary
    Write-Host " | " -NoNewline -ForegroundColor $WK_THEME.Secondary
    Write-Host "$($sysInfo.Computer)" -NoNewline -ForegroundColor $WK_THEME.Primary
    Write-Host " | " -NoNewline -ForegroundColor $WK_THEME.Secondary
    Write-Host "$($sysInfo.OS) $($sysInfo.Build)" -NoNewline -ForegroundColor $WK_THEME.Primary
    Write-Host " | " -NoNewline -ForegroundColor $WK_THEME.Secondary
    Write-Host "$($sysInfo.Arch)" -ForegroundColor $WK_THEME.Primary
    
    Write-Host "│ " -NoNewline -ForegroundColor $WK_THEME.Border
    Write-Host "$($sysInfo.TimeZone)" -NoNewline -ForegroundColor $WK_THEME.Secondary
    Write-Host " | " -NoNewline -ForegroundColor $WK_THEME.Secondary
    Write-Host "v1.0.0" -NoNewline -ForegroundColor $WK_THEME.Accent
    Write-Host " | " -NoNewline -ForegroundColor $WK_THEME.Secondary
    Write-Host "github.com/mkhai2589/winkit" -ForegroundColor $WK_THEME.Highlight
    Write-Host "├─────────────────────────────────────────────────────┤" -ForegroundColor $WK_THEME.Border
}

function Show-Footer {
    try {
        $versionPath = Join-Path $global:WK_ROOT "version.json"
        if (Test-Path $versionPath) {
            $version = Read-Json -Path $versionPath
            Write-Host "`nWinKit $($version.version) ($($version.channel))" -ForegroundColor $WK_THEME.Secondary
        }
    }
    catch {
        Write-Host "`nWinKit v1.0.0" -ForegroundColor $WK_THEME.Secondary
    }
}

function Show-Section {
    param(
        [string]$Title,
        [string]$Color = "Yellow"
    )
    
    Write-Host "`n$Title" -ForegroundColor $Color
    Write-Host ("─" * $Title.Length) -ForegroundColor $WK_THEME.Border
}
