Start-Process -Filepath '\\opnasi01\Software\Server\Downloaded Software\SymantecAV\14.3.7388.4000\setup.exe' -RunAs $env:USERNAME -Wait;
Start-Process -Filepath '\\opnasi02\server\scripts\ocs_local.bat ' -RunAs $env:USERNAME -Wait;
Start-Process -Filepath '\\opnasi01\Software\Server\Downloaded Software\URL_ReWrite\rewrite_amd64.msi' -RunAs $env:USERNAME -Wait;
Start-Process -Filepath '\\opnasi01\Software\Server\Downloaded Software\Oracle\Oracle19\ODAC1931_x64\setup.exe' -RunAs $env:USERNAME -Wait;
$file = 'C:\Windows\Microsoft.NET\assembly\GAC_64\'
if (!(Test-Path $file'\Oracle.DataAccess'))
{\\opnasi02
    copy-item -Path '\\opnasi02\server\Documents\PND\ECD\Oracle.DataAccess' -Destination $file -Force -Recurse
}
else {
    Write-Host 'Oracle.DataAccess file exists already...'
}
Start-Process -Filepath '\\opnasi01\software\Server\Downloaded Software\Db2\10.5_DataServerRuntime\v10.5fp11_ntx64_rtcl_EN.exe' -RunAs $env:USERNAME -Wait;
Start-Process -Filepath '\\opnasi01\software\Server\Downloaded Software\Db2\10.5_DataServerRuntime\v10.5fp11_ntx64_universal_fixpack.exe' -RunAs $env:USERNAME -Wait;
Start-Process -Filepath '\\opnasi01\Software\Server\Downloaded Software\SymantecAV\14.3.7388.4000\setup.exe' -RunAs $env:USERNAME -Wait;
Start-Process -Filepath '\\opnasi01\Software\Server\Downloaded Software\SymantecAV\14.3.7388.4000\setup.exe' -RunAs $env:USERNAME -Wait;
Start-Process -Filepath '\\opnasi01\Software\Server\Downloaded Software\SymantecAV\14.3.7388.4000\setup.exe' -RunAs $env:USERNAME -Wait;
Start-Process -Filepath '\\opnasi01\Software\Server\Downloaded Software\SymantecAV\14.3.7388.4000\setup.exe' -RunAs $env:USERNAME -Wait;