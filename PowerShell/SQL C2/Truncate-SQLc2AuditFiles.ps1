# Parameters
param ( $sqlInstancce = "MSSQLServer", 
        $hours = 24)
Function fnGetDefaultDBLocation {
    Param ([string] $vInstance)
 
    # Get the registry key associated with the Instance Name
    $vRegInst = (Get-ItemProperty -Path HKLM:"SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" -ErrorAction SilentlyContinue).$vInstance
    $vRegPath = "SOFTWARE\Microsoft\Microsoft SQL Server\" + $vRegInst + "\MSSQLServer"

    # Get the Data and Log file paths if available
    $vDataPath = (Get-ItemProperty -Path HKLM:$vRegPath -ErrorAction SilentlyContinue).DefaultData
    
    # Report the entries found
    if ($vDataPath.Length -lt 1) {
        $vRegPath = "SOFTWARE\Microsoft\Microsoft SQL Server\" + $vRegInst + "\Setup"
        $vDataPath = (Get-ItemProperty -Path HKLM:$vRegPath -ErrorAction SilentlyContinue).SQLDataRoot + "\Data\"
        return $vDataPath
    } 
    else {return $vDataPath}
}

$dataPath = fnGetDefaultDBLocation $sqlInstancce

Get-ChildItem -path ($dataPath + "\*.trc") | Where-Object {$_.Lastwritetime -lt (Get-Date).addhours(-$hours)} | remove-item