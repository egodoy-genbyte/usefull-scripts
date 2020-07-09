<#
.SYNOPSIS
Query Windows Server DHCP Scopes, and usage

.DESCRIPTION
Script for use in Zabbix. It will query Windows Server DHCP Scopes, and usage

.PARAMETER Operation
Operations:
 + discover: to discover all DHCP scopes
 + query: to check used % of IP in specific scope

.PARAMETER ScopeID
Needed to check used % of IP in specific scope

.EXAMPLE
PS> GB-CheckDHCP -Operation "discover" 
{
    "{#NAME}":  "10.2.2.0",
    "{#ID}":  "10.2.2.0"
}

Discover all DCHP Scopes

.EXAMPLE
PS> GB-CheckDHCP.ps1 -Operation query -ScopeID "10.2.2.0"
95.2381

check used % of IP in scope "10.2.2.0"
#>

Param(
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateSet("discover","query")]
    [string]$Operation,

    [Parameter(Position=1, Mandatory=$false)]
    [string]$ScopeID
)

Import-Module DhcpServer

switch ($Operation) {
    discover {

        $scopes = Get-DhcpServerv4Scope | Select-Object Name, ScopeId
        $scopeInfo = @()
        foreach ($scope in $scopes){
            $scopeInfo += New-Object psobject -Property @{'{#NAME}'=$scope.Name;'{#ID}'=[string]$scope.ScopeId}
            }

        Write-Host "{`"data`":"
        Write-Host (ConvertTo-Json $scopeInfo)
        Write-Host "}"
        }
    
    query {
    
        $Stats = Get-DhcpServerv4ScopeStatistics -ScopeId $ScopeID
        $IPinUseP = (($Stats.PercentageInUse).ToString()).replace(",",".")

        Write-Host $IPinUseP
    }
}