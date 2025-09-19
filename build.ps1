# //requires -asRunAsAdministrator

<#
.SYNOPSIS
    Build for Deployment Live iPXE Web
.DESCRIPTION
    Complete build process for building Deployment Live iPXE Web components
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
#>

[cmdletbinding()]
param(
    [hashtable[]] $VirtualRegressionTests,
    [String] $REVaultID,
    [hashtable[]] $TargetMachines,
    [hashtable] $WinPESrc,
    [hashtable[]] $ExtraFiles,
    [hashtable[]] $HPSureRecoverTargets,
    [hashtable[]] $iPXEFiles,
    [hashtable[]] $BootFiles,
    [hashtable[]] $ISOImages
)

if ( $PSBoundParameters.count -eq 0 ) { throw "Missing Args" }

#region Support Routines 

function test-UserHasHyperVRole { 
    return ( [Security.Principal.WindowsIdentity]::GetCurrent().Groups -Contains 'S-1-5-32-544' ) -or  # Administrators Group
           ( [Security.Principal.WindowsIdentity]::GetCurrent().Groups -Contains 'S-1-5-32-578' )      # Hyper-V Admin Group
}

function new-AutoexecIPXE { 
    [cmdletbinding()]
    param( $Path, $Target )

    $Data = "#!ipxe`r`nset force_filename " + $Target + "`r`n"

    if ( $Path ) {
        if ( -not ( test-path ( Split-path $Path ))) {
            new-item -ItemType Directory (Split-path $path ) -Force | write-verbose
        }
        $Data | out-file -Encoding ascii -FilePath $Path -Force
    }
    else {
        $Data | Out-Default
    }

}

function Copy-IfNewer {
    # Copies only flat file structure   
    # Copy-IfNewer 'C:\Temp1\*' -dest 'C:\Temp2\' 
    [cmdletbinding()]
    param(  [Parameter(Mandatory,Position=0)] $Path, [Parameter(Mandatory,Position=1)] $Destination )

    Get-ChildItem -Path $Path -File  | ForEach-Object {
        # test if there already is a file with that name in the destination folder
        $existingFile = Get-Item -Path (Join-Path $Destination $_.Name) -ErrorAction SilentlyContinue
        # if not existing or the existing file is older than the one in the source folder, do the copy
        if (!$existingFile -or $existingFile.LastWriteTime -lt $_.LastWriteTime) {
            # if ( -not ( test-path $destination ) ) { new-item -ItemType Directory -Path $Destination -force | out-null } 
            $_ | Copy-Item -Destination $Destination -Force -PassThru | write-verbose
        }
    }

}

#endregion

#region Check for Dependencies

if ( -not ( get-module DeploymentLiveModule -ListAvailable -ErrorAction SilentlyContinue  )) {
    throw "DeploymentLiveModule not found. Please clone from github.com/deploymentlive/DeploymentLiveModule"
}

if ( -not ( get-module DeploymentLiveModule -ErrorAction SilentlyContinue ) ) {
    import-module DeploymentLiveModule -ErrorAction stop
}

if ( -not ( test-path "$PSScriptRoot\..\iPXEPreProcessor\Invoke-IPXEPreProcessor.ps1" ) ) {
    throw "iPXEPreProcessor files not found. Please clone from github.com/deploymentlive/DeploymentLiveModule"
}
$iPXEPreCompiler = "$PSSCriptROot\..\iPXEPreProcessor\Invoke-IPXEPreProcessor.ps1"

if ( test-path "$PSScriptRoot\Block\Bin\*.dll" ) {
    Write-verbose "Block DLLs found"
} elseif ( -not ( test-path "$PSScriptROot\..\DiscUtils\DiscUtils.sln") ) {
    throw "DiscUtils Library files not installed. Please clone from github.com/deploymentlive/DiscUtils"
}

#endregion

#region Initialize Environment

$ScriptRoot = '.'
if (![string]::IsNullOrEmpty($PSscriptRoot)) { 
    $ScriptRoot = $PSScriptRoot
}

while ( $true ) { try { stop-transcript } catch { break } }
Start-Transcript -OutputDirectory "$ScriptRoot\Build"

if ( -not ( test-path "$PSScriptRoot\Block\Bin\*.dll" ) ) {
    write-verbose "Build binaries"
    & "$PSSCriptRoot\block\build-ipxetools.ps1"
}

$TargetDir = "$ScriptRoot\Build"

