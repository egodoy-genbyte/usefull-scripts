Param(
  [string]$Severity
  )

$Computername = $env:COMPUTERNAME
$updatesession =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$computer))

$updatesearcher = $updatesession.CreateUpdateSearcher()
$searchresult = $updatesearcher.Search("IsInstalled=0")

$critical = 0

foreach ($update in $searchresult.Updates){
    if ($update.MsrcSeverity -eq $severity){$critical = $critical + 1}
    }

Write-Host $critical