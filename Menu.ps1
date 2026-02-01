# ==========================================
# WinKit Main Menu Module
# Data-driven menu system - NO HARD-CODED PATHS
# ==========================================

function Show-MainMenu {
    # Main loop - keeps returning to menu until exit
    while ($true) {
        try {
            Clear-Host
            
            # Initialize UI components
            Initialize-UI
            
            # ===== LOAD CONFIGURATION =====
            # Build path using GLOBAL variable
            $configPath = Join-Path $global:WK_ROOT "config.json"
            
            # Validate config file exists
            if (-not (Test-Path $configPath)) {
                throw "Configuration file not found.`nExpected at: $configPath"
            }
            
            # Read configuration
            $config = Read-Json -Path $configPath
            $features = $config.features | Sort-Object order
            
            # ===== DISPLAY HEADER =====
            Write-Host "┌─────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
            Write-Host "│" -NoNewline -ForegroundColor DarkGray
            Write-Host "                    MAIN MENU                         " -NoNewline -ForegroundColor Cyan
            Write-Host "│" -ForegroundColor DarkGray
            Write-Host "├─────────────────────────────────────────────────────┤" -ForegroundColor DarkGray
            
            # ===== DISPLAY FEATURES =====
            foreach ($feature in $features) {
                # Format: [ORDER] TITLE
                Write-Host "│ " -NoNewline -ForegroundColor DarkGray
                Write-Host "[$($feature.order)]" -NoNewline -ForegroundColor Green
                Write-Host " $($feature.title)" -ForegroundColor White
                
                # Display description if available
                if ($feature.description) {
                    Write-Host "│   " -NoNewline -ForegroundColor DarkGray
                    Write-Host "$($feature.description)" -ForegroundColor Gray
                }
                
                # Optional: Show admin requirement
                if ($feature.requireAdmin) {
                    Write-Host "│   " -NoNewline -ForegroundColor DarkGray
                    Write-Host "[Requires Admin]" -ForegroundColor DarkYellow
                }
                
                Write-Host "│" -ForegroundColor DarkGray
            }
            
            # ===== DISPLAY FOOTER =====
            Write-Host "├─────────────────────────────────────────────────────┤" -ForegroundColor DarkGray
            Write-Host "│ " -NoNewline -ForegroundColor DarkGray
            Write-Host "[0]" -NoNewline -ForegroundColor Red
            Write-Host " Exit" -ForegroundColor White
            Write-Host "└─────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
            
            # Show version info
            Write-Host ""
            Write-Host "WinKit v1.0.0" -ForegroundColor DarkGray
            Write-Host "───────────────────────────────────────────────────────" -ForegroundColor DarkGray
            
            # ===== GET USER INPUT =====
            Write-Host ""
            $choice = Read-Host "Select option (0-$($features[-1].order))"
            
            # Handle exit
            if ($choice -eq "0") {
                Write-Host "`nExiting WinKit..." -ForegroundColor Cyan
                Start-Sleep -Milliseconds 500
                exit 0
            }
            
            # Validate input
            if (-not ($choice -match '^\d+$')) {
                Write-Host "`nInvalid input! Please enter a number." -ForegroundColor Red
                Pause
                continue
            }
            
            # Find selected feature
            $selectedFeature = $features | Where-Object { $_.order -eq [int]$choice }
            
            if (-not $selectedFeature) {
                Write-Host "`nOption $choice not available!" -ForegroundColor Red
                Pause
                continue
            }
            
            # ===== EXECUTE SELECTED FEATURE =====
            Execute-Feature -Feature $selectedFeature
            
        }
        catch {
            # Error handling for menu display
            Write-Host "`nMENU ERROR: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Returning to main menu in 3 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }
    }
}

function Execute-Feature {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Feature
    )
    
    try {
        # Clear screen for feature execution
        Clear-Host
        
        # Show feature header
        Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║" -NoNewline -ForegroundColor Cyan
        Write-Host "          $($Feature.title.PadRight(38))" -NoNewline -ForegroundColor White
        Write-Host "║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
        
        if ($Feature.description) {
            Write-Host "$($Feature.description)" -ForegroundColor Gray
            Write-Host ""
        }
        
        # Build feature file path
        $featurePath = Join-Path $global:WK_FEATURES $Feature.file
        
        # Validate feature file exists
        if (-not (Test-Path $featurePath)) {
            throw "Feature file not found:`n$featurePath"
        }
        
        # Load the feature file
        Write-Host "Loading feature module..." -ForegroundColor DarkGray
        . $featurePath
        
        # Construct function name (e.g., Start-CleanSystem)
        $functionName = "Start-$($Feature.id)"
        
        # Check if function exists
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            # Execute the feature
            Write-Host "Executing..." -ForegroundColor DarkGray
            Write-Host "───────────────────────────────────────────────────────" -ForegroundColor DarkGray
            Write-Host ""
            
            & $functionName
            
            # Log successful execution
            try { Write-Log -Message "Feature executed: $($Feature.id)" -Level "INFO" } catch {}
        }
        else {
            throw "Feature function '$functionName' not found in $($Feature.file)"
        }
        
    }
    catch {
        # Feature execution error
        Write-Host "`nFEATURE ERROR: $($_.Exception.Message)" -ForegroundColor Red
        
        # Try to log the error
        try { Write-Log -Message "Feature execution failed: $($Feature.id) - $_" -Level "ERROR" } catch {}
    }
    finally {
        # Always return to menu
        Write-Host ""
        Write-Host "───────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "Press Enter to return to main menu..." -ForegroundColor DarkGray -NoNewline
        [Console]::ReadKey($true) | Out-Null
    }
}

# Helper function for pausing (compatible with Interface.ps1)
function Pause {
    Write-Host ""
    Write-Host "Press Enter to continue..." -ForegroundColor DarkGray -NoNewline
    [Console]::ReadKey($true) | Out-Null
}
