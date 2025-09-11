# Setup a Microsoft Server for PXE booting.

## Windows Lab Kit

One of the easy ways to get started evaluating PXE booting on Microsoft Windows Servers is to simply download and install the [Windows 11 and Office 365 Deployment Lab Kit](https://learn.microsoft.com/en-us/microsoft-365/enterprise/modern-desktop-deployment-and-management-lab?view=o365-worldwide). 

These virtual machines have been pre-configured with a Microsoft DNS and DHCP Servers. 

## Installing and configuring TFTP

As a Pre-Requite, you must have a TFTP server running in your environment.

You can download the correct binaries from:

* https://www.deploymentlive.com/boot/snp_x64.efi
* https://www.deploymentlive.com/boot/snp_aa64.efi

Then run the powershell script: `configureTFTP.ps1` to enable TFTP and to copy the files above. 

## Installing and configuring DHCP

If you are running DHCP from a Microsoft Server, you can use the script: `configureDHCP.ps1` from the DHCP server itself.

You will need the IP address of the TFTP server as a parameter. 

Once configured your DHCP server will now supply the necessary PXE parameters to download Deployment Live iPXE from the TFTP server.


