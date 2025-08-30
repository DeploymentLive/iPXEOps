#requires -module DeploymentLiveModule
#requires -modules hp.firmware

<#
.SYNOPSIS
    Create the SK public/private keys
.DESCRIPTION
    Create the public/private Signing Keys for HP Client management.
.NOTES
    Executed only on "Signing Key" Secure Management Server (not on client)
.LINK
    https://developers.hp.com/hp-client-management/blog/hp-secure-platform-management-hp-client-management-script-library
.EXAMPLE
    $credkek = Get-Credential -UserName 'admin' -Message 'KEK Password'
    $credsk = Get-Credential -UserName 'admin' -Message 'SK Password'
    .\New-HPSigningKey.ps1 -KEKPass $credkek.Password -SKPass $Credsk.Password -Subject "/C=US/ST=AZ/L=Tucson/O=DeploymentLive/OU=Dev/CN=DeploymentLive.com"
#>

[cmdletbinding()]
param(
    [int] $Days = 3650,
    [parameter(mandatory=$false)]
    [string] $Subject = "/C=US/ST=WA/L=Mercer Island/O=DeploymentLive/OU=IT/CN=www.DeploymentLive.com",
    [string] $Name = "HP Secure Platform Signing Key Certificate",
    [string] $CertPath = "$PSScriptRoot\..\Certs\",
    $Nonce = $null,
    [parameter(mandatory=$false)]
    [SecureString] $SKPass = $Pass,
    [SecureString] $KEKPass = $Pass
)

import-module DeploymentLiveModule -force

if ( Test-path "$CertPath\sk.pfx" ) { Throw "sk.pfx is already present." }

#region Create public and private key

remove-item "$CertPath\sk-key.pem","$CertPath\sk-cert.pem" -ErrorAction SilentlyContinue
$NewKEK = @(
    "req","-x509","-nodes","-newkey","rsa:2048"
    "-keyout","$CertPath\sk-key.pem"
    "-out","$CertPath\sk-cert.pem"
    "-passout","env:skPass"
    "-days",$Days
    "-subj",$Subject
)

Invoke-OpenSSL -commands $NewKEK -passout $skPass | Write-verbose

if ( ! ( Test-path "$CertPath\sk-key.pem" ) ) { Throw "sk-key.pem is missing." }
if ( ! ( Test-path "$CertPath\sk-cert.pem" ) ) { Throw "sk-cert.pem is missing." }

#endregion

#region Create PFX

$NewKEKpfx = @(
    "pkcs12"
    "-inkey","$CertPath\sk-key.pem"
    "-in","$CertPath\sk-cert.pem"
    "-export","-keypbe","PBE-SHA1-3DES","-certpbe","PBE-SHA1-3DES"
    "-out","$CertPath\sk.pfx"
    "-name",$Name
    "-passin","env:sk1Pass"
    "-passout","env:skPass"
)

Invoke-OpenSSL -commands $NewKEKpfx -PassOut $SKPass  -PassIn $SKPass | Write-verbose

if ( ! ( Test-path "$CertPath\sk.pfx" ) ) { Throw "sk.pfx is missing." }

#endregion

#region Create KEK Payload

$SigningPayload = @{
    EndorsementKeyFile = "$CertPath\kek.pfx"
    EndorsementKeyPassword = [System.Net.NetworkCredential]::new("", $KEKPass).Password
    SigningKeyFile = "$CertPath\sk.pfx"
    SigningKeyPassword = [System.Net.NetworkCredential]::new("", $SKPass).Password
    OutputFile = "$CertPath\sk.Payload"
}

if ( ! [string]::IsNullOrEmpty($BiosPassword) ) {
    $EndorsementPayload.Add("BIOSPassword",$BiosPassword)
}

if ( $nonce -is [uint32] ) {
    $EndorsementPayload.Add("nonce",$nonce)
}


New-HPSecurePlatformSigningKeyProvisioningPayload @SigningPayload

#endregion

## Reviwers note: Note, this process assumes the SK and KEK teams are the same
## Otherwise, Should we break this script up into two parts? One for the SK team, another for the KEK team?
