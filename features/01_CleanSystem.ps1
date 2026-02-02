# features/01_CleanSystem.ps1
# Feature mẫu - Clean System

$FeatureMetadata = @{
    Id           = "CleanSystem"
    Title        = "Clean System"
    Category     = "Essential"
    Order        = 1
    Description  = "Clean temporary files and system junk"
    RequireAdmin = $true
    OnlineOnly   = $false
}

function Invoke-CleanSystem {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log -Level INFO -Message "Clean System feature started" -Silent $true
        
        # Simulate cleaning process
        Write-Log -Level INFO -Message "Cleaning temporary files..." -Silent $true
        Start-Sleep -Seconds 2
        
        Write-Log -Level INFO -Message "Cleaning Windows Update cache..." -Silent $true
        Start-Sleep -Seconds 1
        
        Write-Log -Level INFO -Message "Cleaning recycle bin..." -Silent $true
        Start-Sleep -Seconds 1
        
        Write-Log -Level INFO -Message "Clean System completed successfully" -Silent $true
        return $true
    }
    catch {
        Write-Log -Level ERROR -Message "Clean System failed: $_" -Silent $true
        return $false
    }
}

# Auto-register feature
Register-Feature -Metadata $FeatureMetadata -ScriptBlock ${function:Invoke-CleanSystem}
