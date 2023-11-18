# vRA REST API

Add-Type -AssemblyName System.Security

$Url = "https://urldefense.com/v3/__https://cloud-portal.uscg.mil/deployment/api/deployments/877f7f6b-0638-4b41-a98c-7ab434741701__;!!HvcyKXabpxxkCQ!pQmJG6L8VCb51kCS9ObA7ivzokNFVwcyoIADJwoDTYKY_5ySBOl4zwWxOYMrTZgCHqckDRiAYa5EDmELYSuQIklt6BFEOKY$ "
$Path = "U:\Documents"

# Filtering for cert requirements...
$ValidCerts = [System.Security.Cryptography.X509Certificates.X509Certificate2[]](dir Cert:\CurrentUser\My | where { $_.NotAfter -gt (Get-Date) })

# You could check $ValidCerts, and not do this prompt if it only contains 1...
$Cert = [System.Security.Cryptography.X509Certificates.X509Certificate2UI]::SelectFromCollection(
    $ValidCerts,
    'Choose a certificate',
    'Choose a certificate',
    'SingleSelection'
) | select -First 1

$WebRequestParams = @{
    Uri = $Url
    OutFile = $Path 
    Certificate = $Cert
}
Invoke-WebRequest @WebRequestParams