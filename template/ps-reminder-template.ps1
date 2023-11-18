Add-Type -AssemblyName PresentationFramework
$expireDate = Get-ADUser -Identity 'qqq9xmb' –Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" | Select-Object @{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed") }} 
$expiryDate = $expiredate | Select-Object -Property ExpiryDate -ExpandProperty ExpiryDate | out-string
$currentDate = Get-Date
$timeLeft = [System.TimeSpan]::FromTicks($currentDate.Ticks - $expiryDate.Ticks)
$daysLeft = [math]::Ceiling($timeLeft.TotalDays)
$formattedDaysLeft = "{0} days left" -f $daysLeft
$message = [System.Windows.MessageBox]::Show("Change your password! You have $timeLeft days left!")
