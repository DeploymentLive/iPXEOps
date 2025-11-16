# Deployment Live iPXE Cloud Ready Deployment and Recovery - Frequently Asked Questions

- [Deployment Live iPXE Cloud Ready Deployment and Recovery - Frequently Asked Questions](#deployment-live-ipxe-cloud-ready-deployment-and-recovery---frequently-asked-questions)
  - [General Questions](#general-questions)
    - [What is Deployment Live Cloud Ready Deployment and Recovery Tool?](#what-is-deployment-live-cloud-ready-deployment-and-recovery-tool)
    - [What Makes it so Special?](#what-makes-it-so-special)
    - [Where can I get this product:](#where-can-i-get-this-product)
      - [ISO Images](#iso-images)
      - [Direct download (for HTTPS boot)](#direct-download-for-https-boot)
      - [HP Boot Files](#hp-boot-files)
      - [Other Misc Files](#other-misc-files)
  - [Scripting](#scripting)
    - [How to create a Hyper-V Machine for DHCP Proxy:](#how-to-create-a-hyper-v-machine-for-dhcp-proxy)
  - [How to create a Hyper-V machine for Client Testing?](#how-to-create-a-hyper-v-machine-for-client-testing)
  - [Troubleshooting](#troubleshooting)
    - [Ubuntu won't download on my Hyper-V Machine.](#ubuntu-wont-download-on-my-hyper-v-machine)
    - [I found a bug, how do I report it?](#i-found-a-bug-how-do-i-report-it)
  - [Misc questions](#misc-questions)
    - [Does \*\*Deployment Live iPXE support wireless recovery?](#does-deployment-live-ipxe-support-wireless-recovery)
  - [Licensing Questions](#licensing-questions)
    - [What kind of Licensed versions are there?](#what-kind-of-licensed-versions-are-there)
    - [Licensing Table:](#licensing-table)
    - [What if I want to develop my own Recovery Solution?](#what-if-i-want-to-develop-my-own-recovery-solution)
  - [Thanks!](#thanks)
  - [More resources](#more-resources)


## General Questions

### What is Deployment Live Cloud Ready Deployment and Recovery Tool?

It's a version of the popular [ipxe](https://ipxe.org) network boot loader, that has been tailored for Windows Operating System Deployment and Recovery.

The **Deployment Live iPXE** binary itself is very small, around 400Kb to 500Kb in size. And can be started via USB, PXE, HTTPS, and more.

Once you have started **Deployment Live iPXE** we can guide you through various deployment and recovery scenarios. 

This product was designed to assist IT departments and end users with the task of recovering machines:
* If the machine has been attacked by Malware.
* If the machine has a critical issue like the CrowdStrike Bug from 2024.
* Or if the Operating System has simply stopped working. 

### What Makes it so Special?

iPXE has been around for a while, it's an ideal network boot loader that uses modern HTTP/HTTPS for communication, 
but so far, no one has publicly released a general version that is signed by Microsoft for Secure Boot.

iPXE with HTTPS can start the Deployment and Recovery process from the cloud, 
and a cloud server is ideal for recovery in malware scenario if all resources in a company have been compromised.

Additionally, with the advent of HTTPS booting in newer UEFI firmware, we now have the ideal delivery mechanism 
for machines with HTTPS. Now even home users can recover quickly and efficiently when things go wrong. More to follow. 

### Where can I get this product:

#### ISO Images

You can mount these ISO images within Hyper-V, or use tools like [Rufus](https:://rufus.ie) to copy to USB Keys.

|URL|Description|
|-----|-----|
|https://www.deploymentlive.com/block/ProdNETDual.iso **MOST COMMON**|Contains Dual Boot (x64 & arm64) Signed iPXE files for computers with **Built in Ethernet**|
|https://www.deploymentlive.com/block/ProdNETamd64.iso|Contains x64 Signed iPXE files for computers with **Built in Ethernet**|
|https://www.deploymentlive.com/block/ProdNETarm64.iso|Contains arm64 Signed iPXE files for computers with **Built in Ethernet**|
|https://www.deploymentlive.com/block/ProdNETamd64Unsigned.iso|Contains x64 **Un-Signed** iPXE files for computers with **Built in Ethernet**|
|https://www.deploymentlive.com/block/ProdNETarm64Unsigned.iso|Contains arm64 **Un-Signed** iPXE files for computers with **Built in Ethernet**|
|https://www.deploymentlive.com/block/ProdUSBDual.iso **MOST COMMON**|Contains Dual Boot (x64 & arm64) Signed iPXE files for computers with **USB to Ethernet**|
|https://www.deploymentlive.com/block/ProdUSBamd64.iso|Contains x64 Signed iPXE files for computers with **USB to Ethernet**|
|https://www.deploymentlive.com/block/ProdUSBarm64.iso|Contains arm64 Signed iPXE files for computers with **USB to Ethernet**|
|https://www.deploymentlive.com/block/ProdUSBamd64Unsigned.iso|Contains x64 **Un-Signed** iPXE files for computers with **USB to Ethernet**|
|https://www.deploymentlive.com/block/ProdUSBarm64Unsigned.iso|Contains arm64 **Un-Signed** iPXE files for computers with **USB to Ethernet**|
<!--
|https://www.deploymentlive.com/block/ProdNETamd64_DHCP.iso|Contains x64 Signed **DHCP Test** iPXE files for computers with **Built in Ethernet**|
|https://www.deploymentlive.com/block/ProdNETamd64_Linux.iso|Contains x64 Signed **Linux Test** iPXE files for computers with **Built in Ethernet**|
|https://www.deploymentlive.com/block/ProdNETamd64_WinPE.iso|Contains x64 Signed **WinPE Test** iPXE files for computers with **Built in Ethernet**|
-->

Why use either USB or NET?  Well USB (sometimes called DRV) versions of iPXE have support for some external USB to Ethernet Adapters.
However, sometimes when iPXE initializes the USB bus, it looses connectivity with some USB Keyboards. So best to use the USB version only if REQUIRED!

#### Direct download (for HTTPS boot)

|URL|Description|
|-----|-----|
|https://www.deploymentlive.com/Boot/snp_DRV_unsigned_x64.efi|**Un-Signed** x64 iPXE file for **USB to Ethernet**|
|https://www.deploymentlive.com/Boot/snp_DRV_unsigned_aa64.efi|**Un-Signed** arm64 iPXE file for **USB to Ethernet**|
|https://www.deploymentlive.com/Boot/snp_unsigned_x64.efi|**Un-Signed** x64 iPXE file for Built in Ethernet|
|https://www.deploymentlive.com/Boot/snp_unsigned_aa64.efi|**Un-Signed** arm64 iPXE file for Built in Ethernet|
|https://www.deploymentlive.com/Boot/snp_DRV_x64.efi|Signed x64 iPXE file for **USB to Ethernet**|
|https://www.deploymentlive.com/Boot/snp_DRV_aa64.efi|Signed arm64 iPXE file for **USB to Ethernet**|
|https://www.deploymentlive.com/Boot/snp_x64.efi|Signed x64 iPXE file for Built in Ethernet|
|https://www.deploymentlive.com/Boot/snp_aa64.efi|Signed arm64 iPXE file for Built in Ethernet|

If booting from HTTPS, you may wish to use the CA.crt below, and the URL: https://aws.deploymentlive.com/... 

#### HP Boot Files

**Deployment Live iPXE** supports HP Sure Recover out of the box! 

You will need to create a Sure Recover payload using `New-HPSureRecoverImageConfigurationPayload`.
It will require your Signing key, the URL to boot, and the Image Certificate below.

|URL|Description|
|-----|-----|
|https://www.deploymentlive.com/Boot/DeploymentLive-HP-RE-cert.pem|Image Certificate for Deployment Live|
|https://www.deploymentlive.com/HP</br>https://www.deploymentlive.com/HP/Signed_Net_x64|URL (both work) for machines with Built in Ethernet|
|https://www.deploymentlive.com/HP/Signed_Drv_x64|URL for machines that need **USB to Ethernet**|

<!-- More documentation to follow -->

#### Other Misc Files

|URL|Description|
|-----|-----|
|https://www.deploymentlive.com/Boot/ca.crt|Deployment Live Certificate Authority Cert file|
|https://www.deploymentlive.com/Boot/cloudboot.ipxe|Cloud Boot entry Point.|
|https://www.deploymentlive.com/Boot/Githubcross.crt|Used for Cross Signing (if any)|
|https://www.deploymentlive.com/Boot/shimx64.efi|Linux Shim used for Secure Boot.|
|https://www.deploymentlive.com/Boot/winpeshl.ini|winpeshl.ini used in WinPE.|


## Scripting

### How to create a Hyper-V Machine for DHCP Proxy:

```
#Requires -RunAsAdministrator
# Create iPXE DHCP Proxy (No Disk,1GB RAM)

[cmdletbinding()]
param(
    $Name = 'iPXE DHCP Proxy',    
    $SwitchName = ( Get-VMSwitch -SwitchType External | Select -first 1 -ExpandProperty Name ),
    $ISOPath
)

if ( !$ISOPath ) { 
    $ISOPath = "$env:temp\DeploymentLiveiPXE_x64.iso"
    Invoke-WebRequest -Uri 'https://www.deploymentlive.com/iso/snp_DRV_x64.efi.iso' -OutFile $ISOPath
}

New-VM $Name -SwitchName $SwitchName -gen 2 -BootDevice 'CD' | Write-Verbose
Set-VMFirmware -VMName $Name -EnableSecureBoot off # Running Unsigned Linux
Set-VMDvdDrive -VMname $Name -path $ISOPath
Start-VM -name $Name
```

## How to create a Hyper-V machine for Client Testing?

```
#Requires -RunAsAdministrator
# Create iPXE Client Machine (Default Disk,8GB RAM,SecureBoot off)

[cmdletbinding()]
param(
    $Name = 'iPXE test machine',
    $SwitchName = ( Get-VMSwitch -SwitchType External | Select -first 1 -ExpandProperty Name ),
    $ISOPath
)

if ( !$ISOPath ) { 
    $ISOPath = "$env:temp\DeploymentLiveiPXE_x64.iso"
    Invoke-WebRequest -Uri 'https://www.deploymentlive.com/iso/snp_DRV_x64.efi.iso' -OutFile $ISOPath
}

$VhdPath = join-path (get-vmhost).VirtualMachinePath ($Name + '.vhdx')
New-VM $Name -SwitchName $SwitchName -gen 2 -BootDevice 'CD' -MemoryStartupBytes 8gb -NewVHDPath $VhdPath | Write-Verbose
Set-VMFirmware -VMName $Name -EnableSecureBoot off # Running Unsigned Linux
Set-VMDvdDrive -VMname $Name -path $ISOPath
Start-VM -name $Name
```

## Troubleshooting

### Ubuntu won't download on my Hyper-V Machine.

If there is not enough ram to store the file, the download can fail. 
VM's testing out Windows and/or Ubuntu live should have **8GB** of RAM. (Sorry)

### I found a bug, how do I report it?

https://github.com/DeploymentLive/iPXEOps/issues

## Misc questions

### Does **Deployment Live iPXE support wireless recovery?

Currently not supported, but may be supported in the future. 



## Licensing Questions

### What kind of Licensed versions are there?

* **Deployment Live iPXE - Unsigned** - All unsigned versions of iPXE fall under `GPL 2.0` You are allowed to copy and distribute at will.</br>
Full Binaries can be found at: https://github.com/DeploymentLive/ipxebuilder under releases.
* **Deployment Live iPXE - Public Version** - We have also taken the Un-Signed binaries above, and aggregated a Secure Boot digital signature at the end of the binary.</br>
These files are public (see above), do not re-distribute, use the links above to download. Note that the public versions contain only **ONE** trusted CA cert: `Deployment Live CA`. See above.
* **Deployment Live iPXE - Enterprise Version** - In addition to public signed version, there is also a Enterprise version with a Secure Boot digital signature aggregated at the end.</br>
In addition to the Signed **Public Version** above, this version has full trust with all Mozilla trusted Certificate Authorities, and other enhanced features like Peer to Peer support.

How do you get the **Enterprise Version**? Please contact us for more information info@deploymentlive.com

### Licensing Table:

|Feature                                     |[iPXE](https://ipxe.org) GPL 2.0|Deployment Live</br>Free|Deployment Live</br> **Enterprise**|
|--------------------------------------------|--------------------|--------------------|------------------------------|
|Boot from USB,PXE, or HTTPS                 |Yes                 |Yes                 |Yes                           |
|Download from HTTP                          |Yes                 |Yes                 |Yes                           |
|Download from TFTP                          |Yes                 |Yes                 |Yes                           |
|Download from https://deploymentlive.com    |Yes                 |Yes                 |Yes                           |
|Download from other HTTPS (Full Mozilla CA) |Yes                 |**No  <--**         |Yes                           |
|Signed with Secure Boot CA Key              |**No  <--**         |Yes                 |Yes                           |
|Peer to Peer (Branch Cache) Support         |Yes                 |No                  |Yes                           |

* Full Mozilla Trusted CA authority list as found in iPXE.

### What if I want to develop my own Recovery Solution?

The public version allows you to create your own version, and you can connect to your own internal HTTP (not-encrypted) server, 
it may require you to learn iPXE script (my apologies in advance).

However, if you would like to connect to your own HTTPS (encrypted) cloud solution, please contact us. info@deploymentlive.com


## Thanks!

Hopefully this should help you get started in restoring your machine. 

Please let us know if you have any feedback on this guide.

info@deploymentlive.com

## More resources

* [Users Guide](usersguide.md)
* [Evaluation Guide](EvalGuide.md)
* [Administrators Guide](AdminGuide.md)
  * [Admin AutoExec.ipxe](admin-autoexec.md)
  * [Admin DHCP Proxy](admin-dhcpproxy.md)
* [Frequently Asked Questions](faqguide.md)
