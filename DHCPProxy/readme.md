# Create a DHCPProxy server that can be launched by iPXE

This project is a small Linux build that can act as a DHCP Proxy for iPXE.

This linux build can be downloaded and launched from iPXE itself. 

## Components

* Contains a build of Tiny Core Linux
* dnsmasq for hosting the DHCP Proxy server
* Several other iPXE related components
* dnsmasq is launched within the bootlocal.sh script
* Custom commands for iPXE can be stored in the autoexec.ipxe script.

## Build Process

`build-TCPProxyServer.ps1` Will build Tiny Core Linux bootable files using the components in this folder.
The build process requries WSL system to be installed on the local machine. 

## Future Work.

Current implementation is a MVP (minimum viable product)

* Move the startup script from `bootlocal.sh` to `bootsync.sh`
* Allow the user to edit the autoexec.ipxe script.
* Add some documentation for the iPXE variables. 
* Need a process to save current settings and store locally for persistence.