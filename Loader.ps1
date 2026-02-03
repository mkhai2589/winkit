function Load-CoreModule {
    param([string]$ModuleName)
    
    $path = "core\$ModuleName.ps1"
    if (Test-Path $path) {
        try {
            Write-Host "  [DEBUG] Loading module: $ModuleName" -ForegroundColor DarkGray
            
            # Đọc và kiểm tra nội dung file
            $content = Get-Content $path -Raw
            if ([string]::IsNullOrWhiteSpace($content)) {
                Write-Host "  [ERR] Module $ModuleName is empty" -ForegroundColor Red
                return $false
            }
            
            # Kiểm tra encoding và ký tự đặc biệt
            if ($content -match '[^\x00-\x7F]') {
                Write-Host "  [WARN] Module $ModuleName contains non-ASCII characters" -ForegroundColor Yellow
            }
            
            # Dot-source module
            . $path
            
            # Kiểm tra module loaded
            if ($ModuleName -eq "Logger") {
                if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
                    Write-Host "  [ERR] Logger module loaded but Write-Log not available" -ForegroundColor Red
                    return $false
                }
            }
            
            Write-TempLog -Message "Loaded core module: $ModuleName" -Level "DEBUG"
            return $true
        }
        catch {
            $errorDetails = $_
            Write-Host "  [ERR] Failed to load $ModuleName" -ForegroundColor Red
            Write-Host "        Error: $errorDetails" -ForegroundColor DarkRed
            
            Write-TempLog -Message "Failed to load $ModuleName : $errorDetails" -Level "ERROR"
            return $false
        }
    }
    else {
        Write-Host "  [ERR] Core file not found: $ModuleName.ps1" -ForegroundColor Red
        Write-TempLog -Message "Core file not found: $ModuleName.ps1" -Level "ERROR"
        return $false
    }
}
