##  PENDIGN:
#   Log or alert

# Parameters
param ( $sourceServer, 
        $updateReg = $true,
        $exportPath = "C:\Windows\Temp\Npsconfig.xml")

# Verify if required modules are installed
if ($null -eq (Get-Module WindowsCompatibility -ListAvailable)) {
    Write-Host "Installing WindowsCompatibility Module..." -ForegroundColor Black -BackgroundColor Yellow
    Install-Module WindowsCompatibility
}

# Import requiered modules (excep NPS)
Import-Module WindowsCompatibility
Import-WinModule ServerManager

# Verify if NPAS feature is installed
if ("Installed" -ne (Get-WindowsFeature NPAS).InstallState) {
    Write-Host "Installing NPAS Feature..." -ForegroundColor Black -BackgroundColor Yellow
    Install-WindowsFeature -Name NPAS
}

# Verify if NPAS Admin Tools are installed
if ("Installed" -ne (Get-WindowsFeature RSAT-NPAS).InstallState) {
    Write-Host "Installing NPAS administration tools (incl. powershell module)..." -ForegroundColor Black -BackgroundColor Yellow
    Install-WindowsFeature -Name RSAT-NPAS
}

# Export config on source server
Invoke-Command -ComputerName $sourceServer -ScriptBlock {Import-Module NPS; Export-NpsConfiguration -Path "C:\Windows\Temp\Npsconfig.xml" }
$sourcePath = "\\" + $sourceServer + "\c$\Windows\Temp\Npsconfig.xml"
$sourceFile = Get-Item $sourcePath

#Verify if the file was created, and if its recent
if ($sourceFile.LastWriteTime -gt (Get-Date).AddMinutes(-10)){
    Write-Host "The new config was exported" -ForegroundColor Black -BackgroundColor Green
    Copy-Item -Path $sourcePath -Destination "C:\Windows\Temp\Npsconfig.xml"

    Import-WinModule nps
    Import-NpsConfiguration -Path $exportPath

    Remove-Item $sourcePath
    Remove-Item $exportPath

} else {
    Write-Host "The new config wasn't exported. Please verify if source server is correctly configured" -ForegroundColor White -BackgroundColor Red
}
