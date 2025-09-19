<#
.SYNOPSIS
    Create a Virtual Floppy Disk
.DESCRIPTION
    Create a Virtual Floppy Disk for Hyper-V testing scenarios.
.NOTES
    Although there are tools within the Microsoft ADK to create ISO images, Microsoft does not include tools to create Virtual Floppy disks.
    the DiscUtils repo does have a .net library that can create both Virtual Floppies and ISO images.

    Files argument can be either a filesource or text.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

[cmdletbinding()]
param(
    [switch] $force = $true,
    [parameter(mandatory=$true)]
    $path,
    $files = @(
        @{ path = "$PSSCriptRoot\Build\Signed\snp_drv_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
        @{ text = "#!ipxe`r`nset force_filename https://boot.deploymentlive.com:8050/boot/cloudboot.ipxe`r`n";  destination = 'autoexec.ipxe' }
    )
)

#region Import DiscUtils Library

add-type -Path "$PSScriptRoot\bin\DiscUtils.Streams.dll"
add-type -Path "$PSScriptRoot\bin\DiscUtils.Core.dll"
add-type -Path "$PSScriptRoot\bin\DiscUtils.Fat.dll"

#endregion

#region Create new Floppy disk

if ( test-path $path )  {
    if ( -not ($force.IsPresent) ) {
        throw "Found floppy disk [$path]. Must remove first, or use -Force flag."
    }
    remove-item -force $path -ErrorAction stop | out-null
}

$fs = [System.IO.FileStream]::new( $path , [System.IO.FileMode]::CreateNew )
$Floppy = [DiscUtils.Fat.FatFileSystem]::FormatFloppy($fs, [DiscUtils.FloppyDiskType]::HighDensity , "iPXE" )

#endregion

#region build files in floppy

foreach ( $file in $files ) {

    $filepath = split-path $File.destination
    if ( -not [string]::isnullorempty($filepath) ) {
        write-verbose "Create path: $FIlePath"
        $Floppy.CreateDirectory( $filepath )
    }

    $newFile = $floppy.OpenFile( $File.destination , [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write );

    if ( $File.containskey('path') ) {
        write-verbose "Copy file $($File.Path) to $($File.destination)"
        $ReadStream = [system.io.file]::OpenRead($File.Path)
    }
    elseif ( $File.containskey('text') ) {
        write-verbose "Copy text $($File.text) to $($File.destination)"
        $ReadStream = [System.IO.MemoryStream]::new( [System.Text.Encoding]::ASCII.GetBytes( $File.text ) )
    }

    $ReadStream.CopyTo( $NewFile )
    $ReadStream.Close()
    $newFile.Close()

}


#endregion 

#region Close

$fs.close();

$floppy.Root.GetFiles() | out-string| Write-verbose
if ( $floppy.Root.GetFiles()[0].fullname -ne 'autoexec.ipxe' ) { throw "did not write autoexec.ipxe correctly"}

#endregion
