Write-Host "Removing AI related scheduled tasks..." -ForegroundColor Yellow

$tasks = Get-ScheduledTask | Where-Object {
    $_.TaskName -match "Recall|Copilot|AI"
}

foreach ($t in $tasks) {
    try {
        Unregister-ScheduledTask -TaskName $t.TaskName -Confirm:$false
        Write-Host "Removed task: $($t.TaskName)" -ForegroundColor DarkGray
    } catch {
        Write-Host "Failed task: $($t.TaskName)" -ForegroundColor Red
    }
}

Write-Host "Task cleanup done." -ForegroundColor Green
Pause
