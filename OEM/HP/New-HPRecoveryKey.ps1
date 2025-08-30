#requires -module DeploymentLiveModule

<#
.SYNOPSIS
    Create the RE public/private keys
.DESCRIPTION
    Create the public/private Recovery Imaging Keys for HP Client management.
.NOTES
    Executed only on "Imaging Recovery" Secure Management Server (not on client)
.LINK
    https://developers.hp.com/hp-client-management/blog/hp-secure-platform-management-hp-client-management-script-library
.EXAMPLE
    $credre = Get-Credential -UserName 'admin' -Message 'RE Password'
    .\New-HPRecoveryKey.ps1 -REPass $Credre.Password -Subject "/C=US/ST=AZ/L=Tucson/O=DeploymentLive/OU=Dev/CN=DeploymentLive.com"
#>

[cmdletbinding()]
param(
    [int] $Days = 3650,
    [parameter(mandatory=$false)]
    [string] $Subject = "/C=US/ST=WA/L=Mercer Island/O=DeploymentLive/OU=IT/CN=www.DeploymentLive.com",
    [string] $CertPath = "$PSScriptRoot\..\Certs\",
    [parameter(mandatory=$false)]
    [SecureString] $REPass = $Pass
)

#region Create public and private key

remove-item "$CertPath\RE-key.pem","$CertPath\RE-cert.pem" -ErrorAction SilentlyContinue
$NewRE = @(
    "req","-x509","-nodes","-newkey","rsa:2048"
    "-keyout","$CertPath\RE-key.pem"
    "-out","$CertPath\RE-cert.pem"
    "-passout","env:rePass"
    "-days",$Days
    "-subj",$Subject
)
invoke-openssl -PassOut $REPass -Commands $NewRE | Write-Verbose

if ( ! ( Test-path "$CertPath\RE-key.pem" ) ) { Throw "RE-key.pem is missing." }
if ( ! ( Test-path "$CertPath\RE-cert.pem" ) ) { Throw "RE-cert.pem is missing." }

#endregion
