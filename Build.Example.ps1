<#
.SYNOPSIS
    Build commands for my environment.
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

[cmdletbinding()]
param( )

$HPVersion = '3'

$ProdCAServer = 'https://Boot.deploymentlive.com:8050/boot/cloudboot.ipxe'
$ProdFullServer = 'https://ops.deploymentlive.com/boot/cloudboot.ipxe'
$NonProdCAServer = 'https://Lab.deploymentlive.com:8050/boot/cloudboot.ipxe'
$NonProdFullServer = 'https://Lab.deploymentlive.com/boot/cloudboot.ipxe'

$iPXEProdCAServer = "#!ipxe`r`nset force_filename " + 'https://Boot.deploymentlive.com:8050/boot/cloudboot.ipxe' + "`r`n"
$iPXEProdFullServer = "#!ipxe`r`nset force_filename " + 'https://ops.deploymentlive.com/boot/cloudboot.ipxe' + "`r`n"
$iPXENonProdCAServer = "#!ipxe`r`nset force_filename " + 'https://Lab.deploymentlive.com:8050/boot/cloudboot.ipxe' + "`r`n"
$iPXENonProdFullServer = "#!ipxe`r`nset force_filename " + 'https://Lab.deploymentlive.com/boot/cloudboot.ipxe' + "`r`n"

