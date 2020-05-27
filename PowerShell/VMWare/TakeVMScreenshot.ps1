# vm-23984
# https://sv-vcsa.genneia.com.ar/screen?id=vm-23984&h=1080&w=1920

$uri = "https://sv-vcsa.genneia.com.ar/screen?id=vm-23984&h=1080&w=1920"
$cred = Get-Credential "genneia\egodoy"
Invoke-WebRequest -Uri $uri -SkipCertificateCheck -Credential $cred