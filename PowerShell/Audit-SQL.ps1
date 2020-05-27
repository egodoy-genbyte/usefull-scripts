#region Variables
$Servidores = @("Sv-SQL","Sv-WebApps-PRD", "Sv-IDEO", "Sv-Filenet-SQL", "Intranet-Prd-SQL", "Sv-WebApps-QA")
$consulta = @()
#endregion

$sqlQuery = [string](Get-Content ".\Audit-SQL.sql")

Write-Host "Este script requiere el modulo de SQL server" -ForegroundColor Green

if (Get-Module -ListAvailable -Name SqlServer) {
    Write-Host "EL modulo esta instalado, importandolo en la sesion" -ForegroundColor Gray
    Import-Module SqlServer
} else {
    Write-Host "El modulo no esta instalado, comenzalo la instalacion (Yo que vos digo todo SI) e importandolo en la sesion" -ForegroundColor Gray
    Install-Module -Name SqlServer -AllowClobber
    Import-Module SqlServer
}

Write-Host "Empecemos!" -ForegroundColor Yellow

foreach ($Servidor in $Servidores)
    {
    $Size = 0
    $CountBasesParcial = 0
    Write-Host "Analizando $Servidor"

    $Consulta += Invoke-SQLCmd -Query $sqlQuery -Database master -ServerInstance $Servidor

    }

Write-Host "Mi tarea aqui ha terminado" -ForegroundColor DarkGray