<#
.SYNOPSIS
    Sign a Certificate Request with the Deployment Live CA
.NOTES
    Requires openssl.exe
    Use any CRT generator on the remote machine
    This command is executed on the CA
.EXAMPLE
    $Vault = Get-SecretVault | Select-Object -first 1 -ExpandProperty Name
    $CAPassword = Get-Secret -vault $Vault -name 'lsamysvygrcli2frln5n53kxey' 
    & .\Complete-CertificateRequest.ps1 -hostname 'dc1.corp.KeithGa.com' -request ".\dc1.corp.keithga.com.req"
#>

[cmdletbinding()]
param(
    # [Parameter(mandatory=$false)]
    #[pscredential] $CAPassword,
    [int] $days = 365,
    [Parameter(mandatory)]
    $request,
    [Parameter(mandatory)]
    [string] $hostname 
)

#region Initialize 
$ScriptRoot = '.'
if (![string]::IsNullOrEmpty($PSscriptRoot)) { 
    $ScriptRoot = $PSScriptRoot -replace "\\","/"
}

import-module DeploymentLiveModule

#endregion

$Target  = $request + ".crt"

Invoke-OpenSSL -commands ( "req", "-in", $Request , "-noout", "-text" ) | Write-Verbose

new-item -ItemType File -Path $ScriptRoot\..\assets\DeploymentLive\ca.idx -ErrorAction SilentlyContinue -Force | Write-Verbose

@"
[ ca ]
default_ca    = CA_default      # The default ca section

[ CA_default ]
default_days     = $($days)   # How long to certify for
default_md       = sha256       # Use public key default MD
email_in_dn     = no            # Don't concat the email in the DN
copy_extensions = copy          # Required to copy SANs from CSR to cert
certificate = $scriptroot/../../ipxebuilder/customers/DeploymentLive/certs/ca.crt
database = $scriptroot/../../ipxebuilder/customers/DeploymentLive/certs/ca.idx
new_certs_dir = $ScriptRoot/../Build/certs
serial = $scriptroot/../../ipxebuilder/customers/DeploymentLive/certs/ca.srl
policy = signing_policy

[ signing_policy ]
countryName            = optional
stateOrProvinceName    = optional
localityName           = optional
organizationName       = optional
organizationalUnitName = optional
commonName             = supplied
emailAddress           = optional

"@ | out-file -Encoding ascii -FilePath $env:temp\config.cnf


remove-item $Target -ErrorAction SilentlyContinue
invoke-openssl -PassIn $CAPassword.password -Commands @(
    "ca" 
    "-config","$env:temp/config.cnf"
    "-in",$request
    "-keyfile","$scriptroot/../../ipxebuilder/customers/DeploymentLive/certs/ca.key"
    "-passin","env:CAPassword"
    "-out",$Target
    "-batch","-verbose"
)

remove-item $env:temp\config.cnf 
# Output for debugging
if ( test-path $Target ) {
    Invoke-OpenSSL -commands ( "x509 -in $Target -text -noout" -split ' ' ) | Write-Verbose
}
