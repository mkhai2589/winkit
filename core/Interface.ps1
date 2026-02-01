# ===============================
# WinKit - Interface Layer
# Unified user interaction
# ===============================

# --------- Internal helpers ---------

function Write-WKLine {
    param (
        [string]$Text = "",
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [switch]$NoNewLine
    )

    if ($NoNewLine) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Write-WKSeparator {
    param (
        [string]$Char = "=",
        [int]$Length = 60
    )

    Write-Host ($Char * $Length) -ForegroundColor DarkGray
}

# --------- Message types ---------

function Write-WKInfo {
    param ([string]$Message)
    Write-WKLine "[*] $Message" Cyan
}

function Write-WKSuccess {
    param ([string]$Message)
    Write-WKLine "[+] $Message" Green
}

function Write-WKWarn {
    param ([string]$Message)
    Write-WKLine "[!] $Message" Yellow
}

function Write-WKError {
    param ([string]$Message)
    Write-WKLine "[X] $Message" Red
}

function Write-WKTitle {
    param ([string]$Title)

    Write-WKSeparator
    Write-WKLine " $Title" White
    Write-WKSeparator
}

# --------- User interaction ---------

function Ask-WKConfirm {
    param (
        [string]$Message,
        [switch]$DefaultYes,
        [switch]$Dangerous  # NEW: For critical operations
    )

    if ($Dangerous) {
        Write-WKWarn "⚠️  CRITICAL OPERATION"
        Write-WKSeparator
        $prompt = "$Message Type 'YES' to confirm: "
        Write-WKLine $prompt Red -NoNewLine
        $input = Read-Host
        return ($input -eq "YES")
    }
    elseif ($DefaultYes) {
        $prompt = "$Message [Y/n]: "
    } else {
        $prompt = "$Message [y/N]: "
    }

    Write-WKLine $prompt Yellow -NoNewLine
    $input = Read-Host
    $input = $input.Trim().ToLower()

    if ([string]::IsNullOrEmpty($input)) {
        return $DefaultYes.IsPresent
    }

    return ($input -eq "y" -or $input -eq "yes")
}

function Pause-WK {
    param (
        [string]$Message = "Press Enter to continue..."
    )

    Write-WKLine ""
    Write-WKLine $Message DarkGray
    [void][System.Console]::ReadLine()
}

function Ask-WKChoice {
    param (
        [string]$Prompt,
        [array]$Options
    )

    if (-not $Options -or $Options.Count -eq 0) {
        throw "Ask-WKChoice: Options list is empty."
    }

    Write-WKLine $Prompt Cyan

    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-WKLine (" {0}. {1}" -f ($i + 1), $Options[$i]) Gray
    }

    while ($true) {
        Write-WKLine "Select option [1-$($Options.Count)]: " Yellow -NoNewLine
        $choice = Read-Host

        if ($choice -match '^\d+$') {
            $num = [int]$choice
            if ($num -ge 1 -and $num -le $Options.Count) {
                return $num
            }
        }

        Write-WKWarn "Invalid selection. Try again."
    }
}

# --------- Critical operation wrapper ---------

function Invoke-WKSafely {
    param (
        [string]$Title,
        [scriptblock]$Action
    )

    Write-WKTitle $Title

    try {
        & $Action
        Write-WKSuccess "Completed successfully."
    }
    catch {
        Write-WKError $_.Exception.Message
        throw
    }
}

# --------- Minimal Core Abstraction (NEW) ---------

function Write-WKLog {
    param (
        [string]$Message,
        [string]$Feature = "System"  # Optional feature name for logging
    )
    
    # Simple wrapper around existing Write-Log
    # This keeps feature from calling core directly
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time [$Feature] - $Message" | Out-File -Append $global:WK_LOG
}

function Get-WKFeatureMetadata {
    param (
        [string]$FeatureId
    )
    
    # Simple metadata reader
    $configPath = Join-Path $global:WK_ROOT "config.json"
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    
    if ($FeatureId) {
        return $config.features | Where-Object { $_.id -eq $FeatureId }
    }
    
    return $config.features
}

function Test-WKFeatureAvailable {
    param (
        [string]$FeatureId
    )
    
    $feature = Get-WKFeatureMetadata -FeatureId $FeatureId
    if (-not $feature) { return $false }
    
    $featurePath = Join-Path $global:WK_FEATURES $feature.file
    return Test-Path $featurePath
}

function Show-WKProgress {
    param (
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete = -1
    )
    
    if ($PercentComplete -ge 0) {
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    }
    else {
        Write-Progress -Activity $Activity -Status $Status
    }
}

function Complete-WKProgress {
    Write-Progress -Completed
}
