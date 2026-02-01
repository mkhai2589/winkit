function Read-Json {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        throw "File not found: $Path"
    }
    
    try {
        $content = Get-Content $Path -Raw -ErrorAction Stop
        return $content | ConvertFrom-Json
    }
    catch {
        throw "Failed to parse JSON: $_"
    }
}

function Pause {
    param([string]$Message = "Press any key to continue...")
    Write-Host ""
    Write-Host $Message -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
