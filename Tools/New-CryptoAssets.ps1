<#
.SYNOPSIS
    Build all cryptographic assets
.DESCRIPTION
    Used for a clean environment 
.NOTES
    Keys applied here come from Microsoft.PowerShell.SecretManagement.
    Your vault must be installed and configured for use.
#>

[CmdletBinding()]
param ( )

########################################################
########################################################
########################################################
########################################################

THROW "This script is rough, and untested in it's current form."

########################################################
########################################################
########################################################
########################################################


$ErrorActionPreference = 'stop'

# All variables
$DefaultSubject = '/C=US/ST=WA/L=Mercer Island/O=Deployment Live/OU=Dev/CN=DeploymentLive CA'
$CodeSigningSubject = 'DeploymentLive CodeSigning Test'
$Vault = Get-SecretVault | Select-Object -first 1 -ExpandProperty Name
$CAPassword = Get-Secret -vault $Vault -name 'lsamysvygrcli2frln5n53kxey' 

$Years = 10 
$TargetDir = "$PSScriptRoot\Assets\DeploymentLive"

if ( -not ( test-path $TargetDir )) {
    new-item -ItemType Directory -Path $TargetDir -ErrorAction SilentlyContinue | out-null
}

########################################
#region Initialize 
$ScriptRoot = '.'
if (![string]::IsNullOrEmpty($PSscriptRoot)) { 
    $ScriptRoot = $PSScriptRoot -replace "\\","/"
}
import-module $ScriptRoot/library/DLiPXELib.psm1 -force
#endregion


#region Configure the SSL CA

<#

# NOt sure what this is


invoke-openssl -PassOut $CAPassword.password -Commands @(
    "req","-x509","-newkey","rsa:2048"
    "-out","$TargetDir\DeploymentLive.crt"
    "-keyout","$TargetDir\DeploymentLive.key"
    "-days",(365*$Years)
    "-subj",$DefaultSubject
    "-passout", "env:keypass" 
    "-verbose", "-batch"
)

# Output for debugging
Invoke-OpenSSL -commands ( "x509 -in $TargetDir\ca.crt -text" -split ' ' ) | Write-Verbose

# Dell HTTPS will only import files named *.PEM
copy-item $TargetDir\ca.crt $TargetDir\ca.pem

#>

#endregion 

#region configure Self-Signed CA
$CodeSigningParams = @{
    Type = 'CodeSigningCert'
    Subject = $CodeSigningSubject
    KeyAlgorithm = 'RSA'
    HashAlgorithm = 'sha256'
    KeyLength = 2048
    CertStoreLocation = 'Cert:\CurrentUser\My'
    NotAfter = (Get-Date).AddYears($Years)
}

$newCert = New-SelfSignedCertificate @CodeSigningParams
$newCert | Write-verbose

write-verbose "Export SelfSignedCert: $TargetDir\SecureBootTest.crt"
Export-Certificate -cert $newCert -FilePath "$TargetDir\SecureBootTest.crt" -type CERT | Write-Verbose

# Dell machines will only accept a PEM format:
Invoke-OpenSSL -commands ( "x509 -inform der -in $TargetDir\SecureBootTest.crt -outform pem -out $TargetDir\SecureBootTest.pem" -split ' ' ) 
Invoke-OpenSSL -commands ( "x509 -in $TargetDir\SecureBootTest.crt -text" -split ' ' ) | Write-Verbose
Invoke-OpenSSL -commands ( "x509 -in $TargetDir\SecureBootTest.pem -text" -split ' ' ) | Write-Verbose
#endregion
