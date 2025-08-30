<#
.SYNOPSIS
    Create a HP Sure Recover Deployment Package
.DESCRIPTION
    Will create a fully functional HP Sure Recover Deployment Package in PowerShell.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

[cmdletbinding()]
param(
    [string] $CertPath = "$PSScriptRoot\..\Certs\",
    [string] $path = "$PSScriptRoot\Deploy-HPSureRecovery.ps1"
)

#region Initialization

$Target = @{
    Encoding = 'ascii'
    filepath = $Path
}

#endregion 

#region Header

@'

#requires -modules hp.firmware

[cmdletbinding()]
param()

'@ | out-file @Target

#endregion 

#region import Payload and verify

$KekData = get-content $CertPath\kek.payload
$SKData  = get-content $CertPath\sk.payload
$REData  = get-content $CertPath\re.payload

if ( convertfrom-json $kekdata | ? purpose -ne 'hp:provision:endorsementkey' ) { throw "Not Endorsement Payload" }
if ( convertfrom-json $skdata | ? purpose -ne 'hp:provision:signingkey' ) { throw "Not Signing payload" }
if ( convertfrom-json $redata | ? purpose -ne 'hp:surerecover:provision:recovery_image' ) { throw "Not recovery payload" }

@"

# signed payload packages to import:

`$KEKData = '$kekdata'
`$SKData = '$SKData'
`$REData = '$REData'

"@ | out-file @Target -append

#endregion 


#region Processing Code

$ErrorActionPreference = 'stop'

@'

$ErrorActionPreference = 'stop'

# Provision the KEK and SK

$State = Get-HPSecurePlatformState
$State | out-string | write-verbose
if ( $State.State -ne "Provisioned" ) { 
    write-verbose "Needs provisoining"

    if ( $State.EndorsementKeyMod | measure -sum | ? Sum -eq 0 ) { 
        write-verbose "Load Endorsement Key"
        Set-HPSecurePlatformPayload -Payload $kekData
    }

    if ( $State.SigningKeyMod | measure -sum | ? Sum -eq 0 ) { 
        write-verbose "Load Signing Key"
        Set-HPSecurePlatformPayload -Payload $SKData
    }

}

# Provision the Recovery State. Always write.

$RecoverState = Get-HPSureRecoverState -all 
$RecoverState | out-string | write-verbose

Set-HPSecurePlatformPayload -Payload $REData

$RecoverState = Get-HPSureRecoverState -all 
$RecoverState | out-string | write-verbose

# Must Reboot?

$State = Get-HPSecurePlatformState
$State | out-string | write-verbose
if ( $state.State -ne "ProvisioningInProgress" ) { 
    write-verbose "Must Reboot"
    # read-host "Press enter to reboot"
    # shutdown -r -f -t 30
    exit 3010
}

'@ | out-file @Target -append

#endregion 

