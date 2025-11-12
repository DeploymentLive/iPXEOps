[cmdletbinding()]
param( 
    $SubjectAlternateName = "subjectAltName=DNS.1:*.deploymentlive.com",
    $ServerName = 'aws.deploymentlive.com'
)

write-verbose "servername: $servername"

$args = @(
    "req","-newkey","rsa:2048"
    "-keyout","./$($servername).key"
    "-out","./$($servername).req"
    "-subj","/CN=$servername"
    # "-passout","env:KeyPass"
    "-nodes"
    "-addext",$SubjectAlternateName
    "-batch","-verbose"
)

echo $args
& 'openssl.exe' $args

    