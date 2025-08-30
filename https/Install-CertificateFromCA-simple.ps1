#require -admin


[cmdletbinding()]
param( )

$hostname = $env:computername + '.' + $env:USERDNSDOMAIN
write-verbose "Hostname: $hostname"


$args = @(
    "pkcs12","-certpbe","PBE-SHA1-3DES","-keypbe","PBE-SHA1-3DES","-nomac","-export"
    "-out","./$($HostName).pfx"
    "-in","./$($HostName).crt"
    "-inkey","./$($HostName).key"
    #"-passin","env:KeyPassIn"
    #"-passout","env:KeyPassOut"
)

& '\\tsclient\c\program files\git\usr\bin\openssl.exe' $args

#region Import into Cert Store

$result = Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\My -FilePath "./$($HostName).pfx"
$result | fl * 

#endregion 