foreach ( $Dir in @( "$TargetDir\Boot","$TargetDir\HP","$TargetDir\block","$TargetDir\boot\dhcpproxy","$TargetDir\boot\winpe" ) ) {
    new-item -ItemType Directory $Dir -ErrorAction SilentlyContinue -Force | Write-Verbose
}

('*' * 80) | write-verbose

#endregion 

#region Initial Pre-Cleanup

write-verbose "Verify Hyper-V does not have any ISO images open."

$BadDVD = get-vm | where-object State -ne 'off' | Get-VMDvdDrive | ? { $_.Path.StartsWith( $TargetDir ) } 
if ( $BadDVD ) {

    $BadDVD | out-string | Write-Verbose
    write-warning "Some Virtual Machines are still running, and possibly mounted with current Build. Turn off first."

    if ( test-UserHasHyperVRole  ) {
        $BadDVD.VMName | Stop-VM
    }
    else {
        write-warning "Not running as an Administrator, please stop vm $($Control.HyperVTest) manually."
    }

}

#endregion

################################################################

#region Build HP Boot files

foreach ( $HPTarget in $HPSureRecoverTargets ) {

    if ( $HPTarget.name -match '(aa64|arm64)' ){
        write-verbose "Skip ARM64 for now on HP devices"
        continue
    }

    if ( test-path "$TargetDir\HP\$($HPTarget.Name)\Autoexec.ipxe" ) {
        write-verbose "Found Target: $TargetDir\HP\$($HPTarget.Name)\autoexec.ipxe.   SKIP!"
        continue
    }

    ###############

    if ( $REPassword -isnot [SecureString] ) {

        #region Get Domain Join Password
        write-warning "Need HP Recovery Package Password..."
        if ( $REPassword -isnot [pscredential] ) {
            if ( $global:REPassword -isnot [pscredential] ) {
                $Vault = Get-SecretVault | Select-Object -first 1 -ExpandProperty Name
                $global:REPassword = Get-Secret -vault $Vault -name $REVaultID | % password
            }
            $REPassword
        }

        #endregion
    }

    ###############
    new-AutoexecIPXE -Path "$TargetDir\HP\$($HPTarget.Name)\autoexec.ipxe" -Target $HPTarget.Target

    new-item -ItemType Directory -path "$TargetDir\HP\$($HPTarget.Name)\EFI\BOOT" -ErrorAction SilentlyContinue -force | Write-Verbose
    Copy-IfNewer $HPTarget.Binary -Destination "$TargetDir\HP\$($HPTarget.Name)\EFI\BOOT\bootx64.efi"

    remove-item "$TargetDir\HP\$($HPTarget.Name)\recovery.mft","$TargetDir\HP\$($HPTarget.Name)\recovery.sig" -ErrorAction SilentlyContinue
    & $ScriptRoot\OEM\HP\New-HPRecoveryManifest.ps1 -certPath "$ScriptRoot\certs" -rePass $REPassword -Version $HPTarget.Version -FilePath "$TargetDir\HP\$($HPTarget.Name)"

    if ( -not ( test-path "$TargetDir\HP\$($HPTarget.Name)\recovery.mft" )) { throw "Missing $TargetDir\HP\$($HPTarget.Name)\recovery.mft" }
    if ( -not ( test-path "$TargetDir\HP\$($HPTarget.Name)\recovery.sig" )) { throw "Missing $TargetDir\HP\$($HPTarget.Name)\recovery.sig" }
}

#endregion

#region Build HP Recovery iPXE MEnu

if ( -not ( test-path "$TargetDir\recovery.mft" ) ) {
    Invoke-WebRequest 'https://ftp.hp.com/pub/pcbios/CPR/recovery.mft' -OutFile "$TargetDir\recovery.mft"
}

#endregion

#region Build WinPE images

if ( ( -not ( test-path $WinPESrc.arm64 ) ) -or ( -not ( test-path $WinPESrc.amd64 ) ) ) {
    throw "Full WinPE Build"
    import-module osd.workspace -force
    #Build-OSDWorkspaceWinPE -name "MyBootMedia" -Architecture amd64
    #Build-OSDWorkspaceWinPE -Name "MyBootMedia" -Architecture arm64
}

new-item -itemtype Directory -path "$TargetDir\WinPE.arm64","$TargetDir\WinPE.amd64" -force | write-verbose
copy-ifnewer $WinPESrc.arm64 -Destination "$TargetDir\WinPE.arm64\boot.wim"
copy-ifnewer $WinPESrc.amd64 -Destination "$TargetDir\WinPE.amd64\boot.wim"

