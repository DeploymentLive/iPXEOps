# Deployment Live iPXE Cloud Ready Deployment and Recovery - Autoexec.ipxe

- [Deployment Live iPXE Cloud Ready Deployment and Recovery - Autoexec.ipxe](#deployment-live-ipxe-cloud-ready-deployment-and-recovery---autoexecipxe)
  - [Introduction](#introduction)
  - [iPXE Scripting](#ipxe-scripting)
  - [Custom Menu Action](#custom-menu-action)
    - [Custom WinPE Image](#custom-winpe-image)
    - [Customizing OSDCloud Installation](#customizing-osdcloud-installation)
    - [Customizing DHCP Proxy](#customizing-dhcp-proxy)
    - [Example](#example)
  - [Thanks!](#thanks)
  - [More resources](#more-resources)

## Introduction

`autoexec.ipxe` files are scripts that are auto-loaded by **Deployment Live iPXE** during startup for two scenarios:
* **During boot up of iPXE from USB Images.** This is **required** for USB sticks, because there is no other way to determine the path to the iPXE Script Server.
* **During boot up of iPXE from PXE Network Booting.** This is not required, but can be helpful in determining next steps.

`Note: autoexec.ipxe is not processed by Deployment Live iPXE for HTTPS booting.`

We need the `autoexec.ipxe` script to determine where to grab the next Cloud recovery scripts, 
but it can also be useful when we want to auto-populate any variables used later in the **Deployment Live iPXE** process.

## iPXE Scripting

First of all, the `autoexec.ipxe` file is an iPXE script file, so it follows all the rules of iPXE scripting.

For more information about iPXE Scripting, you can find information [here](https://ipxe.org/scripting)

* The first line of an iPXE script must be `!#ipxe` 
* scripting is similar to unix sh scripting.
* All commands are listed [here](https://ipxe.org/cmd)
* There are no `if`, `while`, `sub`, `include` or `call` statements. Just a lot of `goto`
  * If you would like to avoid `goto` statements, check out [iPXEPreProcessor](https://github.com/deploymentlive/ipxepreprocessor)
* Be careful when writing scripts, any error could cause the script to crash, exit iPXE, and reboot the machine. If you have a script that *could* crash, and want to ensure that it won't exit iPXE, use the `||` command at the end of the line to handle the error scenario.

## Custom Menu Action

We can program Deployment Live iPXE to auto launch an action within the Cloud Menu 

| Variable           | Example         | Description                                 |
| ------------------ | --------------- | ------------------------------------------- |
| deploymentlivemenu | tools_dhcpproxy | Will auto launch DHCPProxy in this machine. |

`WARNING: be careful about auto launching actions like re-formatting machines`

### Custom WinPE Image

You can have another WinPE image appear in the Advanced Tools menu by setting the following variables in 
your autoexec.ipxe file:

| Variable                                                                  | Example                                                                          | Description                              |
| ------------------------------------------------------------------------- | -------------------------------------------------------------------------------- | ---------------------------------------- |
| CustomerSuppliedWinPE                                                     | Contoso MDT Server                                                               | Name of Local WinPE Target               |
| CustomerSuppliedWinPE_bootfiles                                           | http://contoso.local/winpe                                                       | Path to `wimboot,BCD,boot.sdi` files     |
| CustomerSuppliedWinPE_bootwim                                             | http://contoso.local/boot.wim                                                    | Path to boot.wim file                    |
| CustomerSuppliedWinPE_ExtraFiles1</br>CustomerSuppliedWinPE_ExtraFiles[n] | http://contoso.local/winpeshl.ini</br>http://contoso.local/MyLogo.png</br>etc... | Extra files to load into WinPE from iPXE |

### Customizing OSDCloud Installation

| Variable            | Example                    | Description                                                                    |
| ------------------- | -------------------------- | ------------------------------------------------------------------------------ |
| osdcloud_zti        | true                       | Make installation Fully Automated                                              |
| osdcloud_fw         | false                      | Update Firmware during OSD Cloud installation                                  |
| osdcloud_name       | Contoso-%Rand:5%           | Computer Naming Pattern used in unattend.xml                                   |
| osdcloud_final      | reboot                     | Either `Reboot` or `Shutdown`</br> happens at the end of OSDCloud during WinPE |
| osdcloud_arch       | x64                        | Either `arm64` or `x64` Typically x64                                          |
| osdcloud_version    | 11                         | Windows OS Version, either `10` or `11`                                        |
| osdcloud_build 24H2 | 24H2                       | Either `24H2`, `23H2`, `22H2`                                                  |
| osdcloud_edition    | Pro                        | Either `Home`,`Education`,`Enterprise`,`Pro`                                   |
| osdcloud_activate   | Retail                     | Either `Retail` or `Volume`                                                    |
| osdcloud_ppkg       | http://mdt.local/corp.ppkg | path to local Windows Provisioning Package                                     |


### Customizing DHCP Proxy

| Variable            | Example                    | Description                                                                    |
| ------------------- | -------------------------- | ------------------------------------------------------------------------------ |
| dhcpproxy_args      | autoexec=http://server/path/autoexec.ipxe  | Download this autoexec.ipxe file for DHCP Proxy |


### Example

```
# OSD Behaviour
set osdcloud_zti true   # Fully Automated
set osdcloud_fw false   # DO not update firmware in OSDCloud
set osdcloud_name Contoso-%Rand:5%
set osdcloud_final reboot     # Reboot when done with OSD in WinPE and boot into Full OS

# Windows Version
set osdcloud_version 11
set osdcloud_build 24H2
iseq ${buildarch} arm64 && set osdcloud_arch Arm64 || set osdcloud_arch x64
set osdcloud_edition Pro
set osdcloud_activate Retail
isset ${efi/PlatformLang:string} && set osdcloud_language ${efi/PlatformLang:string} || set osdcloud_language en-US

set osdcloud_ppkg http://mdtserver1.corp.contoso.com/mdt/Contoso.ppkg

# set deploymentlivemenu osd_adv_install
```

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
