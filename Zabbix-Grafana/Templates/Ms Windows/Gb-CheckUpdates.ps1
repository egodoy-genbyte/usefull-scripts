<#
.SYNOPSIS
Query the quantity of updates pending to install

.DESCRIPTION
This script is intended to be used in Zabbix Agent for Windows, and will return single values.
It can be used to query updates pending to install with determined severity.

.PARAMETER Severity
Severity allowed:
 + critical
 + all

.PARAMETER Computername
The Computer Name to query. If it's empty, the script will query local computer.

.EXAMPLE
PS> GB-CheckUpdates.ps1 -Severity critical 
6

Check how many critical updates are pending to update

#>

Param(
  [Parameter(Position=0, Mandatory=$true)]
  [ValidateSet("critical","all")]
  [string]$Severity,

  [Parameter(Position=1, Mandatory=$false)]
  [string]$Computername = $env:COMPUTERNAME
  )

$updatesession =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$computer))

$updatesearcher = $updatesession.CreateUpdateSearcher()
$searchresult = $updatesearcher.Search("IsInstalled=0")

switch ($Severity) {
  all { $quantity = $searchresult.Updates.Count }

  critical {

    $quantity = 0

    foreach ($update in $searchresult.Updates){
      if ($update.MsrcSeverity -eq $severity){$quantity = $quantity + 1}
    }
    
  }
  Default {}
}

Write-Host $quantity