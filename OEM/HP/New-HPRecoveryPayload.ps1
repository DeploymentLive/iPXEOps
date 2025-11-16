#requires -modules hp.firmware

<#
.SYNOPSIS
    Create the RE payload file
.DESCRIPTION
    Create the Recovery Imaging Payload file for HP Client management.
.NOTES
    Executed only on "Signing Key" Secure Management Server (not on client)
.LINK
    https://developers.hp.com/hp-client-management/blog/hp-secure-platform-management-hp-client-management-script-library
.EXAMPLE
        $credsk = Get-Credential -UserName 'admin' -Message 'RE Password'
        .\New-HPRecoveryPayload.ps1 -SKPass $Credsk.Password -url 'http://MyServer.org/boot/hp'
#>

[cmdletbinding()]
param(
    [string] $CertPath = "$PSScriptRoot\..\Certs\",
    [parameter(mandatory=$false)]
    [SecureString] $SKPass = $Pass,
    [parameter(mandatory=$false)]
    [string] $url = 'https://web.deploymentlive.com/hp',
    [hashtable] $OptionalArgs = ( @{ version = 1 } )
)

#region Create Recovery Image Payload

$RecoveryPayload = @{
    image = 'agent'
    url = $url
    SigningKeyFile = "$CertPath\sk.pfx"
    SigningKeyPassword = [System.Net.NetworkCredential]::new("", $SKPass).Password
    ImageCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 "$CertPath\RE-cert.pem"  # Sigh...
    OutputFile = "$CertPath\re.Payload"
}

# Used for: [[-Nonce] <UInt32>] [[-Version] <UInt16>] [[-Username] <String>] [[-Password] <String>]
foreach ( $key in $OptionalArgs.keys ) {
    Write-verbose "      Add: $Key = $($OptionalArgs.Item($Key))"
    $RecoveryPayload.Add($key,$OptionalArgs.Item($Key))
}

write-verbose "Create Recover Image Payload"
$RecoveryPayload | select-object -ExcludeProperty SigningKeyPassword | out-string | write-verbose
New-HPSureRecoverImageConfigurationPayload @RecoveryPayload | write-verbose

#endregion
