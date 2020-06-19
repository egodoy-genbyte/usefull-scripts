<#
.SYNOPSIS
Discover Services, DB Names, or get sizes

.DESCRIPTION
This script is intended to be used in Zabbix Agent for Windows, and will return single values or JSON structures. 
It can be used to discover the SQL Services and Databases, or get the DB (Log and Data files) sizes.
You will also find relevant information like free space in files, and growth
You will need a local user in SQL with the appropriate permissions.

.PARAMETER Operation
Operations allowed:
 + services: Discover all SQL instances (and it's related service)
 + discover: Discover all DB names and it's corresponding ID
 + sizeDAT: Get DB Data file/s Size. You will need to provide DB Name
 + sizeLOG: Get DB Log file/s Size. You will need to provide DB Name
 + freeDAT: Get free space in DATA File
 + freeLOG: Get free space in LOG File
 + grDAT: Get how much the DB DATA file will grogth nex time
 + grLOG: Get how much the DB LOG file will grogth nex time
 + grpDAT: If the DATA file growth in %
 + grpLOG: If the LOG file growth in %
.PARAMETER UsrSQL
Local user in SQL Server
.PARAMETER PwdSQL
Password for local user in SQL Server
.PARAMETER DBname
Used to identify the DB for "size operation"

.EXAMPLE
PS> GB-SQL.ps1 -Operation discover -UsrSQL "Usr" -PwdSQL "Pwd"
{"data":
[
    {
        "{#NAME}":  "DB_NAME_1",
        "{#DBID}":  5
    },
    {
        "{#NAME}":  "DB_NAME_2",
        "{#DBID}":  6
    }
]
}

Discover all databases  (return Name and ID) exept system

.EXAMPLE
PS> GB-SQL.ps1 -Operation services
{"data":
{
    "#DNAME":  "SQL Server (MSSQLSERVER)",
    "#NAME":  "MSSQLSERVER"
}
}

Discover all instances and corresponding services

.EXAMPLE
PS> GB-SQL.ps1 -Operation sizeDAT -UsrSQL "Usr" -PwdSQL "Pwd" -DBname "DadaBaseName"
321088

Get DB (in this case with ID 5) DATA size in MB

#>

Param(
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateSet("services","discover","sizeDAT","sizeLOG","freeDAT","freeLOG","grDAT","grLOG","grpDAT","grpLOG")]
    [string]$Operation,

    [Parameter(Position=1, Mandatory=$false)]
    [string]$UsrSQL,

    [Parameter(Position=2, Mandatory=$false)]
    [string]$PwdSQL,

    [Parameter(Position=3, Mandatory=$false)]
    [string]$DBname
    )

function OuputZabbix {

    param (
        [array]$data
    )
    
    Write-Host "{`"data`":"
    Write-Host (ConvertTo-Json $data)
    Write-Host "}"
}

function ConnectSQL {
    param (
        [string]$UsrSQL,
        [string]$PwdSQL
    )

    $connection = New-Object System.Data.SqlClient.SqlConnection
    
    $sqlServer = $env:COMPUTERNAME
    $connectionString = "Server = $sqlServer; User ID = $UsrSQL; Password = $PwdSQL;"
    #$connectionString = "Server = $sqlServer; Integrated Security = True;"

    $connection.ConnectionString = $connectionString

    return $connection
}

function querySQL {
    param (
        $connection,
        $query
    )
    
    $connection.Open()
        
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $query
    $SqlCmd.Connection = $Connection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($DataSet) > $null

    $Connection.Close()

    return $DataSet
}

function buildSizeQuery {
    param (
        [string]$fileTipe,
        [string]$DBname
    )

    $query = @( "USE DB-NAME"
                "SELECT size/128 AS `'SIZEMB`'",
                ",size/128 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128 AS `'FREESIZEMB`'",
                ",growth AS `'FILEGROWTH`'",
                ",is_percent_growth AS `'FILEGROWTHPERCENT`'",
                "FROM sys.database_files WHERE type IN (0,1)",
                "AND type_desc = `'DB-FILE`'"
                )

    $query = $query -replace "DB-NAME","$DBname"
    $query = $query -replace "DB-FILE","$fileTipe"

    return $query
}

switch ($Operation) {
    "services" {  

        $sqlInstances = get-service | Where-Object {$_.DisplayName -like "*SQL Server (*"} | `
        Select-Object -Property @{label='{#DNAME}';expression={$_.DisplayName}},@{label='{#NAME}';expression={$_.Name}}
    
        OuputZabbix $sqlInstances
    }

    "discover" {

        $query = 'SELECT name as "{#NAME}",dbid as "{#DBID}" FROM sysdatabases WHERE dbid > 4'
        $dataSet = querySQL (ConnectSQL $UsrSQL $PwdSQL) $query
    
        $baseName = $DataSet.Tables[0]
        
        OuputZabbix ($baseName | Select-Object "{#NAME}","{#DBID}")
    }

    "sizeLOG" {

        $query = buildSizeQuery "LOG" $DBname
        $dataSet = querySQL (ConnectSQL $UsrSQL $PwdSQL) $query

        $baseSize = $DataSet.Tables[0]
    
        Write-Host ($baseSize.SIZEMB)
    }

    "sizeDAT" {

        $query = buildSizeQuery "ROWS" $DBname
        $dataSet = querySQL (ConnectSQL $UsrSQL $PwdSQL) $query

        $baseSize = $DataSet.Tables[0]
    
        Write-Host ($baseSize.SIZEMB)
    }

    "freeDAT" {

        $query = buildSizeQuery "ROWS" $DBname
        $dataSet = querySQL (ConnectSQL $UsrSQL $PwdSQL) $query

        $baseSize = $DataSet.Tables[0]
    
        Write-Host ($baseSize.FREESIZEMB)
    }
    
    "freeLOG" {

        $query = buildSizeQuery "LOG" $DBname
        $dataSet = querySQL (ConnectSQL $UsrSQL $PwdSQL) $query

        $baseSize = $DataSet.Tables[0]
    
        Write-Host ($baseSize.FREESIZEMB)
    }
    
    "grDAT" {

        $query = buildSizeQuery "ROWS" $DBname
        $dataSet = querySQL (ConnectSQL $UsrSQL $PwdSQL) $query

        $baseSize = $DataSet.Tables[0]
    
        Write-Host ($baseSize.FILEGROWTH)
    }

    "grLOG" {

        $query = buildSizeQuery "LOG" $DBname
        $dataSet = querySQL (ConnectSQL $UsrSQL $PwdSQL) $query

        $baseSize = $DataSet.Tables[0]
    
        Write-Host ($baseSize.FILEGROWTH)
    }
    
    "grpDAT" {

        $query = buildSizeQuery "ROWS" $DBname
        $dataSet = querySQL (ConnectSQL $UsrSQL $PwdSQL) $query

        $baseSize = $DataSet.Tables[0]
    
        Write-Host ($baseSize.FILEGROWTHPERCENT)
    }

    "grpLOG" {

        $query = buildSizeQuery "LOG" $DBname
        $dataSet = querySQL (ConnectSQL $UsrSQL $PwdSQL) $query

        $baseSize = $DataSet.Tables[0]
    
        Write-Host ($baseSize.FILEGROWTHPERCENT)
    }

    Default {}
}