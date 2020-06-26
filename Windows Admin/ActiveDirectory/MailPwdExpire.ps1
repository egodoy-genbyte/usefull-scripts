<#	
	.SYNOPSIS
	Send email to users whose passwords are about to expire

    .DESCRIPTION
	This script will search in AD for users with password about to expire. With this info, will send an email encouraging them to change the password.
#>

param (
	[Parameter(Mandatory=$false)]
    [string]$SmtpServer = "smtp.server.com",
    
    [Parameter(Mandatory=$false)]
	[array]$FromEmail = "Name to Show <account@domain.com>",
	
	[Parameter(Mandatory=$false)]
	[array]$expireInDays = 15,
	
	[Parameter(Mandatory=$false)]
	[array]$dirPath,

	[Parameter(Mandatory=$false)]
	[array]$BodyPath,

	[Parameter(Mandatory=$false)]
	[array]$LogoPath
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

$LogFile = $dirPath + "Log" + (Get-Date -Format yyy-MM-dd) + ".txt"

$date = Get-Date

# Get Users From AD who are Enabled, Passwords Expire and are Not Currently Expired

writeLog $LogFile "$Date - INFO: Importing AD Module"
Import-Module ActiveDirectory

writeLog $LogFile "$Date - INFO: Getting list of users"

$users = Get-Aduser -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress -filter { (Enabled -eq 'True') -and (PasswordNeverExpires -eq 'False') } | Where-Object { $_.PasswordExpired -eq $False }

$maxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

# Process Each User for Password Expiry
foreach ($user in $users) {

	$Name = (Get-ADUser $user | ForEach-Object { $_.Name })
	writeLog $LogFile "Working on $Name..." -ForegroundColor White
	writeLog $LogFile "Getting e-mail address for $Name..." -ForegroundColor Yellow
	$emailaddress = $user.emailaddress

	If (!($emailaddress)) {
		writeLog $LogFile "$Name has no E-Mail address listed, looking at their proxyaddresses attribute..." -ForegroundColor Red
		
		Try {
			$emailaddress = (Get-ADUser $user -Properties proxyaddresses | Select-Object -ExpandProperty proxyaddresses | Where-Object { $_ -cmatch '^SMTP' }).Trim("SMTP:")
		}
		Catch {
			writeLog $LogFile $_
		}

		If (!($emailaddress)) {
			
			writeLog $LogFile "$Name has no email addresses to send an e-mail to!" -ForegroundColor Red
			#Don't continue on as we can't email $Null, but if there is an e-mail found it will email that address
			writeLog $LogFile "$Date - WARNING: No email found for $Name"
		}
		
	}

	#Get Password last set date
	$passwordSetDate = (Get-ADUser $user -properties * | ForEach-Object { $_.PasswordLastSet })
	#Check for Fine Grained Passwords
	$PasswordPol = (Get-ADUserResultantPasswordPolicy $user)

	if ($null -ne ($PasswordPol)) {
		$maxPasswordAge = ($PasswordPol).MaxPasswordAge
	}
	
	$expireson = $passwordsetdate + $maxPasswordAge
    $today = (get-date)
    
	#Gets the count on how many days until the password expires and stores it in the $daystoexpire var
	$daystoexpire = (New-TimeSpan -Start $today -End $Expireson).Days
	
	If (($daystoexpire -ge "0") -and ($daystoexpire -lt $expireindays))
	{
		$mailBody = Get-Content $bodyPath
        $mailBody = $mailBody -replace "PWD-EXPIRA","$daystoexpire"
        $mailBody = $mailBody -replace "PWD-USER","$Name"
        $mailBody = $mailBody -replace "PWD-DATE","$passwordSetDateStr"

        if ($daystoexpire -ge [int](expireInDays * 0.7)) {
			$mailBody = $mailBody -replace "PWD-COLOR","black"
		}
        if (($daystoexpire -gt [int](expireInDays * 0.3)) -and ($daystoexpire -lt [int](expireInDays * 0.7))) {
			$mailBody = $mailBody -replace "PWD-COLOR","darkorange"
		}
        if ($daystoexpire -le [int](expireInDays * 0.3)) {
			$mailBody = $mailBody -replace "PWD-COLOR","red"
		}

		writeLog $LogFile "$Date - INFO: Sending expiry notice email to $Name"
		
		$mailMsg = new-object Net.Mail.MailMessage
		$smtp = new-object Net.Mail.SmtpClient($smtpServer, 25)

		$attachLogo = New-Object System.Net.Mail.Attachment -ArgumentList $LogoPath
		$attachLogo.ContentDisposition.Inline = $True
		$attachLogo.ContentDisposition.DispositionType = "Inline"
		$attachLogo.ContentType.MediaType = "image/png"
		$attachLogo.ContentId = "Logo-Genneia.png"
		$mailMsg.Attachments.Add($attachLogo)

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
		$mailMsg.Body = $mailBody
		
		writeLog $LogFile "Sending E-mail to $emailaddress..." -ForegroundColor Green
		Try {
			$smtp.Send($mailMsg)
		}
		Catch {
			writeLog $LogFile $_ 
		}
	}
	Else {
		writeLog $LogFile "$Date - INFO: Password for $Name not expiring for $daystoexpire days"
	}
}