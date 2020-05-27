param (
    [string]$proxyIP,
    [string]$TLSPSKIdentity,
    [string]$sharedFolder,
    [Parameter(Mandatory=$true)]
    [array]$serverList
)

#Import-WinModule Microsoft.PowerShell.Management -ErrorAction SilentlyContinue

$Path = "\Program Files\Zabbix Agent"
$LocalPath = "C:"+$Path
$date = (Get-Date -Format "yyyy.MM.dd").ToString()
$LogFile = "ZabbixDeploy-"+$date+".log"
$count = $serverList.Count

#if ($proxy -eq "sede"){$proxyIP = "172.16.3.101"}
#else {
#    if ($proxy -eq "teco") {$proxyIP = "172.16.228.101"}
#    else {
#        Write-Host "Proxy no valido" -BackgroundColor Red -ForegroundColor White
#        exit
#        }
#    }

Write-Host "Iniciando Deploy" -BackgroundColor White -ForegroundColor Red
Write-Host "Proxy utilizado $proxy"
Write-Host "Servidores: $count"
$serverList

Add-Content -Path $LogFile -Value "================================================" -ErrorAction Stop
Add-Content -Path $LogFile -Value "Deploy-Zabbix.ps1 - $date"
Add-Content -Path $LogFile -Value "------------------------------------------------" 
Add-Content -Path $LogFile -Value "Proxy: $proxyIP, Servidores: $count"
Add-Content -Path $LogFile -Value "$serverList"
Add-Content -Path $LogFile -Value "------------------------------------------------" 


foreach ($server in $serverList)
    {
	$Hostname = $server

    $RemotePath = "\\$Hostname\"+'c$'+$Path

    #Estructura de Directorios
    New-Item -ItemType "directory" $RemotePath -ErrorAction SilentlyContinue -InformationAction SilentlyContinue | Out-Null
    New-Item -ItemType "directory" ($RemotePath+"\conf.d") -ErrorAction SilentlyContinue -InformationAction SilentlyContinue | Out-Null
    New-Item -ItemType "directory" ($RemotePath+"\Scripts") -ErrorAction SilentlyContinue -InformationAction SilentlyContinue | Out-Null

    #Archivos necesarios
    #Copy-Item "$sharedFolder\general.conf" -Destination ($RemotePath+"\conf.d") No Implementado aun
    Copy-Item "$sharedFolder\GB-CheckUpdates.ps1" -Destination ($RemotePath+"\Scripts")
    Copy-Item "$sharedFolder\*.exe" -Destination $RemotePath
    Copy-Item "$sharedFolder\psk.key" -Destination $RemotePath

    #Archivo de configuracion
    $Conf = @("LogType=system",
              "Server= $proxyIP",
              "ServerActive= $proxyIP",
              "Hostname=$Hostname",
			  "EnableRemoteCommands=1",
			  "UnsafeUserParameters=1"
              "TLSConnect=psk"
              "TLSAccept=psk"
              "TLSPSKIdentity=$TLSPSKIdentity"
              "TLSPSKFile=C:\Program Files\Zabbix Agent\psk.key"
              "Timeout=15"
              ""
              "Include=C:\Program Files\Zabbix Agent\conf.d\*.conf"
              ""
              'UserParameter=powershell_version[*],powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\Scripts\GB-CheckPSVersion.ps1"'
              'UserParameter=pending_updates[*],powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\Scripts\GB-CheckUpdates.ps1" "$1"'
             )
	
    $Conf | Out-File -FilePath "$RemotePath\Conf_Zabbix.conf" -Encoding ascii
    
    $ScriptBlok = '"'+ $LocalPath + '\zabbix_agentd.exe" -i -c "' + $LocalPath + '\Conf_Zabbix.conf"'
	(Get-WMIObject -ComputerName $Hostname -List | Where-Object -FilterScript {$_.Name -eq "Win32_Process"}).InvokeMethod("Create","$ScriptBlok")
    Start-Sleep -s 5

    $ScriptBlok = '"'+ $LocalPath + '\zabbix_agentd.exe" -s'
    (Get-WMIObject -ComputerName $Hostname -List | Where-Object -FilterScript {$_.Name -eq "Win32_Process"}).InvokeMethod("Create","$ScriptBlok")
    Start-Sleep -s 2

    #$Result = Invoke-Command -ComputerName $Hostname -ScriptBlock {Get-Service "Zabbix Agent"} -ErrorAction SilentlyContinue
    $Result = Get-WMIObject Win32_Service -computer Sv-WebApps-Prd -Filter "Name LIKE '%Zabbix%'"

    if ($null -eq $Result){
        Add-Content -Path $LogFile -Value "Servicio en $Hostname NO INSTALADO"
        }
    else {
        if ($Result.Status -eq "Running"){Add-Content -Path $LogFile -Value "Servicio en $Hostname OK"}
        else{ if ($Result.Status -eq "Stopped"){Add-Content -Path $LogFile -Value "Servicio en $Hostname instalado pero NO INICIADO"}
              else {Add-Content -Path $LogFile -Value "Servicio en $Hostname INDETERMINADO"} }
        }
    }