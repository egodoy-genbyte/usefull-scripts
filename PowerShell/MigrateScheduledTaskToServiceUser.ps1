# Parameters
param ( $taskName, 
        $serviceUser,
        $prefix = "_new_")

# Service User (MSA) validation
if ( $serviceUser.Substring($serviceUser.Length - 1) -ne '$' ) {
    Write-Host 'The service user must end with $' -ForegroundColor Red -BackgroundColor White
    Write-Host 'For example: "dominio\s-abc001$"'  -ForegroundColor Red -BackgroundColor White
    exit
    }

if ( $serviceUser.IndexOf("\") -eq -1 ) {
    Write-Host 'The service user (MSA) must identify with the domain' -ForegroundColor Red -BackgroundColor White
    Write-Host 'For example: "dominio\s-abc001$"'  -ForegroundColor Red -BackgroundColor White
    exit
    }

# Read original task
$task = Get-ScheduledTask -TaskName $taskName

# Configure new task
$principal = New-ScheduledTaskPrincipal -UserID $serviceUser -LogonType Password
$actions = $task.Actions
$triggers = $task.Triggers
$description = $task.Description
$name = $prefix + $task.TaskName

# Validate description
if ($null -eq $description) {
    Write-Host "No hay descripción de la tarea" -BackgroundColor White -ForegroundColor Black
    $description = "Sin descripción"
    }

# Create new task
Register-ScheduledTask $name -Description $description –Action $actions –Trigger $triggers –Principal $principal