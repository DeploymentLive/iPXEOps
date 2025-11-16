<#
.SYNOPSIS
    Create an ISO image
.DESCRIPTION
    Create an ISO image for local Hyper-V testing of iPXE
.NOTES
    Although there are tools within the Microsoft ADK to create ISO images, Microsoft does not include tools to create Virtual Floppy disks.
    the DiscUtils repo does have a .net library that can create both Virtual Floppies and ISO images.
#>

[cmdletbinding()]
param(
    [switch] $force = $true,
    [parameter(mandatory)]
    $path,
    [parameter(mandatory)]
    $files = @(
        @{ path = "$PSSCriptRoot\Build\Signed\snp_drv_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
        @{ text = "#!ipxe`r`nset force_filename https://aws.deploymentlive.com/boot/cloudboot.ipxe`r`n";  destination = 'autoexec.ipxe' }
    )
)

#region Import DiscUtils Library

add-type -Path "$PSScriptRoot\bin\DiscUtils.Streams.dll"
add-type -Path "$PSScriptRoot\bin\DiscUtils.Core.dll"
add-type -Path "$PSScriptRoot\bin\DiscUtils.Iso9660.dll"

#endregion

#region Open ISO Image

$CDBuilder = [DiscUtils.Iso9660.CDBuilder]::new()
$CDBuilder.VolumeIdentifier = 'iPXE'
# $CDBuilder.UseJoliet = $true
$CDBuilder.UpdateIsolinuxBootTable = $false

#endregion

#region Build and Add VFD

& "$PSScriptRoot\new-VFD.ps1" -force:$Force -path "$($Path).vfd" -files $files

$ReadStream = [system.io.file]::OpenRead("$($Path).vfd")
$CDBuilder.SetBootImage($ReadStream, [DiscUtils.Iso9660.BootDeviceEmulation]::Diskette1440KiB,512) | write-verbose

#endregion

#region Add Files

foreach ( $file in $files ) {
    write-verbose "Add File: $($File.destination)"
    $filepath = split-path $File.destination
    if ( -not [string]::isnullorempty($filepath) ) {
        write-verbose "Create path: $FIlePath"
        $CDBuilder.AddDirectory( $filepath ) | write-verbose
    }

    if ( $File.containskey('path') ) {
        write-verbose "Copy file $($File.Path) to $($File.destination)"
        $CDBuilder.AddFile($File.destination,$file.Path) | out-string | write-verbose
    }
    elseif ( $File.containskey('text') ) {
        write-verbose "Copy text $($File.text) to $($File.destination)"
        $CDBuilder.AddFile($File.destination, [Text.Encoding]::ASCII.GetBytes($file.text) ) | out-string | Write-verbose
    }
}

#endregion 

#region Build

write-verbose "Close out ISO image"
$CDBuilder.Build($Path)
$ReadStream.Close()

#endregion