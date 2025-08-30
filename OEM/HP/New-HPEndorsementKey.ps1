#requires -modules DeploymentLiveModule
#requires -modules hp.firmware

<#
.SYNOPSIS
    Create the KEK public/private keys
.DESCRIPTION
    Create the public/private Endorsement keys for HP Client management.
.NOTES
    Executed only on "KEK Signing" Secure Management Server (not on client)
.LINK
    https://developers.hp.com/hp-client-management/blog/hp-secure-platform-management-hp-client-management-script-library
.EXAMPLE
    $cred = Get-Credential -UserName 'admin' -Message 'KEK Password'
    .\New-HPEndorsementKey.ps1 -KEKPass $Cred.Password -Subject "/C=US/ST=AZ/L=Tucson/O=DeploymentLive/OU=Dev/CN=DeploymentLive.com"
#>

[cmdletbinding()]
param(
    [int] $Days = 3650,
    [parameter(mandatory=$False)]
    [string] $Subject = "/C=US/ST=WA/L=Mercer Island/O=DeploymentLive/OU=IT/CN=www.DeploymentLive.com",
    [string] $Name = "HP Secure Platform Key Endorsement Certificate",
    [string] $CertPath = "$PSScriptRoot\..\Certs\",
    [parameter(mandatory=$false)]
    [SecureString] $KEKPass = $Pass,
    [string] $BiosPassword
)

import-module DeploymentLiveModule -force

if ( Test-path "$CertPath\kek.pfx" ) { Throw "KEK.pfx is already present." }

#region Create public and private key

remove-item "$CertPath\kek-key.pem","$CertPath\kek-cert.pem" -ErrorAction SilentlyContinue
$NewKEK = @(
    "req","-x509","-nodes","-newkey","rsa:2048"
    "-keyout","$CertPath\kek-key.pem"
    "-out","$CertPath\kek-cert.pem"
    "-passout","env:kekPass"
    "-days",$Days
    "-subj",$Subject
)

Invoke-OpenSSL -passout $KekPass -commands $NewKEK | Write-verbose

if ( ! ( Test-path "$CertPath\kek-key.pem" ) ) { Throw "kek-key.pem is missing." }
if ( ! ( Test-path "$CertPath\kek-cert.pem" ) ) { Throw "kek-cert.pem is missing." }

#endregion

#region Create PFX

$NewKEKpfx = @(
    "pkcs12"
    "-inkey","$CertPath\kek-key.pem"
    "-in","$CertPath\kek-cert.pem"
    "-export","-keypbe","PBE-SHA1-3DES","-certpbe","PBE-SHA1-3DES"
    "-out","$CertPath\kek.pfx"
    "-name",$Name
    "-passin","env:kek1Pass"
    "-passout","env:kekPass"
)

Invoke-OpenSSL -commands $NewKEKpfx -PassOut $KEKPass -PassIn $KEKPass | Write-verbose

if ( ! ( Test-path "$CertPath\kek.pfx" ) ) { Throw "KEK.pfx is missing." }

#endregion

#region Create KEK Payload

$EndorsementPayload = @{
    EndorsementKeyFile = "$CertPath\kek.pfx"
    EndorsementKeyPassword = [System.Net.NetworkCredential]::new("", $KEKPass).Password
    OutputFile = "$CertPath\kek.Payload"
}

if ( ! [string]::IsNullOrEmpty($BiosPassword) ) {
    $EndorsementPayload.Add("BIOSPassword",$BiosPassword)
}

New-HPSecurePlatformEndorsementKeyProvisioningPayload @EndorsementPayload

#endregion
