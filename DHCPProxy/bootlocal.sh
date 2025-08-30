#!/bin/sh
# put other system startup scripts here.

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "Load dnsmasq if missing..."

if command -v dnsmasq >/dev/null 2>&1 ; then
    echo "dnsmasq already installed."
else
    echo "dnsmasq not found. Installing..."
    su - tc -c 'tce-load -i /tce/optional/dnsmasq.tcz'
    echo "tce-load exited with code $?"
fi

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "Tiny Core Linux DHCP Proxy by Deployment Live LLC"
echo "Command Line: $(cat /proc/cmdline)"
echo "Contents of /tftpboot: $(ls /tftpboot)"

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

IP_ADDRESS=""
while [ -z "$IP_ADDRESS" ]; do
    IP_ADDRESS=$(ifconfig | grep -o -E 'inet addr:[0-9.]*' | grep -o '[0-9.]*' | grep -v '127' | sed -E 's/^(.*)/dhcp-range=\1,proxy/g' )
    if [ -z "$IP_ADDRESS" ]; then
        echo "No DHCP IP address found for Ethernet adapter. Retrying in 5 seconds..."
        sleep 5
    fi
done

#
# Future, move to bootsync.sh

#echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
#echo "Do you have an alternate iPXE script to run?"
#echo "Note: that this URL will be used only once, for this boot."
#echo "Example: http://server/path/script.ipxe"
#echo "Default is https://deploymentlive.com/... cloud boot server."
#echo "Enter the full URL to the iPXE script, or press ENTER to skip:"
#echo ""
#read -t 10 -p " URL: " -r IPXE_URL

if [ -n "$IPXE_URL" ]; then
    echo "User provided iPXE script URL: $IPXE_URL"
    echo "Configuring dnsmasq to use this URL for this dnsmasq session ONLY."

    # Add a dhcp-boot line to point to the user script URL
    echo "dhcp-boot=ipxe,$IP_ADDRESS" >> /etc/dnsmasq.conf
fi

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "Local IP Address: \n $IP_ADDRESS"
echo "$IP_ADDRESS" >> /etc/dnsmasq.conf

cat /etc/dnsmasq.conf

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
mkdir /var/lib/misc
dnsmasq --test --conf-file=/etc/dnsmasq.conf

echo "Launch dnsmasq..."
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
dnsmasq -d --conf-file=/etc/dnsmasq.conf
echo "dnsmasq exited with code $?"
