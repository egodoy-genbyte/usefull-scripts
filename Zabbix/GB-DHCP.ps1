Param(
  [string]$Operation,
  [string]$ScopeID
)

#the function is to bring to the format understands zabbix
#function convertto-encoding ([string]$from, [string]$to){
#	begin{
#		$encfrom = [system.text.encoding]::getencoding($from)
#		$encto = [system.text.encoding]::getencoding($to)
#	}
#	process{
#		$bytes = $encto.getbytes($_)
#		$bytes = [system.text.encoding]::convert($encfrom, $encto, $bytes)
#		$encto.getstring($bytes)
#	}
#}

Import-Module DhcpServer

if ($Operation -eq "discover"){

    $scopes = Get-DhcpServerv4Scope | select Name, ScopeId

    Write-Host "{"
    Write-Host "`"data`":["

    $cant = $scopes.Count
    $prints = 1

    foreach ($scope in $scopes){
        $Name = $scope.Name
        $Id = $scope.ScopeId
        Write-Host "{"
        Write-Host "`"{#NAME}`":`"$Name`","
        Write-Host "`"{#ID}`":`"$Id`"" 
        if ($prints -lt $cant) {Write-Host "},"}
        else {Write-Host "}"}
        $prints = $prints + 1
        }

    Write-Host "]"
    Write-Host "}"

    }
if ($Operation -eq "query"){
    
    $Stats = Get-DhcpServerv4ScopeStatistics -ScopeId $ScopeID
    $IPinUseP = (($Stats.PercentageInUse).ToString()).replace(",",".")

    Write-Host $IPinUseP

    #Write-Host "{"
    #Write-Host "`"data`":["
    #Write-Host "{`"{#USED}`":`"$IPinUseP`"}"
    #Write-Host "]"
    #Write-Host "}"

    }