#requires -module DeploymentLiveModule

<#
.SYNOPSIS
    Create the RE Manifest and Signature
.DESCRIPTION
    Create a RE Manifest and Signature for HP Sure Recover.
.NOTES
    Executed only on "Imaging Recovery" Secure Management Server (not on client)

    Filepath can contain:
        autoexec.ipxe, efi\boot\bootx64.efi
    or
        boot\boot.sdi, efi\boot\bootx64.efi, efi\microsoft\boot\bcd, sources\boot.wim

.LINK
    https://developers.hp.com/hp-client-management/blog/hp-secure-platform-management-hp-client-management-script-library
.EXAMPLE
    $credre = Get-Credential -UserName 'admin' -Message 'RE Password'
    .\New-HPRecoveryManifest.ps1 -REPass $CredRE.Password -FilePath 'd:\build\1002\HP\x64\'
#>

[cmdletbinding()]
param(
    [string] $CertPath = "$PSScriptRoot\..\Certs\",
    [parameter(mandatory=$true)]
    [SecureString] $REPass = $Pass,
    [uint32] $Version = 1,
    [parameter(mandatory=$true)]
    [string] $FilePath = 'C:\Users\keith\source\repos\Build\HP'
)


#region Create Manifest

$ManifestFile = @{
    Encoding = 'ascii'
    FilePath = "$FilePath\recovery.mft"
}

"mft_version=1, image_version=$Version" | out-file @ManifestFile -Force 

$resolvePath = Resolve-Path $FilePath | % path

foreach ( $File in get-childitem $FilePath -file -recurse -Exclude "recovery.mft","recovery.sig" ) {
    write-verbose "Manifest File: $file"
    @(
        (get-filehash -Algorithm SHA256 -Path $file).Hash
        ($File -replace [regex]::Escape($resolvePath),'').trim('\')
        (get-item $file).length
    ) -join ' ' | out-file @ManifestFile -append
}

get-content -raw "$FilePath\recovery.mft" | write-verbose

# copy '\\gibbon9\g$\public\_old\hp\recovery.mft' "$FilePath\recovery.mft"

#endregion

#region Create Signature

remove-item "$FilePath\recovery.sig" -ErrorAction SilentlyContinue

$RESign = @(
    "dgst","-sha256"
    "-sign","$CertPath\re-key.pem"
    "-passin","env:REPass"
    "-out","$FilePath\recovery.sig"
    "$FilePath\recovery.mft"
)

invoke-openssl -commands $RESign -PassIn $REPass

if  ( -not (test-path "$FilePath\Recovery.sig") ) { throw "Did not create $filePath\recovery.Sig" }

#endregion

#region Verify Signature

# Extract RAW public key

$REExtract = @(
    "x509","-pubkey",
    "-in","$CertPath\re-cert.pem"
    "-out","$CertPath\re-pubkey.pem"
)
invoke-openssl -commands $REExtract


$REVerify = @(
    "dgst"
    "-verify","$CertPath\re-pubkey.pem"
    "-signature","$FilePath\recovery.sig"
    "$FilePath\recovery.mft"
)

invoke-openssl -commands $REVerify

#endregion 
