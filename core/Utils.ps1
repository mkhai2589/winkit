# ==========================================
# WinKit Utilities Module
# Common helper functions
# ==========================================

function Read-Json {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    # Validate file exists
    if (-not (Test-Path $Path)) {
        throw "JSON file not found: $Path"
    }
    
    try {
        # Read and parse JSON
        $content = Get-Content $Path -Raw -ErrorAction Stop
        return $content | ConvertFrom-Json
    }
    catch {
        throw "Failed to parse JSON from $Path : $_"
    }
}
function Write-Json {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [object]$Data
    )
    
    try {
        $Data | ConvertTo-Json -Depth 10 | Out-File $Path -Encoding UTF8
    }
    catch {
        throw "Failed to write JSON to $Path : $_"
    }
}

function Pause {
    param(
        [string]$Message = "Press Enter to continue..."
    )
    
    Write-Host ""
    Write-Host $Message -ForegroundColor DarkGray
    [Console]::ReadKey($true) | Out-Null
}
