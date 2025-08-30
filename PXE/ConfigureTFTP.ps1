<#
.SYNOPSIS
    Prepare TFTP Server for iPXE testing
.DESCRIPTION
    Uses WDSServer TFTP Server component for iPXE testing. 
.NOTES
    Implies running on CM1 server from the Windows 11 and Office 365 Deployment Lab Kit.
.LINK
    https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-office-365-lab-kit
#>


[cmdletbinding()]
param(
    [parameter(mandatory)]
    $BuildPath
    )

#region Prepare Paths

$WDSRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\WDSServer\Providers"
$TFTPRoot = get-ItemProperty -Path "$WDSRegPath\WDSTFTP" | % RootFolder
$TFTPBoot = join-path $TFTPRoot 'boot'

#endregion 

#region Prepare TFTP Filters

$ReadFilterValues = @"
\boot\*
/boot\*
/boot/*
boot\*
boot/*
\tmp\*
tmp\*
"@ -split "`r`n"

Set-ItemProperty -Path $TFTPRegPath -Name "ReadFilter" -Value $ReadFilterValues -type 'MultiString'

set-itemProperty -path "$WDSRegPath\WDSPxe" -name "UseDhcpPorts" -value 0

stop-service WDSServer -ErrorAction SilentlyContinue
start-service WDSServer 

#endregion 

#region Copy iPXE binaries

copy-item -force "$BuildPath\Signed\snp_ca_aa64.efi" "$TFTPBoot\arm64\snp.efi"
copy-item -force "$BuildPath\Signed\snp_ca_x64.efi" "$TFTPBoot\x64uefi\snp.efi"

copy-item -force "$BuildPath\Unsigned\undionly.kpxe" "$TFTPBoot\undionly.kpxe"

# copy-item -force "$BuildPath\Unsigned\snp_aa32.efi" "$TFTPBoot\arm\snp.efi"
# copy-item -force "$BuildPath\Unsigned\snp_x86.efi" "$TFTPBoot\x86uefi\snp.efi"

#endregion





