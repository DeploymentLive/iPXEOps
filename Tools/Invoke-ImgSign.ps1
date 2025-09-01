<#
.SYNOPSIS
    Sign files for use within iPXE
.DESCRIPTION
    ImgVerify and ImgTrust
.NOTES
    Unfortunately, imgverify and imgtrust have been identified as vulnerabilities in iPXE by MSFT. 
    I disagree with this assessment, but to avoid issues, these functions have been 
    removed from the Deployment Live versions of iPXE. This script is for reference only.
#>

[cmdletbinding()]
Param(
    [string] $SignFilesList,
    [securestring] $CSPassword,

    [string] $CSCert,  # $CertPath\CodeSign.crt
    [string] $CSKey,   # $CertPath\CodeSign.key
    [string] $CACert   # $CertPath\ca.crt
)

foreach ( $path in get-item $SignFilesList -exclude *.sig,winpe.wim ) {
    if ( Compare-FilesIfNewer -Path $Path -dest "$($Path).sig" ) {
        write-verbose "SIGN: $Path"

        remove-item "$($Path).sig" -ErrorAction SilentlyContinue
        invoke-openssl -PassIn $CSPassword -Commands @(
            "cms","-sign","-binary","-noattr"
            "-in",$Path
            "-signer",$CSCert
            "-certfile",$CACert
            "-inkey",$CSKey
            "-passin","env:CAPassword"
            "-outform","DER"
            "-out","$($Path).sig"
        )
    
        if ( -not ( test-path "$($Path).sig" )) { throw "Did not sign $($Path).sig" }
    
        <#
            # Can't get this command to verify binary files. 
            $result = invoke-openssl -Commands @(
                "cms","-verify","-noverify","-binary"
                "-in","$($Path).sig"
                "-inform","der"
                "-content",$Path
            ) -verbose:$false

            if (!$result) { throw "Did not sign $Path"}
        #>
    }
}