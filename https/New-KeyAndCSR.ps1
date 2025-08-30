<#
.SYNOPSIS
    Create a new Key and CSR for a HTTPS Server.
.NOTES
    Requires openssl.exe
    Use any CRT generator on the remote machine
.EXAMPLE
    $Vault = Get-SecretVault | Select-Object -first 1 -ExpandProperty Name
    $AZPassword = Get-Secret -vault $Vault -name 'ibji37u2q2smxhviy24twf4fia' 
    .\New-KeyAndCSR.ps1 -hostname 'dc1.corp.keithga.com' -PassOut $AZPassword -SAN "subjectAltName=DNS.1:*.deploymentlive.com,DNS.2:*.keithga.com"
#>

[cmdletbinding()]
param(
    [Parameter(mandatory)]
    [securestring] $PassOut,
    [Parameter(mandatory)]    
    [string] $SAN,
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

#region Create Key

new-item -ItemType Directory -Path $ScriptRoot/../Build/Certs -ErrorAction SilentlyContinue | write-verbose

remove-item "$ScriptRoot/../Build/Certs/$($HostName).key","$ScriptRoot/../Build/Certs/$($HostName).req" -ErrorAction SilentlyContinue 
invoke-openssl -PassOut $PassOut -Commands @(
    "req","-newkey","rsa:2048"
    "-keyout","$ScriptRoot/../Build/Certs/$($HostName).key"
    "-out","$ScriptRoot/../Build/Certs/$($HostName).req"
    "-subj","/CN=$HostName"
    "-passout","env:KeyPass"
#     "-config","$env:temp/config.cnf"
    "-addext",$San
    "-batch","-verbose"
)

if ( -not ( test-path "$ScriptRoot/../Build/Certs/$($HostName).key","$ScriptRoot/../Build/Certs/$($HostName).req") ) { Throw "target files not found" }

Invoke-OpenSSL -commands ( "req", "-in", "$ScriptRoot/../Build/Certs/$($HostName).req" , "-noout", "-text" ) | Write-Verbose

#endregion 
