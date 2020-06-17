<#
.Synopsis
Create a CSV report for SQL Logins.

.Description
Create a CSV report for SQL Logins including: 
Date, Type (Success/Failure), User and Client.

.Parameter startDate
The report will include all events Afer this date (M/d/yyyy format). 
If not included, the default value is the actual date minus 2 hours.

.Parameter endDate
The report will include all events Beforte this date (M/d/yyyy format). 
If not included, the default value is the actual date.

.Parameter repoPath
Pathe where the report will be saved.
If not included, It will be saved in the current Location and named "repo.csv"

.Example
AuditSQL-WindowsEventLog.ps1

Description
-----------
Using the default parameters


.Example
AuditSQL-WindowsEventLog.ps1 -startDate ((get-date).AdDays(-1))

Description
-----------
Get the events from the las 24 hours


.Example
AuditSQL-WindowsEventLog.ps1 -StartDate 6/9/2020 -EndDate 6/10/2020 -RepoPath "\\FileServer\FileName.csv"

Description
-----------
Get the events between specific dates (in this case from june 9th to june 10th) 
and save to network share (en the example \\FileServer\FileName.csv)

.Notes
Author: Ezequiel Godoy (Genbyte)

#>

Param ( [DateTime]$StartDate,
    [DateTime]$EndDate,
    [String]$RepoPath = (Get-Location).path + "\repo.csv" )


# If no startDate specified, set to now. Else correct the format
if ($null -eq $StartDate) {$StartDate = Get-Date}
#else {$StartDate = [datetime]::parseexact($StartDate, 'd/M/yyyy', $null)}

# If no EndDate specified, set to now minus 2 hours. Else correct the format
if ($null -eq $EndDate) {$EndDate = (Get-Date).AddHours(-2)}
#else {$EndDate = [datetime]::parseexact($EndDate, 'd/M/yyyy', $null)}

# Date Strings
$startDateString = $StartDate.ToString("dddd dd MMM yyyy hh:mm")
$endDateString = $EndDate.ToString("dddd MMM yyyy hh:mm")

#get events
Write-Host "Collecting events from $endDateString to $startDateString" -BackgroundColor White -ForegroundColor Black
$events = Get-EventLog -After $endDate -Before $startDate -Source "MSSQLSERVER" -LogName "Application"
$eventTable = @()

$eventsCant = $events.count
Write-Host "$eventsCant events listed! Starting to process them..." -BackgroundColor White -ForegroundColor Black
$counter = 0

foreach ($event in $events) {
    
    $eventTime = ($event.TimeGenerated).ToString("d/M/yyyy hh:mm")
    $eventType = $event.EntryType
    
    $eventUser = [regex]::match($event.Message,"'(.*?)'").Groups[0].Value
    $eventClient = [regex]::match($event.Message,"\[(.*?)\]").Groups[0].Value

    $eventUser = ($eventUser).SubString(1,$eventUser.length-2)
    $eventClient = ($eventClient).SubString(9,$eventClient.length-10)

    $eventTable += New-Object psobject -Property @{Time=$eventTime; `
        Type=$eventType; User=$eventUser; Client=$eventClient}

    $counter++
    $currentOperation = "$eventTime - user: $eventUser - client: $eventClient"
    Write-Progress -Activity 'Processing events' -CurrentOperation "$currentOperation"  -PercentComplete (($counter / $eventsCant) * 100)
}

Write-Host "Saving to $repoPath" -BackgroundColor Green -ForegroundColor Black
$eventTable | Select-Object Time,Type,User,Client | Export-Csv -Delimiter ";" -Path $repoPath -NoTypeInformation