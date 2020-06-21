<#
.SYNOPSIS
Query the Powershell Version

.DESCRIPTION
.

.PARAMETER Value
Value to query:
 + version
 + edition

.PARAMETER Computername
The Computer Name to query. If it's empty, the script will query local computer.

.EXAMPLE
PS> GB-CheckPS -Severity critical 
6

Check how many critical updates are pending to update

#>

Param(
    [Parameter(Position=1, Mandatory=$false)]
    [ValidateSet("version","edition")]
    [string]$Value,
  
    [Parameter(Position=1, Mandatory=$false)]
    [string]$Computername = $env:COMPUTERNAME
    )

switch ($Value) {
    version { $info = $PSVersionTable.PSVersion.Major + ($PSVersionTable.PSVersion.Minor / 10) }
    edition { $info = $PSVersionTable.PSEdition }
    Default {}
}

return $info