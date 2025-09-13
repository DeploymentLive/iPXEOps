# Deployment Live iPXE Cloud Ready Deployment and Recovery - DHCP Proxy

- [Deployment Live iPXE Cloud Ready Deployment and Recovery - DHCP Proxy](#deployment-live-ipxe-cloud-ready-deployment-and-recovery---dhcp-proxy)
  - [Introduction](#introduction)
  - [Starting DHCP Proxy](#starting-dhcp-proxy)
    - [Hyper-V](#hyper-v)
  - [Menu System](#menu-system)
  - [Components on DHCP Proxy Virtual Machine](#components-on-dhcp-proxy-virtual-machine)
  - [Boot Process -  Client Side](#boot-process----client-side)
  - [Customization](#customization)
  - [Future Work.](#future-work)
  - [Thanks!](#thanks)
  - [More resources](#more-resources)


## Introduction

One of the powerful features of **Deployment Live iPXE** is the ability to launch it from PXE / Network Boot.
However, setting up a PXE server is generally considered a time consuming exercise. 

With the **Deployment Live iPXE - DHCP Proxy** server we now have a super easy way to start up a PXE server on our local network.

`Warning: your DHCP Server needs to be on the same subnet as the rest of your network. If you have a larger network, you should consult your networking team before deploying.`

**Deployment Live iPXE - DHCP Proxy** is a Linux Live image running the latest version of [Tiny Core Linux](http://www.tinycorelinux.net/). 
The image itself is only 20MB in size (Compared with some versions of Ubuntu Linux, which are 3000MB in size).

This version of Tiny Core linux has just a few add-on-components, including the popular [dnsmasq](https://en.wikipedia.org/wiki/Dnsmasq) service for DHCP and TFTP.

Dnsmasq is all we need to operate as a DHCP Proxy server, and it can easily run in parallel with your **existing** DHCP server.

## Starting DHCP Proxy

Starting up a DHCP Proxy Server is as easy as starting up any **Deployment Live iPXE** recovery process. 
That's because the **Deployment Live DHCP Proxy Server** is one of the entries in the `Advanced Tools Menu`.

So we can easily setup a Machine using the **Deployment Live iPXE** boot ISO media. See [here](usersguide.md#prepare-usb-flash-drive)

`Warning: Tiny Core Linux must not boot in Secure Boot. Please disable SecureBoot before starting`

### Hyper-V 

To start, go ahead and create a Virtual Machine:

* If you are running Hyper-V Make sure you have an **External** switch defined connected to your network (Wired Preferred).
* Then create a Virtual Machine with:
  * 1GB of Ram
  * Gen 2 with Secure Boot turned OFF.
  * No disk required
  * Virtual DVD: https://www.deploymentlive.com/iso/ProdNETamd64_DHCP.iso

or you can run this PowerShell script:
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
    Invoke-WebRequest -Uri 'https://www.deploymentlive.com/iso/ProdNETamd64_DHCP.iso' -OutFile $ISOPath
}

New-VM $Name -SwitchName $SwitchName -gen 2 -BootDevice 'CD' | Write-Verbose
Set-VMFirmware -VMName $Name -EnableSecureBoot off # Running Unsigned Linux
Set-VMDvdDrive -VMname $Name -path $ISOPath
Start-VM -name $Name
```

Once running, we should now have a DHCP Proxy Network Boot Server!

## Menu System

Once Running we should see the DHCP Log from `dnsmasq`. To stop, press `Ctrl-C`. 
Once logging has stopped on the screen (dnsmasq service is still running in the background). 

We should now see a DHCP Proxy operations menu:

```

--- Main Menu ---
1. View dnsmasq logs
2. Edit dnsmasq settings
3. Download autoexec.ipxe from URL
4. Edit autoexec.ipxe
5. Run shell
6. Exit
-----------------
Enter your choice: 

```

Options:
1. **View dnsmasq logs** - Restart the log viewer.
2. **Edit dnsmasq settings** - Allows you to edit the `dnsmasq` settings. This is not common.
3. **Download autoexec.ipxe from URL** - If you have a custom `autoexec.ipxe` file saved locally, now is a great time to grab it.
4. **Edit autoexec.ipxe** - Allows you to edit the `autoexec.ipxe` file saved locally.
5. **Run shell** - Start `/bin/sh`
6. **Exit** - Exit the menu system. To return call `menu.sh` or logout, then login again with user `tc`.


## Components on DHCP Proxy Virtual Machine

|file|Description|
|----|--------|
|`/opt/bootsync.sh`|Tiny Core Linux Boot script - Intialize components, network, dnsmasq |
|`/usr/bin/menu.sh`|Display the custom menu system|
|`/etc/dnsmasq.conf`|Pre-configured dnsmasq config file|
|`/tftpboot/snp_x64.efi`|**Deployment Live iPXE** x64 boot files.|
|`/tftpboot/snp_aa64.efi`|**Deployment Live iPXE** arm64 boot files.|
|`/tftpboot/autoexec.ipxe`|`Autoexec.ipxe` script|

## Boot Process -  Client Side

What does the boot process look like from the Client Side?

* User Turns on the Machine
* User presses the `Boot Menu` interrupt Key
  * Selects PXE/Network Boot
* Machine sends out a DHCP packet with PXE boot options
  * Primary DHCP server returns with DHCP Response:
    * IP adddress, Gateway, Netmask
    * DNS Servers
    * etc...
  * DHCP Proxy server returns with a DHCP Response:
    * TFTP server IP Address (next-server)
    * Path to boot program on TFTP server (filename)
* Machine downloads **Deployment Live iPXE** from TFTP.
  * Machine starts **Deployment Live iPXE** process.
* **Deployment Live iPXE** starts.
  * Checks for `autoexec.ipxe` file on a local disk, and executes.
  * Otherwise, run though the ipxe `autoboot` command.
    * Make **another** DHCP call with `user-class=ipxe`.
    * Primary DHCP Server returns with same DHCP response.
    * DHCP Proxy Server must identify the `user-class=ipxe` entry.
      * Sends out the path to `autoexec.ipxe` on the local TFTP server.
  * **Deployment Live iPXE** calls autoexec.ipxe.

## Customization

Most users will be most interested in modifying the `/tftpboot/autoexec.ipxe` file on the Virtual Machine.

Because the DHCP Proxy server doesn't use any persistent disks by default, please save your
`autoexec.ipxe` customizations on a local web server on the local network. Then use the `3. Download autoexec.ipxe from URL` command above to download and execute. 

for more information on how to modify the `autoexec.ipxe` file, check [here](admin-autoexec.md).

## Future Work.

* Need a process to save current settings and store locally for persistence.
* We can create an ISO/USB image that contains the line (But hard to describe for now):
    * `set dhcpproxy_args autoexec=http://server/path/autoexec.ipxe`

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
