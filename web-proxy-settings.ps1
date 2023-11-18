[system.net.webrequest]::DefaultWebProxy = new-object system.net.webproxy('http://proxy.ups.com:8080')
[System.Net.WebRequest]::DefaultWebProxy.Credentials = Get-Credential
# Also, you can get the user password from a saved XML file (see the article “Using saved credentials in PowerShell scripts”):
#$password = ConvertTo-SecureString "theBlueParr0t!12" -AsPlainText -Force
#[System.Net.WebRequest]::DefaultWebProxy.Credentials = New-Object System.Management.Automation.PSCredential($ENV:Username, $password)
#[System.Net.WebRequest]::DefaultWebProxy= Import-Clixml -Path C:\upgf\user_creds.xml
[system.net.webrequest]::DefaultWebProxy.BypassProxyOnLocal = $true
