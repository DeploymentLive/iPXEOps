<#
.SYNOPSIS
    Build discutils library to create ISO and USB images.
.DESCRIPTION
    build discutils library and copy bits to this folder.

    Must have DiscUtils cloned on the local machine preferably parallel to this repro.
.NOTES
    iPXE has a unix tool to create ISO images and USB images that boot directly into iPXE.
    To create ISO images that support booting within Hyper-V. This also includes putting the iPXE binaries within a Virtual Floppy disk.

    Yes a Floppy disk.

    Although there are tools within the Microsoft ADK to create ISO images, Microsoft does not include tools to create Virtual Floppy disks.
    the DiscUtils repo does have a .net library that can create both Virtual Floppies and ISO images.

    However there is a bug in discutils where it only supports filenames in the old 8.3 format, and iPXE tries to read the autoexec.ipxe file which contains 8.4.

    Thankfully there is a private fix available as a git pull request. It needed a few bug fixes, but works for our needs.

    FUTURE: Don't know how to stop it building 4 different frameworks, we only need Framework 4.5.
.LINK
    https://github.com/deploymentlive/DiscUtils
#>

[cmdletbinding()]
param(
    [switch] $Clean,
    [string[]] $ProjectFiles = @(
        "$PSscriptRoot\..\..\DiscUtils\Library\DiscUtils.Fat\DiscUtils.Fat.csproj"
        "$PSscriptRoot\..\..\DiscUtils\Library\DiscUtils.Iso9660\DiscUtils.Iso9660.csproj"
    ),
    $Destination = "$PSScriptRoot\bin"
)

# Requires MsBuild.exe current Version.
$msbuild = 'C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\amd64\MSBuild.exe'
if ( -not (test-path $msbuild) ) { throw "MSBuild not found" }

if ( $Clean.IsPresent) {
    foreach ( $project in $ProjectFiles ) {
        write-verbose "$MSBuild /t:clean '/p:Configuration=Release' '$project'"
        & $MSBuild /t:clean "/p:Configuration=Release" $project
    }
    return
}

new-item -ItemType Directory -path $Destination -ErrorAction SilentlyContinue | out-string | write-verbose

foreach ( $project in $ProjectFiles ) {
    write-verbose ("$MSBuild /t:Rebuild '/p:Configuration=Release' '$Project'" -replace '''','"' )
    & $MSBuild /t:Rebuild "/p:Configuration=Release" $project

    join-path (split-path $project) "\bin\Release\net45\*" | Copy-item -Destination $Destination

}

if ( -not ( test-path "$Destination\DiscUtils.Fat.dll" ) ) { throw "missing DiscUtils.Fat.dll" }
if ( -not ( test-path "$Destination\DiscUtils.Iso9660.dll" ) ) { throw "missing DiscUtils.Iso9660.dll" }
