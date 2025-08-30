<#
.SYNOPSIS
    Create a recovery script for HP Devices
.DESCRIPTION
    Boot to HP Sure Recover Cloud Solution from iPXE
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    https://ftp.hp.com/pub/pcbios/CPR/recovery.mft

#>

[cmdletbinding()]
param(
    [string] $path = "$PSScriptRoot\..\..\ipxeBuilder\Build\Tmp\HPRecovery.ipxe"
)

#region Download Manifest
$HPURL = 'https://ftp.hp.com/pub/pcbios/CPR/recovery.mft'

$HPData = invoke-restmethod -Uri $HPURL 
if ( -not $HPData ) { throw "Failed to download HP Recovery Manifest from $HPURL" }

$hpFiles = $hpdata -split "`r`n" 
if ( $hpfiles[0] -notmatch 'version=[0-9]+, agent_version=[0-9]+' ) { throw "Invalid HP Manifest version line: $($hpfiles[0])" }

$HPManifest = $hpfiles | where-object { $_ -match '^(?<hash>[0-9a-zA-Z]{64}) (?<path>[^ ]+) (?<size>[0-9]+)$' } |
    foreach-object { $Matches }

# Future: Verify Manifest. Assume OK as from HTTPS

#endregion 

#region Build HP Recovery Script

@"
#!ipxe

echo ${cls} Boot machine with HP Recovery WinPE image

iseq `${debug} true && set wimbootargs pause || set wimbootargs quiet
imgfree autoexec.ipxe ||

kernel -n wimboot       `${cwduri}/WinPE/`${buildarch}/wimboot  `${wimbootargs} ||

####################################
"@ | out-file -Encoding ascii -FilePath $path -Force

foreach ( $Item in $HPManifest ) {

    $BaseName = split-path -leaf $Item.Path
    $URL = "https://ftp.hp.com/pub/pcbios/CPR$( $Item.Path -replace '\\','/' )"

@"
set myhash $($Item.Hash)
initrd -n $BaseName $URL || goto hpbootfail
sha256sum $basename ||
sha256sum -s `${myhash} $basename || prompt `${myhash} expected for $basename. Press ctrl-c to exit." || goto hpbootfail

"@| out-file -Encoding ascii -FilePath $path -append

}

@"
####################################

imgstat ||
boot ||
:hpbootfail
prompt HP Recovery WinPE image failed to boot. Take a picture here for support.

"@ | out-file -Encoding ascii -FilePath $path -append

#endregion

