<#	
	.NOTES
	===========================================================================
    .DESCRIPTION
	===========================================================================
#>

#region Variables

$isDev = $true

# SMTP Host
$smtpServer = "mail.genneia.com.ar"
$fromEmail = "helpdesk@genneia.com.ar"
$expireInDays = 15

#Program File Path
$dirPath = "C:\scripts\PasswordExpiry\"
$LogFile = $dirPath + "Log" + (Get-Date -Format yyy-MM-dd) + ".txt"

#endregion

$date = Get-Date

# Get Users From AD who are Enabled, Passwords Expire and are Not Currently Expired

Add-Content -Path $LogFile -Value "$Date - INFO: Importing AD Module"
Import-Module ActiveDirectory

Add-Content -Path $LogFile -Value "$Date - INFO: Getting users"

if ($false -eq $isDev){
	$users = Get-Aduser -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress -filter { (Enabled -eq 'True') -and (PasswordNeverExpires -eq 'False') } | Where-Object { $_.PasswordExpired -eq $False }
} 
if ($true -eq $isDev) {
	$users = (Get-ADGroupMember "testMailPwd" | Get-Aduser -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress )
}

$maxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

# Process Each User for Password Expiry
foreach ($user in $users)
{
	$Name = (Get-ADUser $user | ForEach-Object { $_.Name })
	Write-Host "Working on $Name..." -ForegroundColor White
	Write-Host "Getting e-mail address for $Name..." -ForegroundColor Yellow
	$emailaddress = $user.emailaddress
	If (!($emailaddress))
	{
		Write-Host "$Name has no E-Mail address listed, looking at their proxyaddresses attribute..." -ForegroundColor Red
		Try
		{
			$emailaddress = (Get-ADUser $user -Properties proxyaddresses | Select-Object -ExpandProperty proxyaddresses | Where-Object { $_ -cmatch '^SMTP' }).Trim("SMTP:")
		}
		Catch
		{
			Add-Content -Path $LogFile -Value $_
		}
		If (!($emailaddress))
		{
			Write-Host "$Name has no email addresses to send an e-mail to!" -ForegroundColor Red
			#Don't continue on as we can't email $Null, but if there is an e-mail found it will email that address
			Add-Content -Path $LogFile -Value "$Date - WARNING: No email found for $Name"
		}
		
	}
	#Get Password last set date
	$passwordSetDate = (Get-ADUser $user -properties * | ForEach-Object { $_.PasswordLastSet })
	#Check for Fine Grained Passwords
	$PasswordPol = (Get-ADUserResultantPasswordPolicy $user)
	if ($null -ne ($PasswordPol))
	{
		$maxPasswordAge = ($PasswordPol).MaxPasswordAge
	}
	
	$expireson = $passwordsetdate + $maxPasswordAge
    $today = (get-date)
    
	#Gets the count on how many days until the password expires and stores it in the $daystoexpire var
	$daystoexpire = (New-TimeSpan -Start $today -End $Expireson).Days
	
	If (($daystoexpire -ge "0") -and ($daystoexpire -lt $expireindays))
	{
		Add-Content -Path $LogFile -Value "$Date - INFO: Sending expiry notice email to $Name"
		Write-Host "Sending Password expiry email to $name" -ForegroundColor Yellow
		
		if ($false -eq $isDev) {
			$mailMsg = new-object Net.Mail.MailMessage
			$smtp = new-object Net.Mail.SmtpClient($smtpServer, 25)

			#Who is the e-mail sent from
			$mailMsg.From = $FromEmail
			#SMTP server to send email
			$SmtpClient.Host = $SMTPHost
			#SMTP SSL
			$SMTPClient.EnableSsl = $true
			#SMTP credentials
			$SMTPClient.Credentials = $cred
			#Send e-mail to the users email
			$mailMsg.To.add("$emailaddress")
			#Email subject
			$mailMsg.Subject = "Su contraseña expira en $daystoexpire días"
			#Notification email on delivery / failure
			$mailMsg.DeliveryNotificationOptions = ("onSuccess", "onFailure")
			#Send e-mail with high priority
			$mailMsg.Priority = "High"
			$mailMsg.Body = ""
			
			Write-Host "Sending E-mail to $emailaddress..." -ForegroundColor Green
			Try
			{
				$smtp.Send($mailMsg)
			}
			Catch
			{
				Add-Content -Path $LogFile -Value $_ 
			}
		}
	}
	Else
	{
		Add-Content -Path $LogFile -Value "$Date - INFO: Password for $Name not expiring for $daystoexpire days"
		Write-Host "Password for $Name does not expire for $daystoexpire days" -ForegroundColor White
	}
}