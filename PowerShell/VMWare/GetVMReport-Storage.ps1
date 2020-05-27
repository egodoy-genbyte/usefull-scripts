param ( $user, 
        $server,
        $repoName = "vm-datastore.csv")

$cred = Get-Credential $user

Import-Module VMware.PowerCLI

Connect-VIServer -Server $server -Credential $cred

$vms = Get-VM | Select-Object Name, ResourcePool,UsedSpaceGB,
    @{N="Datastore";E={[string]::Join(',',(Get-Datastore -Id $_.DatastoreIdList | Select-Object -ExpandProperty Name))}}

$vms | Export-Csv vms-datastore-sede.csv