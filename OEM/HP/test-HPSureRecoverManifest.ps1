[CmdletBinding()]
Param(
    $url = 'http://web.deploymentlive.com/boot/hp'
)

Invoke-WebRequest -Uri "$URL/recovery.mft" -OutFile $env:temp\Recovery.mft
Invoke-WebRequest -Uri "$URL/recovery.sig" -OutFile $env:temp\Recovery.sig

$REVerify = @(
    "dgst"
    "-verify","$PSscriptRoot\..\certs\re-pubkey.pem"
    "-signature","$env:temp\recovery.sig"
    "$env:temp\recovery.mft"
)

invoke-openssl -commands $REVerify

# TODO - download each file and check the SHA256 hash.