Param(
    [string]$Usr,
    [string]$Pwd,
    [string]$Operation,
    [string]$DBid
    )

$sqlServer = $env:COMPUTERNAME
$connectionString = "Server = $sqlServer; User ID = $Usr; Password = $Pwd;"
#$connectionString = "Server = $sqlServer; Integrated Security = True;"

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()

if ($Operation -eq "discover"){
    
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = 'SELECT name as "{#NAME}",dbid as "{#DBID}" FROM sysdatabases WHERE dbid > 4'
    $SqlCmd.Connection = $Connection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($DataSet) > $null

    $baseName = $DataSet.Tables[0]
    
    Write-Host "{`"data`":"
    Write-Host (ConvertTo-Json ($baseName | select "{#NAME}","{#DBID}"))
    Write-Host "}"

    }

if ($Operation.StartsWith("size")){
    
    $query =  "SELECT "
	$query += "ROUND(SUM(mf.size) * 8, 0) AS `'SIZEMB`' "
    $query += "FROM sys.master_files mf "
    $query += "WHERE database_id = $DBid"
    if ($Operation -eq "sizeDAT") {$query += "AND type_desc = `'ROWS`'"}
    else {$query += "AND type_desc = `'LOG`'"}

    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $query
    $SqlCmd.Connection = $Connection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($DataSet) > $null

    $baseSize = $DataSet.Tables[0]
    
    Write-Host ($baseSize.SIZEMB)

    }

$Connection.Close()