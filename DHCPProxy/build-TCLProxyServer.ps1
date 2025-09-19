<#
.SYNOPSIS
    Create a Tiny Core Linux-based DHCP Proxy Server image for iPXE testing.
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Copyright Deployment Live LLC, All Rights Reserved
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

[CmdletBinding()]
param (
    $TCLBuild = @(
        'http://www.tinycorelinux.net/16.x/x86_64/release/distribution_files/corepure64.gz'
        'http://www.tinycorelinux.net/16.x/x86_64/release/distribution_files/vmlinuz64'
    ),
    $Packages = @(
        'http://www.tinycorelinux.net/16.x/x86_64/tcz/dnsmasq.tcz'
        'http://www.tinycorelinux.net/16.x/x86_64/tcz/nano.tcz'
        'http://www.tinycorelinux.net/16.x/x86_64/tcz/nano-locale.tcz'

        'http://www.tinycorelinux.net/16.x/x86_64/tcz/ncursesw.tcz'
        'http://www.tinycorelinux.net/16.x/x86_64/tcz/libzstd.tcz'
        'http://www.tinycorelinux.net/16.x/x86_64/tcz/bzip2-lib.tcz'
        'http://www.tinycorelinux.net/16.x/x86_64/tcz/liblzma.tcz'
        'http://www.tinycorelinux.net/16.x/x86_64/tcz/file.tcz'

        'http://www.tinycorelinux.net/16.x/x86_64/tcz/dnsmasq.tcz.md5.txt'
        'http://www.tinycorelinux.net/16.x/x86_64/tcz/nano.tcz.md5.txt'
        'http://www.tinycorelinux.net/16.x/x86_64/tcz/nano-locale.tcz.md5.txt'

        'http://www.tinycorelinux.net/16.x/x86_64/tcz/ncursesw.tcz.md5.txt'
        'http://www.tinycorelinux.net/16.x/x86_64/tcz/libzstd.tcz.md5.txt'
        'http://www.tinycorelinux.net/16.x/x86_64/tcz/bzip2-lib.tcz.md5.txt'
        'http://www.tinycorelinux.net/16.x/x86_64/tcz/liblzma.tcz.md5.txt'
        'http://www.tinycorelinux.net/16.x/x86_64/tcz/file.tcz.md5.txt'

        ),
    $OtherFiles = @(
        @{ path = "$PSScriptRoot\build\signed\snp_CA_x64.efi" ; dest = '/tftpboot/snp_x64.efi' }
        @{ path = "$PSScriptRoot\build\signed\snp_CA_aa64.efi" ; dest = '/tftpboot/snp_aa64.efi' }
        @{ path =     "$PSScriptRoot/dnsmasq.conf" ; dest = '/etc/dnsmasq.conf' }
        @{ path =     "$PSScriptRoot/bootsync.sh" ; dest = '/opt/bootsync.sh' }
        @{ path =     "$PSScriptRoot/menu.sh" ; dest = '/usr/bin/menu.sh' }
        @{ path = "$PSScriptRoot/autoexec.ipxe" ; dest = '/tftpboot/autoexec.ipxe' }
    ),

    [switch]$Fast = $true,
    [switch]$forcedownload,
    [string]$tmpPath = '/tmp/tclbuild'

)

#region Verify WSL is available

if ( -not ( test-path \\wsl.localhost\ubuntu ) ) {
    throw "WSL Ubuntu instance not available. Please install WSL and an Ubuntu distribution from the Microsoft Store."
}

#endregion

#region Download TCL
write-verbose "Download Components"

$wsltmp = "\\wsl.localhost\ubuntu$($tmpPath -replace '/','\')"
write-verbose "make tmp directory $wsltmp"
if ( -not (test-path $wsltmp) ) {
    wsl.exe -- mkdir -p $tmpPath
}

foreach ($url in ($TCLBuild+$packages) ) {
    $fileName = join-path $wsltmp (Split-Path $url -Leaf)
    if ( (test-path $fileName) -and -not $forcedownload.IsPresent ) {
        write-verbose "$fileName already exists, skipping download"
        continue
    }    
    write-verbose "Downloading $url to $fileName"
    Invoke-WebRequest -Uri $url -OutFile $fileName
}

#endregion

#region download support files

write-verbose "Copy Other Support Files"
copy-item $OtherFiles.path -dest "\\wsl.localhost\ubuntu$($tmpPath -replace '/','\')\" -force
wsl.exe -- ls -la /tmp/tclbuild/  | write-verbose

#endregion

#region Extract Filesystem

write-verbose "Cleanup previous Extracts if any"

wsl.exe -u root -- rm -rf "$tmpPath/extract"

write-verbose "Extract from $tmpPath/corepure64.gz"

wsl.exe -- mkdir -p -m=777 "$tmpPath/extract"
wsl.exe -u root --cd "$tmpPath/extract" -- zcat "$tmpPath/corepure64.gz" `| cpio -i -H newc -d

#endregion

#region Build filesystem

write-verbose "Copy Optional TCL Packages"
wsl.exe -- mkdir -p "$tmpPath/extract/tce/optional/"
wsl.exe -- mkdir -p "$tmpPath/extract/tftpboot/"
wsl.exe -- cp "$tmpPath/*.tcz" "$tmpPath/extract/tce/optional/"
wsl.exe -- cp "$tmpPath/*.tcz.md5.txt" "$tmpPath/extract/tce/optional/"
wsl.exe -- ls -1 "$tmpPath/extract/tce/optional" `> "$tmpPath/extract/tce/onboot.lst"

write-verbose "copy other files"

foreach ( $file in $OtherFiles ) {
    write-verbose "cp $tmpPath/$( split-path $file.path -leaf )  $tmpPath/extract$($file.dest)"
    wsl -u root -- cp "$tmpPath/$( split-path $file.path -leaf )"  "$tmpPath/extract$($file.dest)" --force
}

wsl.exe -u root -- echo "/usr/bin/menu.sh" `>`> "$tmpPath/extract/etc/skel/.profile"

wsl -u root -- chmod 755 "$tmpPath/extract/usr/bin/menu.sh"
wsl -u root -- chmod 666 "$tmpPath/extract/tftpboot/autoexec.ipxe"
wsl -u root -- dos2unix "$tmpPath/extract/tftpboot/autoexec.ipxe"

#endregion

#region create newc filesystem

write-verbose "Create new cpio.gz filesystem"

wsl.exe -u root -- rm -f "$tmpPath/tinycore.gz"
wsl.exe -u root --cd "$tmpPath/extract" -- find `| cpio -o -H newc `|  gzip -2 `> "$tmpPath/tinycore.gz"

if ( -not $Fast.IsPresent ) {
    write-verbose "SUPER Compress..."
    wsl.exe --cd "$tmpPath" -- cp tinycore.gz tinycore_quick.gz --force
    wsl.exe --cd "$tmpPath" -- advdef -z4 tinycore.gz
}

#endregion
