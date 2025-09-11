<#
.SYNOPSIS
    Prepare DHCP Server for iPXE testing
.DESCRIPTION
    Uses Microsoft DHCP Server component for iPXE testing. 
.NOTES
    Implies running on DC1 server from the Windows 11 and Office 365 Deployment Lab Kit.
.LINK
    https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-office-365-lab-kit
#>

[cmdletbinding()]
param(
    $TFTPServer = '10.0.0.7',

    [parameter(mandatory)]
    $iPXEScript = 'https://boot.deploymentlive.com:8050/boot/cloudboot.ipxe'
)

Import-Module DhcpServer -ErrorAction SilentlyContinue


# From: https://www.iana.org/assignments/dhcpv6-parameters/dhcpv6-parameters.xhtml#processor-architecture
$Table = @"
Name,Description,Type,Data,InUse,File
PXEClient x86 BIOS,PXEClient x86 BIOS,Vendor,PXEClient:Arch:00000,true,boot/undionly.kpxe
PXEClient x86 UEFI,PXEClient x86 UEFI,Vendor,PXEClient:Arch:00006,true,boot/x86uefi/snp.efi
PXEClient x64 UEFI,PXEClient x64 UEFI,Vendor,PXEClient:Arch:00007,true,boot/x64uefi/snp.efi
PXEClient arm32 UEFI,PXEClient arm32 UEFI,Vendor,PXEClient:Arch:0000a,true,boot/arm/snp.efi
PXEClient arm64 UEFI,PXEClient arm64 UEFI,Vendor,PXEClient:Arch:0000b,true,boot/arm64/snp.efi
HTTPClient x86 UEFI,HTTPClient x86 UEFI,Vendor,HTTPClient:Arch:0000f,true,boot/x86uefi/snp.efi
HTTPClient x64 UEFI,HTTPClient x64 UEFI,Vendor,HTTPClient:Arch:00010,true,boot/x64uefi/snp.efi
HTTPClient arm32 UEFI,HTTPClient arm32 UEFI,Vendor,HTTPClient:Arch:00012,true,boot/arm/snp.efi
HTTPClient arm64 UEFI,HTTPClient arm64 UEFI,Vendor,HTTPClient:Arch:00013,true,boot/arm64/snp.efi
"@  -split "`r`n" | ConvertFrom-Csv 

#region Get Scope

$Scopes = Get-DhcpServerv4Scope

if ( $scopes | Measure-Object | ? Count -eq 1 ) { 
    $Scope = $Scopes
    write-verbose "Single Scope Found"
}
elseif ( $scopes | Measure-Object | ? Count -eq 0 ) {
    throw "No Scopes defined"
}
else { 
    $Scope = $Scopes | Out-GridView -OutputMode Single -Title "Select Scope"
}

if ( $scope.State -ne 'Active' ) { throw "Scope not found" }
write-verbose "Scope to be used:"
$scope | out-string | write-verbose

#endregion 

#region Get IP Address

if ( ! $TFTPServer ) {

    $ScopeTest = ([net.ipaddress]$Scope.scopeid).address -band $scope.SubnetMask.address

    $TFTPServer = Get-NetIPAddress -AddressFamily IPv4 | 
        where-object { (([net.ipaddress]$_.IPAddress).Address -band $scope.SubnetMask.Address) -eq $Scopetest } | 
        Select-object -first 1 -ExpandProperty IPAddress

}

write-verbose "IP Address for DHCP Server: $TFTPServer"

#endregion 

#region Create Classes

foreach ( $Item in $Table ) {

    $item | write-verbose

    #region Add Classes

    if ( ! ( Get-DhcpServerv4Class -name $Item.name -ErrorAction SilentlyContinue ) ) { 
        write-verbose "Add Class: $($Item.Name)"
        Add-DhcpServerv4Class -Name $item.Name -data $item.data -Type $Item.Type -PassThru | out-string | write-verbose
    }

    #endregion 

    #region Add Policy

    if ( ! ( Get-DhcpServerv4Policy -name $Item.Name -ScopeId $Scope.ScopeID -ErrorAction SilentlyContinue ) ) { 
        write-verbose "Add Policy: $($Item.Name)"
        Add-DhcpServerv4Policy -Name $Item.Name -ScopeId $Scope.ScopeID -Condition OR -VendorClass EQ,"$($ipv4Class.Name)*" -PassThru | out-string | Write-Verbose
    }

    #endregion

    #region add Option 66 TFTP Server 

    if ( ! ( Get-DhcpServerv4OptionValue -scopeid $Scope.ScopeId -Optionid 66 -PolicyName $Item.name -ErrorAction SilentlyContinue ) ) {
        write-verbose "Set Option 66:"
        Set-DhcpServerv4OptionValue -OptionId 66 -Value $TFTPServer -ScopeId $Scope.ScopeId -PolicyName $Item.name -PassThru | out-string | Write-verbose
    }

    #endregion 

    #region add option 67 Filename


    if ( ( Get-DhcpServerv4OptionValue -scopeid $Scope.ScopeId -Optionid 67 -PolicyName $Item.name -ErrorAction SilentlyContinue ) ) {
        write-verbose "Set Option 67:"
        Set-DhcpServerv4OptionValue -OptionId 67 -Value $Item.File -ScopeId $Scope.ScopeId -PolicyName $Item.name -PassThru | out-string | Write-verbose
    }

    #endregion 

}

#endregion 

#region Setup iPXE UserClass and Policy

if ( ! ( Get-DhcpServerv4Class -name 'iPXE' -ErrorAction SilentlyContinue ) ) { 
    write-verbose "Add Class: iPXE"
    Add-DhcpServerv4Class -Name 'iPXE' -data 'iPXE' -Type User -Description 'iPXE' 
    Restart-Service DhcpServer   # Grumble Grumble
}

if ( ! ( Get-DhcpServerv4Policy -name 'iPXE' -ScopeId $Scope.ScopeID -ErrorAction SilentlyContinue ) ) { 
    write-verbose "Add Policy: iPXE"
    Add-DhcpServerv4Policy -Name 'iPXE' -ScopeId $Scope.ScopeID -Condition OR -UserClass EQ,"iPXE" -ProcessingOrder 1 -PassThru | out-string | Write-Verbose
}

if ( ! ( Get-DhcpServerv4OptionValue -scopeid $Scope.ScopeId -PolicyName 'iPXE' -Optionid 67 -ErrorAction SilentlyContinue ) ) {
    write-verbose "Set Option 67:"
    Set-DhcpServerv4OptionValue -OptionId 67 -Value $iPXEScript -ScopeId $Scope.ScopeId -PolicyName 'iPXE' -PassThru | out-string | Write-verbose
}

#endregion
