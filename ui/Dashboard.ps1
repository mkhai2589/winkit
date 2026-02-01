function Show-Dashboard {

    Clear-Host

    # ===== SYSTEM INFO =====
    $user = $env:USERNAME
    $pc   = $env:COMPUTERNAME
    $os   = (Get-CimInstance Win32_OperatingSystem).Caption
    $build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
    $arch = if ([Environment]::Is64BitOperatingSystem) { "64bit" } else { "32bit" }
    $time = (Get-TimeZone).Id

    Write-Host "===============================================================================" -ForegroundColor DarkGray
    Write-Host " USER:" -NoNewline -ForegroundColor Cyan
    Write-Host " $user " -NoNewline -ForegroundColor White
    Write-Host "| PC:" -NoNewline -ForegroundColor Cyan
    Write-Host " $pc " -NoNewline -ForegroundColor White
    Write-Host "| OS:" -NoNewline -ForegroundColor Cyan
    Write-Host " $os $build $arch" -ForegroundColor Green
    Write-Host " TIMEZONE:" -NoNewline -ForegroundColor Cyan
    Write-Host " $time" -ForegroundColor Yellow
    Write-Host "===============================================================================" -ForegroundColor DarkGray

    # ===== DASHBOARD BODY =====
    Write-Host ""
    Write-Host " TWEAK | CLEAN | FIX" -ForegroundColor Cyan
    Write-Host " ------------------------------------------------------------------------------" -ForegroundColor DarkGray

    Write-Host " [1] Disable Copilot & Windows AI" -ForegroundColor Gray
    Write-Host " [2] Remove Recall Feature" -ForegroundColor Gray
    Write-Host " [3] Disable Telemetry & Data Collection" -ForegroundColor Gray
    Write-Host " [4] Clean Temp & System Cache" -ForegroundColor Gray
    Write-Host " [5] Clear Windows Update Cache" -ForegroundColor Gray
    Write-Host " [6] Disable OneDrive" -ForegroundColor Gray
    Write-Host " [7] Enable Classic Right Click Menu" -ForegroundColor Gray
    Write-Host " [8] Disable Windows Widgets" -ForegroundColor Gray
    Write-Host " [9] Performance Tweaks (Gaming)" -ForegroundColor Gray

    Write-Host ""
    Write-Host " INSTALLER" -ForegroundColor Cyan
    Write-Host " ------------------------------------------------------------------------------" -ForegroundColor DarkGray

    Write-Host " [10] Install Internet Browser" -ForegroundColor Gray
    Write-Host " [11] Install Dev Tools (VSCode, Git)" -ForegroundColor Gray
    Write-Host " [12] Install Media Tools" -ForegroundColor Gray
    Write-Host " [13] Install Compression Tools (7zip, WinRAR)" -ForegroundColor Gray
    Write-Host " [14] Install Gaming Clients (Steam, Epic)" -ForegroundColor Gray

    Write-Host ""
    Write-Host " SYSTEM | OTHER" -ForegroundColor Cyan
    Write-Host " ------------------------------------------------------------------------------" -ForegroundColor DarkGray

    Write-Host " [15] Check Windows Activation Status" -ForegroundColor Gray
    Write-Host " [16] Activate Windows / Office" -ForegroundColor Gray
    Write-Host " [17] Change Windows Edition" -ForegroundColor Gray
    Write-Host " [18] Change DNS (Google / Cloudflare)" -ForegroundColor Gray
    Write-Host " [19] Show Network Info (IPv4 / IPv6)" -ForegroundColor Gray

    Write-Ho
