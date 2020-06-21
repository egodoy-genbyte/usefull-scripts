<#
.SYNOPSIS
Update executable, conifguration and script files of Zabbix Agent for Windows.

.DESCRIPTION
This script updates the zabbix Agent for Windows in this simple steps:
1) Stops the Agent
2) Update files
3) Start the agent and check if it's OK

.PARAMETER SharedFolder
Shared folder with at least read permission that contains:
 + One ".conf" file in root. It will be used as config file
 + If there are any ".exe" for the agent, will be copied to the hosts
 + conf.d folder. All ".conf" files inside will be copied to the hosts
 + scripts foled. All files inside will be copied to the hosts 

.PARAMETER HostList
Hosts to be updated, comma separed

.EXAMPLE
PS> DeployZabbixAgent-Windows.ps1 -SharedFolder "\\Server01\Zbx" -HostList Server02,Server03
================================================
DeployZabbixAgent-Windows.ps1 - 2020.06.21
------------------------------------------------
Hosts: 2
Server02 Server03
------------------------------------------------
Service is not installed on Server02. Starting deploy...
Files copied, installing and starting service...
Service installed and started in Server02. All should be OK
Service was stopped and config/files updated in Server03. Satarting again...
Service started in Server03. All should be OK

#>

param (
    [Parameter(Mandatory=$true)]
    [string]$SharedFolder,
    
    [Parameter(Mandatory=$true)]
    [array]$HostList
)

function writeLog {
    param (
        [string]$LogFile,
        $logMsg,
        [string]$BackgroundColor = "Black",
        [string]$ForegroundColor = "White"
    )

    Add-Content -Path $LogFile -Value $logMsg
    Write-Host $logMsg -BackgroundColor $BackgroundColor -ForegroundColor $ForegroundColor
}

function copyFiles {
    param (
        $Hostname,
        $Path,
        $sharedFolder
    )

    $RemotePath = "\\$Hostname\"+'c$'+$Path

    #Archivos necesarios
    Copy-Item "$sharedFolder\conf.d\*.conf" -Destination ($RemotePath+"\conf.d") -Force
    Copy-Item "$sharedFolder\Scripts\*.*" -Destination ($RemotePath+"\Scripts") -Force
    Copy-Item "$sharedFolder\*.exe" -Destination $RemotePath -Force
    Copy-Item "$sharedFolder\*.key" -Destination $RemotePath -Force

    $confZbx = Get-Content ("$sharedFolder\" + (Get-Item $sharedFolder\*.conf).Name)
    $confZbx[ ((0..($confZbx.Count-1)) | Where-Object {$confZbx[$_] -like "Hostname*"}) ] = "Hostname=$Hostname"

    $confZbx | Out-File -FilePath "$RemotePath\Conf_Zabbix.conf" -Encoding ascii
}

function execZbxSrv {
    param (
        $ScriptBlok,
        $hostName
    )
    
    (Get-WMIObject -ComputerName $Hostname -List | Where-Object -FilterScript {$_.Name -eq "Win32_Process"}).InvokeMethod("Create","$ScriptBlok") > $null
    Start-Sleep -s 2

    $result = (Get-WMIObject Win32_Service -computer $Hostname -Filter "Name LIKE '%Zabbix%'").State

    return $result
}

#Import-WinModule Microsoft.PowerShell.Management -ErrorAction SilentlyContinue

$Path = "\Program Files\Zabbix Agent"
$LocalPath = "C:"+$Path
$date = (Get-Date -Format "yyyy.MM.dd").ToString()
$LogFile = "ZabbixUpdate-"+$date+".log"
$count = $HostList.Count

writeLog $LogFile "================================================" 
writeLog $LogFile "DeployZabbixAgent-Windows.ps1 - $date"
writeLog $LogFile "------------------------------------------------"
writeLog $LogFile "Hosts: $count"
writeLog $LogFile "$HostList"
writeLog $LogFile "------------------------------------------------"

foreach ($hostName in $HostList) {
    
    $result = execZbxSrv ('"'+ $LocalPath + '\zabbix_agentd.exe" --stop"') $hostName

    switch ($result) {
        Running {

            writeLog $LogFile "Service is running in $Hostname and shouldn't. Check if the update was applied and restart service manually" "White" "Red"
        }

        Stopped {

            copyFiles $hostName $Path $SharedFolder

            writeLog $LogFile "Service was stopped and config/files updated in $Hostname. Satarting again..."
            
            $result = execZbxSrv ( '"' + $LocalPath + '\zabbix_agentd.exe" --start' ) $hostName
            
            if ($Result -eq "Running") {
                writeLog $LogFile "Service started in $Hostname. All should be OK" "White" "DarkGreen"
            }
            else {
                writeLog $LogFile "Service stopped in $Hostname. Please check the host" "White" "Red"
            }
        }

        Default {
            writeLog $LogFile "Service is not installed on $Hostname. Starting deploy..." "White" "Blue"

            copyFiles $hostName $Path $SharedFolder

            writeLog $LogFile "Files copied, installing and starting service..."

            execZbxSrv ('"'+ $LocalPath + '\zabbix_agentd.exe" -i -c "' + $LocalPath + '\Conf_Zabbix.conf"') $hostName > $null
            $result = execZbxSrv ('"'+ $LocalPath + '\zabbix_agentd.exe" --start') $hostName

            if ($Result -eq "Running") {
                writeLog $LogFile "Service installed and started in $Hostname. All should be OK" "White" "DarkGreen"
            }
            else {
                writeLog $LogFile "Service stopped or not installed in $Hostname. Please check the host" "White" "Red"
            }
        }
    }
}