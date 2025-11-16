<#

Regression Testing for Deployment Live Web Services 


#>

[cmdletbinding()]
param(
    [switch]$SpeedTest = $false
)

#region Common FUnctions

function MyWebDownload {
    [cmdletbinding()]
    param(
        $URI,
        $Certificate,
        $Method
    )

   try {
      $result = iwr @PSBoundParameters -Verbose:$false
      [PSCustomObject] @{ Status = $result.StatusCode; LastModified = $result.Headers.'Last-Modified'; Length = $result.Headers.'Content-Length'; Name = $file.key } | write-verbose
   }
   catch { 
      $errNumber = $_.exception | select-string -Pattern '[0-9]{3}' | % { $_.matches.value }
      [PSCustomObject] @{ Status =  $errNumber ; LastModified = $null; Length = 0 ; Name = $file.key } | out-string | write-host
    }

}

#endregion 

#region Initialization

$sourceroot = '.'
if ( $PSScriptRoot -ne $Null ) { $sourceroot = $PSScriptRoot } 

$CertPath = resolve-path "$sourceroot\..\iPXEBuilder\customers\DeploymentLive\Certs\ca.crt"
if ( -not (test-path $certPath ) ) { throw "Missing Cert" }
$Target = resolve-path "$sourceroot\..\DeploymentLiveWeb\www"

#endregion

#region Get Manifest

$Manifest = dir $Target -recurse -file -Exclude 'web.config'

foreach ( $file in $Manifest ) { 
    $key = $file.FullName.Replace($Target,'').trim('\').Replace('\','/')
    Add-Member -InputObject $file -MemberType NoteProperty -Name key -Value $key
}

#endregion 

#region Import Certificate 

$Cert = [System.Security.Cryptography.X509Certificates.X509Certificate]::new($CertPath)

#endregion 


#region Speed test

if ( $SpeedTest.IsPresent ) {

    curl.exe https://web.deploymentlive.com/boot/winpe/x86_64/boot.wim -o $env:temp\temp.wim 
    curl.exe https://lab.deploymentlive.com/boot/winpe/x86_64/boot.wim -o $env:temp\temp.wim 
    curl.exe https://aws.deploymentlive.com/boot/winpe/x86_64/boot.wim -o $env:temp\temp.wim  --cacert $CertPath --ssl-no-revoke
    curl.exe https://lab.deploymentlive.com:8050/boot/winpe/x86_64/boot.wim -o $env:temp\temp.wim --cacert $CertPath --ssl-no-revoke

}

#endregion


#region Manifest Test web.deploymentlive.com

$Root = 'web.deploymentlive.com'

write-host "Download from $Root"
foreach ( $file in $Manifest ) { 
    MyWebDownload -method head "https://$Root/$($file.key)"
}

#endregion

#region Manifest Test aws.deploymentlive.com

$Root = 'aws.deploymentlive.com'
write-host "Download from $Root"
foreach ( $file in $Manifest ) { 

   MyWebDownload -method head "https://$Root/$($file.key)" -Certificate $Cert 

}

#endregion

#region Manifest Test lab.deploymentlive.com

$Root = 'lab.deploymentlive.com'
write-host "Download from $Root"
foreach ( $file in $Manifest ) { 

    MyWebDownload -method head "https://$Root/$($file.key)" 

}

#endregion

#region Manifest Test lab.deploymentlive.com:8050 

$Root = 'lab.deploymentlive.com:8050'
write-host "Download from $Root"
foreach ( $file in $Manifest ) { 

    MyWebDownload -method head "https://$Root/$($file.key)"  -Certificate $Cert 

}

#endregion

#region Manifest Test www.deploymentlive.com

$Root = 'lab.deploymentlive.com'
write-host "Download from $Root"
foreach ( $file in $Manifest ) { 

    MyWebDownload -method head "https://$Root/$($file.key)"

}

#endregion
