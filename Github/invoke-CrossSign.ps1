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
    & .\Invoke-CrossSign.ps1 -path sectigo.crt -target Crossusertrust2.crt
    & .\Invoke-CrossSign.ps1 -path usertrust.crt -target Crossusertrust1.crt
    type Crossusertrust1.crt,Crossusertrust2.crt  > Crossusertrust.crt
#>

[cmdletbinding()]
param(
    # [Parameter(mandatory=$false)]
    #[pscredential] $CAPassword,
    [int] $days = 90,
    [Parameter(mandatory)]
    [string] $path,
    [Parameter(mandatory)]
    [string] $target
)

#region Initialize 
$ScriptRoot = '.'
if (![string]::IsNullOrEmpty($PSscriptRoot)) { 
    $ScriptRoot = $PSScriptRoot -replace "\\","/"
}

import-module DeploymentLiveModule

#endregion

new-item -ItemType File -Path $ScriptRoot\..\..\ipxebuilder\customers\DeploymentLive\certs\ca.idx -ErrorAction SilentlyContinue -Force | Write-Verbose

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
new_certs_dir = $scriptroot/../../ipxebuilder/customers/DeploymentLive/certs/
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

[ cross ]
basicConstraints       = critical,CA:true
keyUsage               = critical,cRLSign,keyCertSign

"@ | out-file -Encoding ascii -FilePath $env:temp\config.cnf


# openssl ca -config ca.cnf -extensions cross -notext -preserveDN -ss_cert startcom.crt -out startcom-cross.crt

remove-item $Target -ErrorAction SilentlyContinue
invoke-openssl -PassIn $CAPassword.password -Commands @(
    "ca" 
    "-config","$env:temp/config.cnf"
    "-extensions","cross","-notext","-preserveDN"
    "-ss_cert",$path
    "-keyfile","$scriptroot/../../ipxebuilder/customers/DeploymentLive/certs/ca.key"
    "-passin","env:CAPassword"
    "-out",$Target
    "-batch","-verbose"
)

# remove-item $env:temp\config.cnf 
# Output for debugging
if ( test-path $Target ) {
    Invoke-OpenSSL -commands ( "x509 -in $Target -text -noout" -split ' ' ) | Write-Verbose
}
else { 
    throw "Failed to create $Target" 
}