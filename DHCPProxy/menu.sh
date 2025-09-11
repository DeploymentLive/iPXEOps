#!/bin/sh

echo Menu Start...

trap "echo 'continue...'" SIGINT

FIRST_CHOICE_MENU=1

while true; do

    if [ -n "$FIRST_CHOICE_MENU" ]; then
        choice=$FIRST_CHOICE_MENU
        unset FIRST_CHOICE_MENU
    else

        # FUTURE: add some status here
        echo ""
        echo ""
        echo "--- Main Menu ---"
        echo "1. View dnsmasq logs"
        echo "2. Edit dnsmasq settings"
        echo "3. Download autoexec.ipxe from URL"
        echo "4. Edit autoexec.ipxe"
        echo "5. Run shell"
        echo "6. Exit"
        echo "-----------------"
        printf "Enter your choice: "
        read choice

    fi

    case $choice in
        1)
            echo "run dnsmasq...    $GREEN [Ctrl-C to exit] $NORMAL"
            sudo chmod 644 /tmp/dnsmasq.dhcp.log 
            tail -f /tmp/dnsmasq.dhcp.log 
            clear
            ;;
        2)
            # Future: check for changes before restarting service.
            sudo nano /etc/dnsmasq.conf
            # Restart dnsmasq
            clear
            sudo killall dnsmasq
            if [ $? -ne 0 ]; then
                echo "Stopping dnsmasq failed!" >&2
            fi
            sudo dnsmasq --conf-file=/etc/dnsmasq.conf --log-facility=/tmp/dnsmasq.dhcp.log
            if [ $? -ne 0 ]; then
                echo "Restarting dnsmasq failed!" >&2
                continue
            fi
            clear
            ;;
        3)
            echo Please enter the URL for the new autoexec.ipxe file:
            read newurl
            clear
            echo "Downloading [$newurl]"
            sudo wget $newurl -o /tftpboot/newautoexec.ipxe
            if [ $? -ne 0 ]; then
                echo "Download Failed! " >&2
                continue
            fi
            # force user to review file...
            sudo nano /tftpboot/newautoexec.ipxe
            sudo mv /tftpboot/autoexec.ipxe /tftpboot/oldautoexec.ipxe
            sudo mv /tftpboot/newautoexec.ipxe /tftpboot/autoexec.ipxe
            clear
            echo old /tftpboot/autoexec.ipxe saved to /tftpboot/oldautoexec.ipxe
            ;;
        4) 
            nano /tftpboot/autoexec.ipxe
            clear
            ;;
        5) 
            echo "Run shell   [type exit to return to menu]"
            sh
            clear
            ;;
        6) 
            echo
            echo "To re-enter menu, logout, and login with account \"tc\""
            break
            ;;
        *)
            clear
            echo ""
            echo "Invalid choice. Please enter 1, 2, or 3."
            ;;
    esac
done

echo exit...