write-verbose "Copy to Azure if necessary"
& "$ScriptRoot\tools\Upload-Blob.ps1" "$TargetDir\WinPE.amd64\boot.wim","$TargetDir\WinPE.arm64\boot.wim"

#endregion

#region Gather WinPE Collateral

write-verbose "download wimboot"
new-item -ItemType Directory -path "$TargetDir\boot\WinPE\x86_64","$TargetDir\boot\WinPE\arm64" -force | Write-Verbose
if ( -not ( test-path "$TargetDir\boot\winpe\x86_64\wimboot" ) ) {
    Invoke-WebRequest -uri "https://github.com/ipxe/wimboot/releases/download/v2.8.0/wimboot" -OutFile "$TargetDir\boot\WinPE\x86_64\wimboot" 
}

if ( -not ( test-path "$TargetDir\boot\winpe\arm64\wimboot" ) ) {
    Invoke-WebRequest -uri "https://github.com/ipxe/wimboot/releases/download/v2.8.0/wimboot.arm64" -OutFile "$TargetDir\boot\WinPE\arm64\wimboot" 
}


#endregion

#region Build DHCP Proxy

if ( -not ( test-path \\wsl.localhost\ubuntu\tmp\tclbuild\tinycore.gz ) ) {
    write-verbose "Full TCL PRoxy Server rebuild"
    & "$ScriptRoot\dhcpproxy\build-TCLProxyServer.ps1"
}

write-verbose "Copy TCL Proxy Files"
Copy-IfNewer \\wsl.localhost\ubuntu\tmp\tclbuild\vmlinuz64 $TargetDir\boot\dhcpproxy\vmlinuz64
Copy-IfNewer \\wsl.localhost\ubuntu\tmp\tclbuild\tinycore.gz $TargetDir\boot\dhcpproxy\tinycore.gz

#endregion

#region Build ipxe files

foreach ( $ipxeFile in $iPXEFiles ) {

    if ( Compare-FilesIfNewer @ipxeFiles ) {
        write-verbose "    COMPILE: $($iPXEFile.path)"
        & $iPXEPreCompiler -path $iPXEFile.Path -include "$ScriptRoot\..\ipxeBuilder\customers\_common" | out-file -Encoding ascii $iPXEFile.Destination 
        
    }

}

#endregion

#region Build ISO Images 

foreach ( $ISOImage in $ISOImages ) {

    $ISOImage | write-verbose 
    $TargetISO = "$TargetDir\Block\$($ISOImage.Name).iso"
    if ( -not ( test-path $TargetISO )) {
        write-verbose "Build ISO $TargetISO"

        remove-item $TargetISO -ErrorAction SilentlyContinue
        & $ScriptRoot\block\new-iso.ps1 -Path $TargetISO -files $ISOImage.files 
        remove-item "$($TargetISO).vfd" -ErrorAction SilentlyContinue
        if ( -not ( test-path $TargetISO ) ) { throw "genfsimg returned error, Did you leave a VM running?" }
        icacls.exe $TargetISO /grant "NT VIRTUAL MACHINE\Virtual Machines:(R)" # Required for Hyper-V testing
    }
}

#endregion

#region Copy other misc files


foreach ( $WinPEFile in $ExtraFiles ) {
    Copy-IfNewer @WinPEFile
}


#endregion


################################################################

#region Copy Builds to Targets

foreach ( $Machine in $TargetMachines ) {

    $Machine | out-string | write-verbose
    <#
    if ( $Machine.TargetFolder.StartsWith('\\') ) {
        if ( -not ( Test-NetConnection ( $machine.TargetFolder.Split('\')[2] ) -Port 445 -InformationLevel Quiet  )) {
            write-warning "Unable to connect to $($Machine.TargetFolder)"
            continue
        }
    }
        #>

    foreach ( $dir in @('boot','Block','HP') ) {
        robocopy /mir /np /ndl /xx /ipg:1 "$TargetDir\$Dir" "$($Machine.TargetFolder)\$Dir" /xf *Paid* /xd *PAID* | write-verbose
    }
}

#endregion

#region Regression Testing

foreach ( $VM in $VirtualRegressionTests ) {
    if (test-UserHasHyperVRole) {
        $vm | Write-Verbose
        write-verbose "Launch Virtual Machine"
        Start-VM @VM | Write-verbose
    }
}

#endregion

#region Close out environment

write-verbose "DONE"
Stop-Transcript -ErrorAction SilentlyContinue

#endregion
