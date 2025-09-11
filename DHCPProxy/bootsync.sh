#!/bin/sh
# put other system startup commands here, the boot process will wait until they complete.
# Use bootlocal.sh for system startup commands that can run in the background 
# and therefore not slow down the boot process.
/usr/bin/sethostname box
/opt/bootlocal.sh &

# put other system startup scripts here.

#region Initialize and parse command line
echo "Tiny Core Linux DHCP Proxy by Deployment Live LLC"
echo "Command Line: $(cat /proc/cmdline)"
echo "Contents of /tftpboot: $(ls /tftpboot)"
#endregion 

#region Load Optional Components
echo "Load optional components"

for file in /tce/optional/*.tcz; do
  if [ -f "$file" ]; then
    echo "Found .tcz file: $file"
    su tc -c "tce-load -i $file"
  fi
done
#endregion

#region get the IP address for dnsmasq.conf
IP_ADDRESS=""
while [ -z "$IP_ADDRESS" ]; do
    IP_ADDRESS=$(ifconfig | grep -o -E 'inet addr:[0-9.]*' | grep -o '[0-9.]*' | grep -v '127' | sed -E 's/^(.*)/dhcp-range=\1,proxy/g' )
    if [ -z "$IP_ADDRESS" ]; then
        echo "No DHCP IP address found for Ethernet adapter. Retrying in 1 seconds..."
        sleep 1
    fi
done

echo "Local IP Address: \n $IP_ADDRESS"
echo "$IP_ADDRESS" >> /etc/dnsmasq.conf

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
cat /etc/dnsmasq.conf
#endregion

#region download autoexec.ipxe if on the linux kernel command line

IPXE_URL=$(cat /proc/cmdline | grep -o 'autoexec=[^[:space:]]*' | cut -d'=' -f2)
if [ -n "$IPXE_URL" ]; then
    echo "download $IPXE_URL for autoexec.ipxe"
    wget $iPXE_URL -o /tftpboot/autoexec.ipxe
    md5sum /tftpboot/autoexec.ipxe
    sha1sum /tftpboot/autoexec.ipxe
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    cat /tftpboot/autoexec.ipxe
fi

#endregion

#region Launch dnsmasq

echo "Launch dnsmasq"
mkdir /var/lib/misc

dnsmasq --conf-file=/etc/dnsmasq.conf --test
dnsmasq --conf-file=/etc/dnsmasq.conf --log-facility=/tmp/dnsmasq.dhcp.log
if [ $? -ne 0 ]; then
    echo "Execution Error.  Press Enter to continue."
    read
fi

#endregion

sleep 1

# Fall through to menu system...