[cmdletbinding()]
param( 
    $SubjectAlternateName = "subjectAltName=DNS.1:*.deploymentlive.com,DNS.2:*.keithga.com"
)

$hostname = $env:computername + '.' + $env:USERDNSDOMAIN
write-verbose "Hostname: $hostname"

$args = @(
    "req","-newkey","rsa:2048"
    "-keyout","./$($HostName).key"
    "-out","./$($HostName).req"
    "-subj","/CN=$HostName"
    # "-passout","env:KeyPass"
    "-addext",$SubjectAlternateName
    "-batch","-verbose"
)

& '\\tsclient\c\program files\git\usr\bin\openssl.exe' $args

