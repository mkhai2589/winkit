function Read-Json {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        throw "File not found: $Path"
    }
    
    try {
        $content = Get-Content $Path -Raw -ErrorAction Stop
        return $content | ConvertFrom-Json
    }
    catch {
        throw "Failed to read JSON from $Path : $_"
    }
}

function Pause {
    param(
        [string]$Message = "Press Enter to continue..."
    )
    Write-Host ""
    Write-Host $Message -ForegroundColor DarkGray
    [Console]::ReadKey($true)
}
