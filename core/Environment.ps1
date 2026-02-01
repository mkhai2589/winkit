$Global:WinKitEnv = @{}

function Initialize-Environment {
    $os = Get-CimInstance Win32_OperatingSystem
    $Global:WinKitEnv.OSName  = $os.Caption
    $Global:WinKitEnv.Build   = $os.BuildNumber
    $Global:WinKitEnv.Version = $os.Version

    if ($os.Caption -match "Windows 11") {
        $Global:WinKitEnv.OS = "Windows11"
    } elseif ($os.Caption -match "Windows 10") {
        $Global:WinKitEnv.OS = "Windows10"
    } else {
        $Global:WinKitEnv.OS = "Unknown"
    }
}