$Control = @{

    # List of virtual Machines to launch...
    # Hashtable of arguments to Start-VM

    REVaultID = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'

    WinPESrc = @{
        arm64 = dir C:\OSDWorkspace\build\windows-pe\*arm64\Winpe-media\sources\*.wim | sort lastwritetime | select -last 1 -ExpandProperty FullName
        amd64 = dir C:\OSDWorkspace\build\windows-pe\*amd64\Winpe-media\sources\*.wim | sort lastwritetime | select -last 1 -ExpandProperty FullName
    }

    ExtraFiles = @(
        @{
            Path = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\EFI\Microsoft\boot\BCD'
            destination = "$PSScriptRoot\Build\boot\WinPE\x86_64\BCD"
        }
        @{
            Path = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\boot\boot.sdi'
            destination = "$PSScriptRoot\Build\boot\WinPE\x86_64\boot.sdi"
        }
        @{
            Path = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\arm64\Media\EFI\Microsoft\boot\BCD'
            destination = "$PSScriptRoot\Build\boot\WinPE\arm64\BCD"
        }
        @{
            Path = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\arm64\Media\boot\boot.sdi'
            destination = "$PSScriptRoot\Build\boot\WinPE\arm64\boot.sdi"
        }

        @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_CA_aa64.efi" ; destination = "$PSScriptRoot\Build\boot\snp_aa64.efi" }
        @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_CA_aa64.efi" ; destination = "$PSScriptRoot\Build\boot\snp_DRV_aa64.efi" }
        @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_CA_x64.efi" ; destination = "$PSScriptRoot\Build\boot\snp_DRV_x64.efi" }
        @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_CA_x64.efi" ; destination = "$PSScriptRoot\Build\boot\snp_x64.efi" }

        @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\UnSigned\snp_aa64.efi" ; destination = "$PSScriptRoot\Build\boot\snp_unsigned_aa64.efi" }
        @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\UnSigned\snp_DRV_aa64.efi" ; destination = "$PSScriptRoot\Build\boot\snp_DRV_unsigned_aa64.efi" }
        @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\UnSigned\snp_DRV_x64.efi" ; destination = "$PSScriptRoot\Build\boot\snp_DRV_unsigned_x64.efi" }
        @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\UnSigned\snp_x64.efi" ; destination = "$PSScriptRoot\Build\boot\snp_unsigned_x64.efi" }

        @{ path = "$PSScriptRoot\github\Crossusertrust.crt"; destination = "$PSScriptRoot\Build\boot\Githubcross.crt" }
        @{ path = "$PSScriptRoot\ipxe\shimx64.efi"; destination = "$PSScriptRoot\Build\boot\shimx64.efi" }
        @{ path = "$PSScriptRoot\ipxe\winpeshl.ini"; destination = "$PSScriptRoot\Build\boot\winpeshl.ini" }
        @{ path = "$PSScriptRoot\..\iPXEBuilder\customers\DeploymentLive\Certs\ca.crt"; destination = "$PSScriptRoot\Build\boot\ca.crt" }

    )

    iPXEFiles = @(
        @{
            path = "$PSScriptRoot\ipxe\cloudboot.sh"
            Destination = "$PSScriptRoot\Build\boot\cloudboot.ipxe"
        }
    )

    VirtualRegressionTests = @(

        # @{ VMName = 'Deployment Live iPXE Test'  }
    )

    TargetMachines = @(

        @{
            TargetFolder = '\\Server\public'
        }
        @{
            TargetFolder = "$env:UserProfile\source\repos\DeploymentLiveWeb\www\"
            GitPush = $false
        }

    )

    ISOImages = @(

        @{ Name = 'ProdNETarm64'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_CA_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ text = $iPXEProdCAServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'ProdUSBarm64'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_CA_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ text = $iPXEProdCAServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'ProdUSBamd64'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_CA_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXEProdCAServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'ProdNETamd64'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_CA_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXEProdCAServer;  destination = 'autoexec.ipxe' }
        )}

        @{ Name = 'ProdNETDual'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_CA_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_CA_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXEProdCAServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'ProdUSBDual'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_CA_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_CA_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXEProdCAServer;  destination = 'autoexec.ipxe' }
        )}

        @{ Name = 'ProdNETarm64Paid'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ text = $iPXEProdFullServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'ProdUSBarm64Paid'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ text = $iPXEProdFullServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'ProdUSBamd64Paid'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXEProdFullServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'ProdNETamd64Paid'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXEProdFullServer;  destination = 'autoexec.ipxe' }
        )}

        @{ Name = 'ProdNETDualPaid'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXEProdFullServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'ProdUSBDualPaid'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ text = $iPXEProdFullServer;  destination = 'autoexec.ipxe' }
        )}

        @{ Name = 'ProdNETarm64Unsigned'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ text = $iPXEProdFullServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'ProdUSBarm64Unsigned'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_DRV_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ text = $iPXEProdFullServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'ProdUSBamd64Unsigned'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_DRV_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXEProdFullServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'ProdNETamd64Unsigned'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXEProdFullServer;  destination = 'autoexec.ipxe' }
        )}

        @{ Name = 'TestNETarm64'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_CA_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ text = $iPXENonProdCAServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'TestUSBarm64'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_CA_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ text = $iPXENonProdCAServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'TestUSBamd64'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_CA_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXENonProdCAServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'TestNETamd64'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_CA_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXENonProdCAServer;  destination = 'autoexec.ipxe' }
        )}

        @{ Name = 'TestNETarm64Paid'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ text = $iPXENonProdFullServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'TestUSBarm64Paid'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ text = $iPXENonProdFullServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'TestUSBamd64Paid'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXENonProdFullServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'TestNETamd64Paid'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXENonProdFullServer;  destination = 'autoexec.ipxe' }
        )}

        @{ Name = 'TestNETarm64Unsigned'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ text = $iPXENonProdFullServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'TestUSBarm64Unsigned'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_DRV_aa64.efi" ; destination = 'EFI\BOOT\BOOTAA64.EFI'}
            @{ text = $iPXENonProdFullServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'TestUSBamd64Unsigned'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_DRV_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXENonProdFullServer;  destination = 'autoexec.ipxe' }
        )}
        @{ Name = 'TestNETamd64Unsigned'; files = @(
            @{ path = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_x64.efi" ; destination = 'EFI\BOOT\BOOTX64.EFI'}
            @{ text = $iPXENonProdFullServer;  destination = 'autoexec.ipxe' }
        )}    
    
    )

    HPSureRecoverTargets = @(

        # Main Production Use Case using private CA
        @{ Name = 'Signed_Net_aa64' ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_CA_aa64.efi";      Target = $ProdCAServer; Version = $HPVersion }
        @{ Name = 'Signed_Drv_aa64' ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_CA_aa64.efi";  Target = $ProdCAServer; Version = $HPVersion }
        @{ Name = 'Signed_Drv_x64'  ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_CA_x64.efi";   Target = $ProdCAServer; Version = $HPVersion }
        @{ Name = 'Signed_Net_x64'  ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_CA_x64.efi";       Target = $ProdCAServer; Version = $HPVersion }
        @{ Name = '.'  ;              Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_CA_x64.efi";       Target = $ProdCAServer; Version = $HPVersion }    # Default 

        <#
        # For Full HTTPS Production use with Signed Binaries (Not common)
        @{ Name = 'Paid_Signed_Net_aa64' ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_aa64.efi";     Target = $ProdFullServer; Version = $HPVersion }
        @{ Name = 'Paid_Signed_Drv_aa64' ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_aa64.efi"; Target = $ProdFullServer; Version = $HPVersion }
        @{ Name = 'Paid_Signed_Drv_x64'  ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_x64.efi";  Target = $ProdFullServer; Version = $HPVersion }
        @{ Name = 'Paid_Signed_Net_x64'  ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_x64.efi";      Target = $ProdFullServer; Version = $HPVersion }
        #>

        # For Full HTTPS by customer in Production Environment, Unsigned Binaries.
        @{ Name = 'Unsigned_Net_aa64' ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_aa64.efi";     Target = $ProdFullServer; Version = $HPVersion }
        @{ Name = 'Unsigned_Drv_aa64' ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_DRV_aa64.efi"; Target = $ProdFullServer; Version = $HPVersion }
        @{ Name = 'Unsigned_Drv_x64'  ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_DRV_x64.efi";  Target = $ProdFullServer; Version = $HPVersion }
        @{ Name = 'Unsigned_Net_x64'  ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_x64.efi";      Target = $ProdFullServer; Version = $HPVersion }

        # Non-Prod Private CA use using public signed binaries
        @{ Name = 'Signed_Net_aa64_nonProd' ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_CA_aa64.efi";      Target = $NonProdCAServer; Version = $HPVersion }
        @{ Name = 'Signed_Drv_aa64_nonProd' ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_CA_aa64.efi";  Target = $NonProdCAServer; Version = $HPVersion }
        @{ Name = 'Signed_Drv_x64_nonProd'  ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_CA_x64.efi";   Target = $NonProdCAServer; Version = $HPVersion }
        @{ Name = 'Signed_Net_x64_nonProd'  ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_CA_x64.efi";       Target = $NonProdCAServer; Version = $HPVersion }

        # For Full HTTPS in non-Prod environment, not signed
        @{ Name = 'Unsigned_Net_aa64_nonProd' ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_aa64.efi";     Target = $NonProdFullServer; Version = $HPVersion }
        @{ Name = 'Unsigned_Drv_aa64_nonProd' ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_DRV_aa64.efi"; Target = $NonProdFullServer; Version = $HPVersion }
        @{ Name = 'Unsigned_Drv_x64_nonProd'  ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_DRV_x64.efi";  Target = $NonProdFullServer; Version = $HPVersion }
        @{ Name = 'Unsigned_Net_x64_nonProd'  ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Unsigned\snp_x64.efi";      Target = $NonProdFullServer; Version = $HPVersion }

        <#
        # For Full HTTPS testing in Non-Prod environemnt (Not Common)
        @{ Name = 'Paid_Signed_Net_aa64_nonProd' ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_aa64.efi";     Target = $NonProdFullServer; Version = $HPVersion }
        @{ Name = 'Paid_Signed_Drv_aa64_nonProd' ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_aa64.efi"; Target = $NonProdFullServer; Version = $HPVersion }
        @{ Name = 'Paid_Signed_Drv_x64_nonProd'  ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_DRV_x64.efi";  Target = $NonProdFullServer; Version = $HPVersion }
        @{ Name = 'Paid_Signed_Net_x64_nonProd'  ; Binary = "$PSScriptRoot\..\iPXEBuilder\Build\Signed\snp_x64.efi";      Target = $NonProdFullServer; Version = $HPVersion }
        #>
    )

    Verbose = $True
}

# $Control | convertto-json -Depth 10 | write-verbose
& "$PSscriptRoot\Build.ps1" @Control
