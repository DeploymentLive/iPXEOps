# Configure dnsmasq for iPXE and DeploymentLive.com

This document was modified from:  https://netboot.xyz/docs/kb/networking/edgerouter

## Routers that support dnsmasq:

* Ubiquiti EdgeRouter

### Assumptions

Assumes that the EdgeRouter is configured as:

* There is a DHCP pool called `LAN`
* The LAN pool manages `10.10.2.0/24`

### Configure tftp support in dnsmasq

By default, dnsmasq is using in the Edgerouter to provide DNS services. In order to enable it :

```
sudo mkdir /config/user-data/tftproot
sudo chmod ugo+rX /config/user-data/tftproot

configure

set service dns forwarding  options enable-tftp
set service dns forwarding  options tftp-root=/config/user-data/tftproot

commit
save
```

### Setup TFTP components
Download the kpxe image for netboot.xyz and set the permissions properly:

```
sudo curl -o /config/user-data/tftproot/snp_x64.efi https://boot.deploymentlive.com/boot/snp_x64.efi
sudo curl -o /config/user-data/tftproot/snp_aa64.efi https://boot.deploymentlive.com/boot/snp_aa64.efi
sudo chmod ugo+r /config/user-data/tftproot/snp_*.efi
```

At this point you should be able to use a TFTP client from a client in 10.10.2.0/24 to fetch the image:

```
$ tftp 10.10.2.1
tftp> get netboot.xyz.kpxe
Received 354972 bytes in 2.0 seconds
```

## Setup dnsmasq

Run the following commands in the console:

```
configure
set service dhcp-server use-dnsmasq enable

set service dns forwarding options "dhcp-match=set:efix64,60,PXEClient:Arch:00007"
set service dns forwarding options "dhcp-boot=tag:efix64,snp_x64.efi,,10.10.2.1"
set service dns forwarding options "dhcp-match=set:efia64,60,PXEClient:Arch:00011"
set service dns forwarding options "dhcp-boot=tag:efiaq64,snp_aa64.efi,,10.10.2.1"
set service dns forwarding options "dhcp-match=set:ipxe,175"
set service dns forwarding options "dhcp-boot=tag:ipxe,https://boot.deploymentlive.com:8050/boot/cloudboot.ipxe"

commit; save
```

These options will now show up in the `Config Tree`
*  service / dns / forwarding : DNS forwarding