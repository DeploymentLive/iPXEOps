<#
.SYNOPSIS
    Install Cert and key into HTTPS Server
.NOTES
    Requires openssl.exe
    Use any CRT generator on the remote machine
.EXAMPLE
    & New-KeyAndCSR.ps1
#>

[cmdletbinding()]
param(
    #[Parameter(mandatory)]
    [securestring] $PassIn,
    #[Parameter(mandatory)]
    [string] $hostname = 'dc1.corp.keithga.com'
)

#region Initialize 
$ScriptRoot = '.'
if (![string]::IsNullOrEmpty($PSscriptRoot)) { 
    $ScriptRoot = $PSScriptRoot -replace "\\","/"
}
import-module DeploymentLiveModule

#endregion

#region Build Pfx

remove-item "$ScriptRoot/../Build/Certs/$($HostName).pfx" -ErrorAction SilentlyContinue 
invoke-openssl -PassIn $PassIn -PassOut $PassIn -Commands @(
    "pkcs12","-certpbe","PBE-SHA1-3DES","-keypbe","PBE-SHA1-3DES","-nomac","-export"
    "-out","$ScriptRoot/../Build/certs/$($HostName).pfx"
    "-in","$ScriptRoot/../Build/certs/$($HostName).crt"
    "-inkey","$ScriptRoot/../Build/certs/$($HostName).key"
    "-passin","env:KeyPassIn"
    "-passout","env:KeyPassOut"
)

if ( -not ( test-path "$ScriptRoot/../Build/Certs/$($HostName).pfx" ) ) { throw "missing $($HostName).pfx" }

#endregion

#region Import into Cert Store

# $result = Import-PfxCertificate -password $PassIn -CertStoreLocation Cert:\LocalMachine\My -FilePath "$ScriptRoot/../Build/Certs/$($HostName).pfx"
# $result | fl * | out-string | write-verbose

#endregion 


